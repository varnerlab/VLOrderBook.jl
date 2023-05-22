using VLOrderBook
using Test, Random, Dates
using AVLTrees: AVLTree
using Base.Iterators: zip,cycle,take,filter

@testset "VLOrderBook.jl" begin
    include("./test-logic.jl")
end
