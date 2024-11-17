precompile(Tuple{typeof(DistributedNext.remotecall),Function,Int,Module,Vararg{Any, 100}})
precompile(Tuple{typeof(DistributedNext.procs)})
precompile(Tuple{typeof(DistributedNext.finalize_ref), DistributedNext.Future})
precompile(Tuple{typeof(DistributedNext.setup_launched_worker), DistributedNext.LocalManager, DistributedNext.WorkerConfig, Vector{Int}})
precompile(Tuple{typeof(DistributedNext.process_tcp_streams), Sockets.TCPSocket, Sockets.TCPSocket, Bool})

precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.IdentifySocketMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallWaitMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallMsg{:call}, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.CallMsg{:call_fetch}, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.ResultMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.IdentifySocketAckMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.RemoteDoMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.JoinPGRPMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})
precompile(Tuple{typeof(DistributedNext.handle_msg), DistributedNext.JoinCompleteMsg, DistributedNext.MsgHeader, Sockets.TCPSocket, Sockets.TCPSocket, VersionNumber})

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
