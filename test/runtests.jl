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
