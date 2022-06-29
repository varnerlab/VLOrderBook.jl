# setup internal paths -
_PATH_TO_SRC = dirname(pathof(@__MODULE__))

# Load external packages -
using AVLTrees: AVLTree
using Base: @kwdef
using Printf

# Load my codes -
include(joinpath(_PATH_TO_SRC, "sidequeue.jl"))
include(joinpath(_PATH_TO_SRC, "orderqueue.jl"))
include(joinpath(_PATH_TO_SRC, "sidebook.jl"))
include(joinpath(_PATH_TO_SRC, "book.jl"))
include(joinpath(_PATH_TO_SRC, "ordermatching.jl"))
include(joinpath(_PATH_TO_SRC, "moneydata.jl"))