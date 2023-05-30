# ExtensionsExt.jl

[![Build Status](https://github.com/longemen3000/ExtensionExtensions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/longemen3000/ExtensionExtensions.jl/actions/workflows/CI.yml?query=branch%3Amain)

A package that defines some commonly used boilerplate using in extensions.

There are different usecases that appeared during the transition to julia 1.9 extensions. We are going to use an hypothetical package, `Things.jl`, tho showcase how we can use `ExtensionsExt.jl` to address those usecases.

## Case 0: only extending new methods, using Requires.jl

This is the mayority of the cases. excluding `has_extension` and the `@require_X` macros, there is not much else to do, other than following the (julia documentation)[https://pkgdocs.julialang.org/dev/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions)].`ExtensionsExt` helps on the boilerplate:

In our particular example, `Things.jl` loaded `Unitful.jl` via `Requires.jl` to extend `HotThing`

- In the `Things` module:
```julia

struct HotThing
    val::Float64
end

if !has_extensions() #if isdefined(Base,:get_extension)
    function __init__()
        @require Unitful="1986cc42-f94f-5a68-af5c-568840ba703d" include("../ext/ThingsUnitfulExt.jl")
    end
end
```

- In the `ThingsUnitfulExt` module:
```julia
module ThingsUnitfulExt

using ExtensionsExt
@require_using Unitful: ustrip, uprefered,Temperature #if isdefined(Base,:get_extension) ...
@require_import Things: HotThing

HotThing(val::Temperature) = HotThing(ustrip(upreferred(val)))
end #module

```

### Case 1: new extension, with an exported function

`Things.jl` added a new conditional dependency, `Plots.jl` into the package, it wants to export a function that depends on `Plots.jl` being loaded, with `ExtensionsExt`, you can use this:

- In the `Things` module:
```julia
const PLOT_EXT_ERR = "thingplot requires that Plots is loaded, i.e. `using Plots`"
function thingplot(x::Thing)
    ext = try_extension(Things,:ThingsPlotsExt,err_msg = PLOT_EXT_ERR)
    ext.__thingplot(x)
end

```

### Case 2: dependency to extension, with an exported struct

`Things.jl` moved `Tables.jl` from inconditional dependency to Extension. A struct, `ThingTable`, was exported. On 1.8 and before, `Things.jl` loaded the methods for `ThingTable` inconditionally. Now, `Tables.jl` needs to be loaded before constructing a `ThingTable`. We want to error on the construction of `ThingTable` if `Tables.jl` is not loaded in 1.9, but don't do anything on earlier versions.

- In the `Things` module:
```julia
struct ThingTable
    x::Vector{Thing}
    function ThingTable(x::Vector{Thing})
        #if force == true, assert_extension will fail on julia 1.8 and before.
        assert_extension(Things,:ThingsTablesExt, force = false)
        return new(x)
    end
end

#at the end of the module, we suppose that the ThingsTablesExt module loads Tables.jl
if !has_extensions() && include("../ext/ThingsTablesExt.jl")
export ThingTable
```







