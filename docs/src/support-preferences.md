# Supporting both Distributed and DistributedNext

The [Distributed.jl](https://docs.julialang.org/en/v1/stdlib/Distributed/)
standard library and DistributedNext are independent Julia modules, which means
that they are not compatible at all. E.g. you cannot
`DistributedNext.remotecall()` a worker added with `Distributed.addprocs()`. If
you as a package developer want to make your package support both Distributed
and DistributedNext, we suggest using
[Preferences.jl](https://juliapackaging.github.io/Preferences.jl/stable/) to
choose which package to load.

Here's an example for a package named Foo.jl:
```julia
module Foo

# Load a dependency which also supports Distributed/DistributedNext
import Dependency

import Preferences: @load_preference, @set_preferences!

const distributed_package = @load_preference("distributed-package")
if distributed_package == "DistributedNext"
    using DistributedNext
elseif distributed_package == "Distributed"
    using Distributed
else
    error("Unsupported `distributed-package`: '$(distributed_package)'")
end

"""
    set_distributed_package!(value[="Distributed|DistributedNext"])

Set a [preference](https://github.com/JuliaPackaging/Preferences.jl) for using
either the Distributed.jl stdlib or DistributedNext.jl. You will need to restart
Julia after setting a new preference.
"""
function set_distributed_package!(value)
    # Set preferences for all dependencies
    Dependency.set_distributed_package!(value)

    @set_preferences!("distributed-package" => value)
    @info "Foo.jl preference has been set, restart your Julia session for this change to take effect!"
end

end
```

Users will then be able to call
e.g. `Foo.set_distributed_package!("DistributedNext")`. Note that
`Foo.set_distributed_package!` should also set the preferences of any dependencies
of Foo.jl that use a distributed worker package.
