## This is a minimal version of NetworkInterfaceControllers.jl, licensed under MIT

# uv_interface_address_t has a few fields, but we don't support accessing all of
# them because `name` is the first field and it's a pointer:
# https://docs.libuv.org/en/v1.x/misc.html#c.uv_interface_address_t
#
# To safely access the other fields we would have to account for their
# offset changing on 32/64bit platforms, which we are too lazy to do (and
# don't need anyway since we only want the name).
const uv_interface_address_t = Cvoid

const sizeof_uv_interface_address_t = @ccall jl_uv_sizeof_interface_address()::Cint

function uv_interface_addresses(addresses, count)
    @ccall jl_uv_interface_addresses(addresses::Ptr{Ptr{uv_interface_address_t}}, count::Ptr{Cint})::Cint
end

function uv_free_interface_addresses(addresses, count)
    @ccall uv_free_interface_addresses(addresses::Ptr{uv_interface_address_t}, count::Cint)::Cvoid
end

function _next(r::Base.RefValue{Ptr{uv_interface_address_t}})
    next_addr = r[] + sizeof_uv_interface_address_t
    Ref(Ptr{uv_interface_address_t}(next_addr))
end

_is_loopback(addr) = 1 == @ccall jl_uv_interface_address_is_internal(addr::Ptr{uv_interface_address_t})::Cint

_sockaddr(addr) = @ccall jl_uv_interface_address_sockaddr(addr::Ptr{uv_interface_address_t})::Ptr{Cvoid}

_sockaddr_is_ip4(sockaddr::Ptr{Cvoid}) = 1 == @ccall jl_sockaddr_is_ip4(sockaddr::Ptr{Cvoid})::Cint

_sockaddr_is_ip6(sockaddr::Ptr{Cvoid}) = 1 == @ccall jl_sockaddr_is_ip6(sockaddr::Ptr{Cvoid})::Cint

_sockaddr_to_ip4(sockaddr::Ptr{Cvoid}) = IPv4(ntoh(@ccall jl_sockaddr_host4(sockaddr::Ptr{Cvoid})::Cuint))

function _sockaddr_to_ip6(sockaddr::Ptr{Cvoid})
    addr6 = Ref{UInt128}()
    @ccall jl_sockaddr_host6(sockaddr::Ptr{Cvoid}, addr6::Ptr{UInt128})::Cuint
    IPv6(ntoh(addr6[]))
end

# Define a selection of hardware types that we're interested in. Values taken from:
# https://github.com/torvalds/linux/blob/28eb75e178d389d325f1666e422bc13bbbb9804c/include/uapi/linux/if_arp.h#L29
@enum ARPHardware begin
    ARPHardware_Ethernet = 1
    ARPHardware_Infiniband = 32
    ARPHardware_Loopback = 772
end

struct Interface
    name::String
    version::Symbol
    ip::IPAddr

    # These two fields are taken from the sysfs /type and /speed files if available:
    # https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-net
    type::Union{ARPHardware, Nothing}
    speed::Union{Float64, Nothing}
end

function _get_interfaces(
    ::Type{T}=IPAddr; loopback::Bool=false
) where T <: IPAddr
    addr_ref  = Ref{Ptr{uv_interface_address_t}}(C_NULL)
    count_ref = Ref{Int32}(1)

    err = uv_interface_addresses(addr_ref, count_ref)
    if err != 0
        error("Call to uv_interface_addresses() to list network interfaces failed: $(err)")
    end

    interface_data = Interface[]
    current_addr = addr_ref
    for i = 0:(count_ref[]-1)
        # Skip loopback devices, if so required
        if (!loopback) && _is_loopback(current_addr[])
            # Don't don't forget to iterate the address pointer though!
            current_addr = _next(current_addr)
            continue
        end

        # Interface name string. The name is the first field of the struct so we
        # just cast the struct pointer to a Ptr{Cstring} and load it.
        name_ptr = unsafe_load(Ptr{Cstring}(current_addr[]))
        name = unsafe_string(name_ptr)

        # Sockaddr used to load IPv4, or IPv6 addresses
        sockaddr = _sockaddr(current_addr[])

        # Load IP addresses
        (ip_type, ip_address) = if IPv4 <: T && _sockaddr_is_ip4(sockaddr)
            (:v4, _sockaddr_to_ip4(sockaddr))
        elseif IPv6 <: T && _sockaddr_is_ip6(sockaddr)
            (:v6, _sockaddr_to_ip6(sockaddr))
        else
            (:skip, nothing)
        end

        type = nothing
        speed = nothing

        @static if Sys.isunix()
            # Load sysfs info
            sysfs_path = "/sys/class/net/$(name)"
            type_path = "$(sysfs_path)/type"
            speed_path = "$(sysfs_path)/speed"

            if isfile(type_path)
                try
                    type_code = parse(Int, read(type_path, String))
                    if type_code in Int.(instances(ARPHardware))
                        type = ARPHardware(type_code)
                    end
                catch
                    # Do nothing on any failure to read or parse the file
                end
            end

            if isfile(speed_path)
                try
                    reported_speed = parse(Float64, read(speed_path, String))
                    if reported_speed > 0
                        speed = reported_speed
                    end
                catch
                end
            end
        end

        # Append to data vector and iterate address pointer
        if ip_type != :skip
            push!(interface_data, Interface(name, ip_type, ip_address, type, speed))
        end
        current_addr = _next(current_addr)
    end

    uv_free_interface_addresses(addr_ref[], count_ref[])

    return interface_data
end
