include("testhelpers/PersistentWorkers.jl")
using .PersistentWorkers
using Test
using Random
using DistributedNext

@testset "PersistentWorkers.jl" begin
    cookie = randstring(16)
    port = rand(9128:9999) # TODO: make sure port is available?
    helpers_path = joinpath(@__DIR__, "testhelpers", "PersistentWorkers.jl")
    cmd = `$(Base.julia_exename()) --startup=no --project=$(Base.active_project()) -L $(helpers_path) -e "using .PersistentWorkers; wait(start_worker_loop($port; cluster_cookie=$(repr(cookie)))[1])"`
    worker = run(pipeline(cmd; stdout, stderr); wait=false)
    try
    @show worker.cmd
    cluster_cookie(cookie)
    sleep(10)

    p = addprocs(PersistentWorkerManager(port))[]
    @test procs() == [1, p]
    @test workers() == [p]
    @test remotecall_fetch(myid, p) == p
    rmprocs(p)
    @test procs() == [1]
    @test workers() == [1]
    @test process_running(worker)
    # this shouldn't error
    @everywhere 1+1

    # try the same thing again for the same worker
    p = addprocs(PersistentWorkerManager(port))[]
    @test procs() == [1, p]
    @test workers() == [p]
    @test remotecall_fetch(myid, p) == p
    rmprocs(p)
    @test procs() == [1]
    @test workers() == [1]
    @test process_running(worker)
    # this shouldn't error
    @everywhere 1+1
    finally
        kill(worker)
        wait(worker)
    end
end
