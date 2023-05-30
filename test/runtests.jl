using ExtensionsExt
using ExtensionsExt: using_expr
using Test

@testset "ExtensionsExt.jl" begin

    @test using_expr(:D,:import,true) == :(import D)
    @test using_expr(:D,:using,true) == :(using D)
    @test using_expr(:D,:import,false) == :(import ..D)
    @test using_expr(:D,:using,false) == :(using ..D)

    expr_bare = :(D: a,b,c)
    @test using_expr(expr_bare,:import,true) == :(import D: a,b,c)
    @test using_expr(expr_bare,:using,true) == :(using D: a,b,c)
    @test using_expr(expr_bare,:import,false) == :(import ..D: a,b,c)
    @test using_expr(expr_bare,:using,false) == :(using ..D: a,b,c)

    @test isdefined(Base,:get_extension) == has_extensions()

    
    # Write your tests here.
end
