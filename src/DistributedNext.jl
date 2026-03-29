# This file is a part of Julia. License is MIT: https://julialang.org/license

"""
Tools for distributed parallel processing. This is a soft fork of Distributed.jl
for the purposes of testing new things before merging upstream. Here be dragons!
"""
module DistributedNext

# imports for extension
import Base: getindex, wait, put!, take!, fetch, isready, push!, length,
             hash, ==, kill, close, isopen, showerror, iterate, IteratorSize

# imports for use
using Base: Process, Semaphore, JLOptions, buffer_writes, @async_unwrap,
            VERSION_STRING, binding_module, atexit, julia_exename,
            julia_cmd, AsyncGenerator, acquire, release, invokelatest,
            shell_escape_posixly, shell_escape_csh,
            shell_escape_wincmd, escape_microsoft_c_args,
            uv_error, something, notnothing, isbuffered, mapany, SizeUnknown
using Base.Threads: Event

using Serialization, Sockets
import Serialization: serialize, deserialize
import Sockets: connect, wait_connected

@static if VERSION < v"1.11"
    using ScopedValues: ScopedValue, @with
else
    using Base.ScopedValues: ScopedValue, @with
end

# NOTE: clusterserialize.jl imports additional symbols from Serialization for use

export
    @spawn,
    @spawnat,
    @fetch,
    @fetchfrom,
    @everywhere,
    @distributed,

    AbstractWorkerPool,
    addprocs,
    CachingPool,
    clear!,
    ClusterManager,
    default_worker_pool,
    init_worker,
    interrupt,
    launch,
    manage,
    myid,
    nprocs,
    nworkers,
    pmap,
    procs,
    other_procs,
    remote,
    remotecall,
    remotecall_eval,
    remotecall_fetch,
    remotecall_wait,
    remote_do,
    rmprocs,
    workers,
    other_workers,
    WorkerPool,
    RemoteChannel,
    Future,
    WorkerConfig,
    RemoteException,
    ProcessExitedException,

    process_messages,
    remoteref_id,
    channel_from_id,
    worker_id_from_socket,
    cluster_cookie,
    start_worker,

# Used only by shared arrays.
    check_same_host

function _check_distributed_active()
    # Find the Distributed module if it's been loaded
    distributed_pkgid = Base.PkgId(Base.UUID("8ba89e20-285c-5b6f-9357-94700520ee1b"), "Distributed")
    if !haskey(Base.loaded_modules, distributed_pkgid)
        return false
    end

    if isdefined(Base.loaded_modules[distributed_pkgid].LPROC, :cookie) && CTX[].inited[]
        @warn "DistributedNext has detected that the Distributed stdlib may be in use. Be aware that these libraries are not compatible, you should use either one or the other."
        return true
    else
        return false
    end
end

function _require_callback(mod::Base.PkgId)
    if Base.toplevel_load[] && myid() == 1 && nprocs() > 1
        # broadcast top-level (e.g. from Main) import/using from node 1 (only)
        @sync for p in procs()
            p == 1 && continue
            # Extensions are already loaded on workers by their triggers being loaded
            # so no need to fire the callback upon extension being loaded on master.
            Base.loading_extension && continue
            @async_unwrap remotecall_wait(p) do
                Base.require(mod)
                nothing
            end
        end
    end
end

# This is a minimal copy of Base.Lockable we use for backwards compatibility with 1.10
struct Lockable{T, L <: Base.AbstractLock}
    value::T
    lock::L
end
Lockable(value) = Lockable(value, ReentrantLock())
Base.getindex(l::Lockable) = (Base.assert_havelock(l.lock); l.value)
Base.lock(l::Lockable) = lock(l.lock)
Base.trylock(l::Lockable) = trylock(l.lock)
Base.unlock(l::Lockable) = unlock(l.lock)

next_ref_id() = Threads.atomic_add!(CTX[].ref_id, 1)

struct RRID
    whence::Int
    id::Int

    RRID() = RRID(myid(), next_ref_id())
    RRID(whence, id) = new(whence, id)
end

hash(r::RRID, h::UInt) = hash(r.whence, hash(r.id, h))
==(r::RRID, s::RRID) = (r.whence==s.whence && r.id==s.id)

include("network_interfaces.jl")
include("clusterserialize.jl")
include("cluster.jl")   # cluster setup and management, addprocs
include("messages.jl")
include("process_messages.jl")  # process incoming messages
include("remotecall.jl")  # the remotecall* api
include("macros.jl")      # @spawn and friends
include("workerpool.jl")
include("pmap.jl")
include("managers.jl")    # LocalManager and SSHManager
include("precompile.jl")

