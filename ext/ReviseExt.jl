module ReviseExt

import DistributedNext
import DistributedNext: myid, workers, remotecall

using PrecompileTools: @recompile_invalidations

# Sadly Revise causes quite a few invalidations. TODO: make DistributedNext more
# resistant to invalidations.
@recompile_invalidations import Revise

struct DistributedNextWorker <: Revise.AbstractWorker
    id::Int
end

function get_workers()
    map(DistributedNextWorker, workers())
end

function Revise.remotecall_impl(f, worker::DistributedNextWorker, args...; kwargs...)
    remotecall(f, worker.id, args...; kwargs...)
end

Revise.is_master_worker(::typeof(get_workers)) = myid() == 1
Revise.is_master_worker(worker::DistributedNextWorker) = worker.id == 1

function __init__()
    Revise.register_workers_function(get_workers)
    DistributedNext.add_worker_started_callback(pid -> Revise.init_worker(DistributedNextWorker(pid));
                                                key="DistributedNext-integration")
end

end
