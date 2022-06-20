using VLOrderBook
using Test
using AVLTrees: AVLTree
using Base.Iterators: zip,cycle,take,filter

@testset "VLOrderBook.jl" begin
    include("./test-1.jl")
end
