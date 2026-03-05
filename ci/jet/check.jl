using DistributedNext: DistributedNext

using JET: JET
using Serialization: Serialization
using Test: Test, @testset

# We don't want to fail PkgEval because of a JET failure
# Therefore, we don't put the JET tests in the regular DistributedNext test suite
# Instead, we put it in a separate CI job, which runs on the DistributedNext repo

@testset "JET" begin
    ignored_modules = (
        # We will ignore Base:
        Base,

        # We'll ignore the Serialization stdlib:
        Serialization,
    )
    JET.test_package(DistributedNext; ignored_modules)
end
