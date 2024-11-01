# This file is a part of Julia. License is MIT: https://julialang.org/license

# Run the distributed test outside of the main driver since it needs its own
# set of dedicated workers.
include(joinpath(Sys.BINDIR, "..", "share", "julia", "test", "testenv.jl"))

cmd = `$test_exename $test_exeflags`

# Run the SSH tests with a single thread because LibSSH.jl is not thread-safe
sshtestfile = joinpath(@__DIR__, "sshmanager.jl")
run(addenv(`$cmd $sshtestfile`, "JULIA_NUM_THREADS" => "1"))

disttestfile = joinpath(@__DIR__, "distributed_exec.jl")
if !success(pipeline(`$cmd  $disttestfile`; stdout=stdout, stderr=stderr)) && ccall(:jl_running_on_valgrind,Cint,()) == 0
    error("Distributed test failed, cmd : $cmd")
end

include("managers.jl")
