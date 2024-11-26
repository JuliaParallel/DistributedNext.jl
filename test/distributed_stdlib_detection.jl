@testset "Distributed.jl detection" begin
    function get_stderr(cmd)
        stderr_buf = IOBuffer()
        run(pipeline(cmd; stderr=stderr_buf))
        return String(take!(stderr_buf))
    end

    # Just loading Distributed should do nothing
    cmd = `$test_exename $test_exeflags -e 'using Distributed, DistributedNext; @assert !DistributedNext._check_distributed_active()'`
    @test isempty(get_stderr(cmd))

    # Only one of the two being active should also do nothing
    cmd = `$test_exename $test_exeflags -e 'using Distributed, DistributedNext; Distributed.init_multi(); @assert !DistributedNext._check_distributed_active()'`
    @test isempty(get_stderr(cmd))

    cmd = `$test_exename $test_exeflags -e 'using Distributed, DistributedNext; DistributedNext.init_multi(); @assert !DistributedNext._check_distributed_active()'`
    @test isempty(get_stderr(cmd))

    # But both being active at the same time should trigger a warning
    cmd = `$test_exename $test_exeflags -e 'using Distributed, DistributedNext; Distributed.init_multi(); DistributedNext.init_multi(); @assert DistributedNext._check_distributed_active()'`
    @test contains(get_stderr(cmd), "DistributedNext has detected that the Distributed stdlib may be in use")
end
