using PrecompileTools: @compile_workload

@compile_workload begin
    # Run the workload in a separate ClusterContext so the default one stays clean
    ClusterContext() do
        # Use an in-process worker to avoid spawning a real process during precompilation
        pid = only(addprocs(LocalManager(1, true, true)))
        rmprocs(pid)
    end
end