# Bundles all mutable global state for a distributed cluster into a single
# object. The active context is accessed via the `CTX` ScopedValue, allowing
# multiple independent clusters to coexist in different task scopes.
@kwdef mutable struct ClusterContext
    # Process identity
    lproc::LocalProcess = LocalProcess()
    role::Ref{Symbol} = Ref{Symbol}(:master)

    # Process group
    pgrp::ProcessGroup = ProcessGroup([])

    # Worker registries
    map_pid_wrkr::Lockable{Dict{Int, Union{Worker, LocalProcess}}, ReentrantLock} = Lockable(Dict{Int, Union{Worker, LocalProcess}}())
    map_sock_wrkr::Lockable{IdDict{Any, Any}, ReentrantLock} = Lockable(IdDict())
    map_del_wrkr::Lockable{Set{Int}, ReentrantLock} = Lockable(Set{Int}())
    map_pid_statuses::Lockable{Dict{Int, Any}, ReentrantLock} = Lockable(Dict{Int, Any}())

    # Lifecycle callbacks
    worker_starting_callbacks::Dict{Any, Base.Callable} = Dict{Any, Base.Callable}()
    worker_started_callbacks::Dict{Any, Base.Callable} = Dict{Any, Base.Callable}()
    worker_exiting_callbacks::Dict{Any, Base.Callable} = Dict{Any, Base.Callable}()
    worker_exited_callbacks::Dict{Any, Base.Callable} = Dict{Any, Base.Callable}()

    # Cluster manager
    cluster_manager::Ref{ClusterManager} = Ref{ClusterManager}()

    # Synchronization
    worker_lock::ReentrantLock = ReentrantLock()
    inited::Threads.Atomic{Bool} = Threads.Atomic{Bool}(false)
    next_pid::Threads.Atomic{Int} = Threads.Atomic{Int}(2) # 1 is reserved for the client (always)

    # Remote references
    ref_id::Threads.Atomic{Int} = Threads.Atomic{Int}(1)
    # Tracks whether a particular `AbstractRemoteRef` (identified by its RRID)
    # exists on this worker. The `client_refs` lock is also used to synchronize
    # access to `.refs` and associated `clientset` state.
    client_refs::WeakKeyDict{AbstractRemoteRef, Nothing} = WeakKeyDict{AbstractRemoteRef, Nothing}() # used as a WeakKeySet
    any_gc_flag::Threads.Condition = Threads.Condition()

    # Serialization state
    object_numbers::WeakKeyDict = WeakKeyDict()
    obj_number_salt::Ref{Int} = Ref(0)
    known_object_data::Dict{UInt64, Any} = Dict{UInt64, Any}()

    # Worker pools / macros
    default_worker_pool::Ref{Union{AbstractWorkerPool, Nothing}} = Ref{Union{AbstractWorkerPool, Nothing}}(nothing)
    next_worker_idx::Threads.Atomic{Int} = Threads.Atomic{Int}(0)

    # Network / SSH
    tunnel_counter::Threads.Atomic{Int} = Threads.Atomic{Int}(1)
    tunnel_hosts_map::Dict{String, Semaphore} = Dict{String, Semaphore}()
    client_port::Ref{UInt16} = Ref{UInt16}(0)

    # Scoped value for exited callback pid
    exited_callback_pid::ScopedValue{Int} = ScopedValue(-1)

    # GC messages task
    shutting_down::Threads.Atomic{Bool} = Threads.Atomic{Bool}(false)
    gc_msgs_task::Union{Task, Nothing} = nothing

    # Stdlib watcher
    stdlib_watcher_timer::Union{Timer, Nothing} = nothing
end

function Base.close(ctx::ClusterContext)
    ctx.shutting_down[] = true
    if !isnothing(ctx.gc_msgs_task)
        @lock ctx.any_gc_flag notify(ctx.any_gc_flag)
        wait(ctx.gc_msgs_task::Task)
    end

    if !isnothing(ctx.stdlib_watcher_timer)
        close(ctx.stdlib_watcher_timer::Timer)
    end

    # Close all tracked sockets
    @lock ctx.map_sock_wrkr for sock in keys(ctx.map_sock_wrkr[])
        close(sock)
    end
end

const CTX = ScopedValue(ClusterContext())

function __init__()
    init_parallel()

    if ccall(:jl_generating_output, Cint, ()) == 0
        # Start a task to watch for the Distributed stdlib being loaded and
        # initialized to support multiple workers. We do this by checking if the
        # cluster cookie has been set, which is most likely to have been done
        # through Distributed.init_multi() being called by Distributed.addprocs() or
        # something.
        CTX[].stdlib_watcher_timer = Timer(0; interval=1) do timer
            if _check_distributed_active()
                close(timer)
            end
        end
    end

    atexit(() -> close(CTX[]))
end

end
