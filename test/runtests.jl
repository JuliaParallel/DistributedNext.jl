# This file is a part of Julia. License is MIT: https://julialang.org/license

using Test
import DistributedNext
import Aqua

# Run the distributed test outside of the main driver since it needs its own
# set of dedicated workers.
include(joinpath(Sys.BINDIR, "..", "share", "julia", "test", "testenv.jl"))

cmd = `$test_exename $test_exeflags`

# LibSSH.jl currently only works on unixes
if Sys.isunix()
    # Run the SSH tests with a single thread because LibSSH.jl is not thread-safe
    sshtestfile = joinpath(@__DIR__, "sshmanager.jl")
    if Base.VERSION >= v"1.12-"
        # The x,y format for threadpools requires Julia 1.9 or above.
        # However, Julia didn't begin starting with 1 interactive thread by default until Julia 1.12
        # So we don't need to bother with this on Julia 1.11 and earlier
        JULIA_NUM_THREADS = "1,0"
    else
        JULIA_NUM_THREADS = "1"
    end
    run(addenv(`$cmd $sshtestfile`, "JULIA_NUM_THREADS" => "1"))
else
    @warn "Skipping the SSH tests because this platform is not supported"
end

include("distributed_exec.jl")

include("managers.jl")

include("distributed_stdlib_detection.jl")

@testset "Aqua" begin
    Aqua.test_all(DistributedNext)
end
