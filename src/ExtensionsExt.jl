module ExtensionsExt

"""
    has_extensions()::Bool

Returns `true` if the julia version supports extensions,Returns `false` otherwise.

"""
function has_extensions()
    isdefined(Base,:get_extension)
end

function using_expr(expr,type::Symbol,has_ext::Bool)
    #type is :using or :export
    if expr isa Symbol
        if type == :import
            if has_ext
                return :(import $expr)
            else
                return :(import ..($expr))
            end
        else
            if has_ext
                return :(using $expr)
            else
                return :(using ..($expr))
            end
        end

    end

    if expr.head == :call
        mod = expr.args[2]
        first_expr = expr.args[3]
        push!(calls_expr.args,Expr(:.,mod))
        push!(calls_expr.args,Expr(:.,first_expr))
    else
        mod = expr.args[1].args[2]
        first_expr = expr.args[1].args[3]
        push!(calls_expr.args,Expr(:.,mod))
        push!(calls_expr.args,Expr(:.,first_expr))
        for i in 2:length(expr.args)
            push!(calls_expr.args,Expr(:.,expr.args[i]))
        end
    end
    if !has_ext
        mod_expr = calls_expr.args[1].args
        prepend!(mod_expr,(:.,:.))
    end
    using_expr = Expr(type)
    push!(using_expr.args,calls_expr)
    return using_expr
end

"""
    @require_import(expr)

shortcut for:
```julia
if has_extensions()
    using expr
else
    using ..expr
end
```
"""
macro require_import(expr)
    has_ext = ExtensionsExt.has_extensions()
    _using_expr = using_expr(expr,:import,has_ext)
    return :($_using_expr) |> esc
end

"""
    @require_using expr...

shortcut for:
```julia
if has_extensions()
    using expr..
else
    using ..expr...
end
```
"""
macro require_using(expr)
    has_ext = ExtensionsExt.has_extensions()
    _using_expr = using_expr(expr,:using,has_ext)
    return :($_using_expr) |> esc
    
end

struct ExtensionError <: Exception
    ext::Symbol
    msg::String
end

ExtensionError(ext::Symbol) = ExtensionError(ext,"")
ExtensionError(ext::Symbol,msg::Nothing) = ExtensionError(ext,"")

function Base.showerror(io::IO,e::ExtensionError)
    print(io,"ExtensionError: cannot load the extension ")
    print(io,string(e.ext))
    msg = e.msg
    if !isempty(msg)
        println(io)
        print(io,"       ")
        print(io,msg)
    end
end

function notavailable_ext_error(msg)
    if msg === nothing
        err_msg = "Julia version $(Base.VERSION) does not support Pkg extensions"
    else
        err_msg = msg
    end
    throw(error(err_msg))
end


"""
assert_extension(mod::Module,ext::Symbol,;err_msg = nothing,force = true)

If extensions are available, it will try to check if the extension `ext` from module `mod` can be loaded.If the check fails, it errors with `ExtensionError`.

If extensions aren't available, the function will error if `force == true` and return `nothing` otherwise.
"""
function assert_extension end

"""
    try_extension(mod::Module,ext::Symbol,;err_msg = nothing,force = true)

If extensions are available, it will try to load the extension `ext` from module `mod`. If the extension cannot be loaded, it errors with `ExtensionError`.

If extensions aren't available, the function will error if `force == true` and return `nothing` otherwise.
"""
function try_extension end

if has_extensions()
    function assert_extension(mod,ext::Symbol;err_msg = nothing,force = true)
        Ext = Base.get_extension(mod, ext)
        if Ext === nothing
            throw(ExtensionError(ext,err_msg))
        end
        return nothing
    end

    function try_extension(mod,ext::Symbol,;err_msg = nothing,force = true)::Module
        Ext = Base.get_extension(mod, ext)
        if Ext === nothing
            throw(ExtensionError(ext,err_msg))
        end
        return Ext
    end
else
    function assert_extension(mod,ext::Symbol;err_msg = nothing,force = true)
        force && notavailable_ext_error(err_msg)
        return nothing
    end

    function try_extension(mod,ext::Symbol;err_msg = nothing,force = true)
        force && notavailable_ext_error(err_msg)
        return nothing
    end
end

export has_extensions, Extension, assert_extension, try_extension
export @require_using, @require_import

end #module
