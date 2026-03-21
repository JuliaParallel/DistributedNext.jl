precompile(Tuple{typeof(DistributedNext.remotecall),Function,Int,Module,Vararg{Any, 100}})
precompile(Tuple{typeof(DistributedNext.procs)})
precompile(Tuple{typeof(DistributedNext.finalize_ref), DistributedNext.Future})
precompile(Tuple{typeof(DistributedNext.setup_launched_worker), DistributedNext.LocalManager, DistributedNext.WorkerConfig, Vector{Int}})
precompile(Tuple{typeof(DistributedNext.process_tcp_streams), Sockets.TCPSocket, Sockets.TCPSocket, Bool})
precompile(Tuple{typeof(Serialization.serialize), DistributedNext.ClusterSerializer{Sockets.TCPSocket}, Array{Any, 1}})
precompile(Tuple{typeof(DistributedNext.parse_connection_info), String})
precompile(Tuple{typeof(DistributedNext._run_callbacks_concurrently), String, Base.Dict{Any, Union{Function, Type}}, Int64, Array{Tuple{DistributedNext.LocalManager, Base.Dict{Symbol, Any}}, 1}})
precompile(Tuple{typeof(DistributedNext._run_callbacks_concurrently), String, Base.Dict{Any, Union{Function, Type}}, Int64, Array{Int64, 1}})
precompile(Tuple{typeof(DistributedNext.read_worker_host_port), Base.PipeEndpoint})
precompile(Tuple{typeof(Base.put!), Base.Channel{Any}, Int64})
precompile(Tuple{typeof(Base.put!), Base.Channel{Any}, WeakRef})

precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.IdentifySocketMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallWaitMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallMsg{:call}, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallMsg{:call_fetch}, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.ResultMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.IdentifySocketAckMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.RemoteDoMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.JoinPGRPMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.JoinCompleteMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})

# These lines were obtained from `addprocs(1; exeflags=`--trace-compile=compilation.txt --trace-compile-timing`)`
precompile(Tuple{typeof(DistributedNext.start_worker)})
precompile(Tuple{typeof(DistributedNext.start_worker), Base.PipeEndpoint, String})
precompile(Tuple{typeof(DistributedNext.set_valid_processes), Array{Int64, 1}})
precompile(Tuple{typeof(DistributedNext.terminate_all_workers)})

# This is disabled because it doesn't give much benefit
# and the code in Distributed is poorly typed causing many invalidations
# TODO: Maybe reenable now that Distributed is not in sysimage.
#=
    precompile_script *= """
    using Distributed
    addprocs(2)
    pmap(x->iseven(x) ? 1 : 0, 1:4)
    @distributed (+) for i = 1:100 Int(rand(Bool)) end
    """
=#
