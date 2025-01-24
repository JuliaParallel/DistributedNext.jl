using Test
using DistributedNext
import Sockets: getipaddr, listenany

import LibSSH as ssh
import LibSSH.Demo: DemoServer


include(joinpath(Sys.BINDIR, "..", "share", "julia", "test", "testenv.jl"))

function test_n_remove_pids(new_pids)
    for p in new_pids
        w_in_remote = sort(remotecall_fetch(workers, p))
        try
            @test intersect(new_pids, w_in_remote) == new_pids
        catch
            print("p       :     $p\n")
            print("newpids :     $new_pids\n")
            print("w_in_remote : $w_in_remote\n")
            print("intersect   : $(intersect(new_pids, w_in_remote))\n\n\n")
            rethrow()
        end
    end

    remotecall_fetch(rmprocs, 1, new_pids)
end

@testset "SSHManager" begin
    ssh_port, server = listenany(2222)
    close(server)

    DemoServer(Int(ssh_port); auth_methods=[ssh.AuthMethod_None], allow_auth_none=true, verbose=false, timeout=3600) do
        sshflags = `-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR -p $(ssh_port)`
        #Issue #9951
        hosts=[]
        localhost_aliases = ["localhost", string(getipaddr()), "127.0.0.1"]
        num_workers = parse(Int,(get(ENV, "JULIA_ADDPROCS_NUM", "9")))

        for i in 1:(num_workers/length(localhost_aliases))
            append!(hosts, localhost_aliases)
        end

        # CI machines sometimes don't already have a .ssh directory
        ssh_dir = joinpath(homedir(), ".ssh")
        if !isdir(ssh_dir)
            mkdir(ssh_dir)
        end

        print("\nTesting SSH addprocs with $(length(hosts)) workers...\n")
        new_pids = addprocs_with_testenv(hosts; sshflags=sshflags)
        @test length(new_pids) == length(hosts)
        test_n_remove_pids(new_pids)

        print("\nMixed ssh addprocs with :auto\n")
        new_pids = addprocs_with_testenv(["localhost", ("127.0.0.1", :auto), "localhost"]; sshflags=sshflags)
        @test length(new_pids) == (2 + Sys.CPU_THREADS)
        test_n_remove_pids(new_pids)

        print("\nMixed ssh addprocs with numeric counts\n")
        new_pids = addprocs_with_testenv([("localhost", 2), ("127.0.0.1", 2), "localhost"]; sshflags=sshflags)
        @test length(new_pids) == 5
        test_n_remove_pids(new_pids)

        print("\nssh addprocs with tunnel\n")
        new_pids = addprocs_with_testenv([("localhost", num_workers)]; tunnel=true, sshflags=sshflags)
        @test length(new_pids) == num_workers
        test_n_remove_pids(new_pids)

        print("\nssh addprocs with tunnel (SSH multiplexing)\n")
        new_pids = addprocs_with_testenv([("localhost", num_workers)]; tunnel=true, multiplex=true, sshflags=sshflags)
        @test length(new_pids) == num_workers
        controlpath = joinpath(ssh_dir, "julia-$(ENV["USER"])@localhost:$(ssh_port)")
        @test issocket(controlpath)
        test_n_remove_pids(new_pids)
        @test :ok == timedwait(()->!issocket(controlpath), 10.0; pollint=0.5)

        print("\nTest SSH addprocs() passing environment variables\n")
        withenv("JULIA_FOO" => "foo") do
            new_pids = addprocs_with_testenv(["localhost"]; sshflags)
            @test remotecall_fetch(() -> ENV["JULIA_FOO"], only(new_pids)) == "foo"
            test_n_remove_pids(new_pids)
        end

        print("\nAll supported formats for hostname\n")
        h1 = "localhost"
        user = ENV["USER"]
        h2 = "$user@$h1"
        h3 = "$h2:$(ssh_port)"
        h4 = "$h3 $(string(getipaddr()))"
        (bind_port, server) = listenany(9300)
        close(server)
        h5 = "$h4:$(bind_port)"

        new_pids = addprocs_with_testenv([h1, h2, h3, h4, h5]; sshflags=sshflags)
        @test length(new_pids) == 5
        test_n_remove_pids(new_pids)

        print("\nkeyword arg exename\n")
        for exename in [`$(joinpath(Sys.BINDIR, Base.julia_exename()))`, "$(joinpath(Sys.BINDIR, Base.julia_exename()))"]
            for addp_func in [()->addprocs_with_testenv(["localhost"]; exename=exename, exeflags=test_exeflags, sshflags=sshflags),
                              ()->addprocs_with_testenv(1; exename=exename, exeflags=test_exeflags)]

                local new_pids = addp_func()
                @test length(new_pids) == 1
                test_n_remove_pids(new_pids)
            end
        end
    end
end
