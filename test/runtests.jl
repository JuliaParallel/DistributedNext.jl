# This file is a part of Julia. License is MIT: https://julialang.org/license

using Test
import DistributedNext
import Aqua

# Run the distributed test outside of the main driver since it needs its own
# set of dedicated workers.
include(joinpath(Sys.BINDIR, "..", "share", "julia", "test", "testenv.jl"))

cmd = `$test_exename $test_exeflags`

# LibSSH.jl currently only works on unixes and v1.11+, and the latest release
# currently doesn't pass CI on MacOS.
if Sys.islinux() && VERSION >= v"1.11"
    include("sshmanager.jl")
else
    @warn "Skipping the SSH tests because this platform is not supported"
end

include("distributed_exec.jl")

include("managers.jl")

include("distributed_stdlib_detection.jl")

@testset "Aqua" begin
    Aqua.test_all(DistributedNext; stale_deps=(; ignore=[:ScopedValues]))
end
