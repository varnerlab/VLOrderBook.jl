# import stuff from Base
import Base.@kwdef

# abstract types -
abstract type Comparable end

# === CONCRETE TYPES BELOW (EXPORTED) =========================================================================================== %

"""
    OrderSide(is_buy::Bool)

Type representing whether an order is a buy order or sell order.
New instance can be generated with `OrderSide(::Bool)` or by using exported constants
`BUY_ORDER` and `SELL_ORDER`
"""
struct OrderSide
    is_buy::Bool
end

"""
    Order{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}

Type representing a limit order.

An `Order{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}` is a struct representing a resting Limit Order which contains
 - `side::OrderSide`, the side of the book the order will rest in. See [`OrderSide`](@ref) for more info.
 - `size::Sz`, the order size
 - `price::Px`, the price the order is set at
 - `orderid::Oid`, a unique Order ID
 - (optional) `acctid::Union{Aid,Nothing}`, which is set to nothing if the account is unknown or irrelevant.

One can create a new `Order` as

```
Order{Sz,Px,Pid,Aid}(side, size, price, orderid, order_mode [,acctid=nothing])
```

where the types of `size` and `price` will be cast to the correct types.
The `orderid` and `acctid` types will not be cast in order to avoid ambiguity.
"""
struct Order{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}
    
    # data -
    side::OrderSide
    size::Sz
    price::Px
    orderid::Oid
    acctid::Union{Aid,Nothing}

    # constructor -
    function Order{Sz,Px,Oid,Aid}(
        side::OrderSide,
        size::Real,
        price::Real,
        orderid::Oid,
        acctid::Union{Aid,Nothing} = nothing,
    ) where {Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}
        new{Sz,Px,Oid,Aid}(side, Sz(size), Px(price), orderid, acctid) # cast price and size to correct types
    end
end

"""
    AcctMap{Sz,Px,Oid,Aid}

Collection of open orders by account.

`(Sz,Px,Oid,Aid)` characterize the type of Order present in the `AcctMap`.
See documentation on [`Order`](@ref) for more information on the meaning of types.

The account map is implemented as a `Dict` containing `AVLTree`s.
    AcctMap{Sz,Px,Oid,Aid} = Dict{Aid,AVLTree{Oid,Order{Sz,Px,Oid,Aid}}}
The outer key is the account id, mapping to an `AVLTree` of `Order`s keyed by order id.
"""
AcctMap{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer} = Dict{
    Aid,AVLTree{Oid,Order{Sz,Px,Oid,Aid}}
}

""""
OrderQueue is a queue of orders at a fixed price, implemented as a Deque/Vector.

OrderQueue.queue is a Vector (interpreted as double ended queue). Orders are added and removed via FIFO logic.
OrderQueue also keeps track of its contained volume in shares and orders

OrderQueue(price) Initializes an empty order queue at price
"""
struct OrderQueue{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}
    
    # data -
    price::Px # price at which queue is located
    queue::Vector{Order{Sz,Px,Oid,Aid}} # queue of orders as vector
    total_volume::Base.RefValue{Sz} # total volume in queue
    num_orders::Base.RefValue{Int64} # total size of queue
    
    
    # Initialize empty OrderQueue
    function OrderQueue{Sz,Px,Oid,Aid}(price::Px) where {Sz,Px,Oid,Aid}
        new{Sz,Px,Oid,Aid}(
            price,
            Vector{Order{Sz,Px,Oid,Aid}}(),
            Base.RefValue{Sz}(0),
            Base.RefValue{Int64}(0),
        )
    end
end

"""
    OneSidedBook{Sz,Px,Oid,Aid}

One-Sided book with order-id type Oid, account-id type Aid,
size type Sz and price type Px.

OneSidedBook is a one-sided book (i.e. :BID or :ASK) of order queues at
varying prices.

OrderQueues are stored in an AVLTree (.book) indexed
either by price (ASK side) or -price (BID side)

The book keeps track of various statistics such as the current best price,
total share and price volume, as well as total contained number of orders.

"""
@kwdef mutable struct OneSidedBook{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer}
    is_bid_side::Bool
    book::AVLTree{Px,OrderQueue{Sz,Px,Oid,Aid}} = AVLTree{Px,OrderQueue{Sz,Px,Oid,Aid}}()
    total_volume::Sz = 0 # Total volume available in shares
    total_volume_funds::Float64 = 0.0 # Total volume available in underlying currency
    num_orders::Int32 = Int32(0) # Number of orders in the book
    best_price::Union{Px,Nothing} = nothing # best bid or ask
end


"""
    OrderBook{Sz,Px,Oid,Aid}

An `OrderBook` is a data structure containing __limit orders__ represented as objects of type `Order{Sz,Px,Oid,Aid}`.

See documentation on [`Order`](@ref) for more information on this type.

How to use `Orderbook`:
 - Initialize an empty limit order book as `OrderBook{Sz,Px,Oid,Aid}()`
 - __Submit__ or __cancel__ limit orders with [`submit_limit_order!`](@ref) and [`cancel_order!`](@ref).
 - Submit __market orders__ with [`submit_market_order!`](@ref)
 - Retrieve order book state information with `print` or `show` methods, as well as [`book_depth_info`](@ref),
 [`best_bid_ask`](@ref), [`volume_bid_ask`](@ref), [`n_orders_bid_ask`](@ref) and [`get_acct`](@ref)
 - Write book state to `csv` file with [`write_csv`](@ref).

"""
mutable struct OrderBook{Sz<:Real,Px<:Real, Oid<:Integer, Aid<:Integer}
    
    # data -
    bid_orders::OneSidedBook{Sz,Px,Oid,Aid} # bid orders
    ask_orders::OneSidedBook{Sz,Px,Oid,Aid} # ask orders
    acct_map::AcctMap{Sz,Px,Oid,Aid} # Map from acct_id::Aid to AVLTree{order_id::Oid,Order{Sz,Px,Oid,Aid}}
    flags::Dict{Symbol,Any} # container for additional order book logic flags (not yet implemented)
    
    
    # constructor
    function OrderBook{Sz,Px,Oid,Aid}() where {Sz,Px,Oid,Aid}
        return new{Sz,Px,Oid,Aid}(
            OneSidedBook{Sz,Px,Oid,Aid}(; is_bid_side=true),
            OneSidedBook{Sz,Px,Oid,Aid}(; is_bid_side=false),
            AcctMap{Sz,Px,Oid,Aid}(),
            Dict{Symbol,Any}(:PlotTickMax => 5),
        )
    end
end

"""
Priority{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}  <: Comparable
"""
mutable struct Priority{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}  <: Comparable
    
    # data -
    size::Sz
    price::Px
    transcation_id::Oid
    account_id::Aid
    create_time::Dt
    ip_address::Ip
    port::Pt
    
    # constructor -
    function Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
        size::Sz, 
        price::Px, 
        transcation_id::Oid, 
        account_id::Aid, 
        create_time::Dt, 
        ip_address::Ip, 
        port::Pt) where {Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer,Dt<:DateTime,Ip<:String,Pt<:Integer}
        new{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
            Sz(size), Px(price), transcation_id, account_id, Dt(create_time), Ip(ip_address), Pt(port)
            )
    end
end


"""
OneSideUnmatchedBook{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}
"""
@kwdef mutable struct OneSideUnmatchedBook{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}
    
    # data -
    is_bid_side::Bool
    unmatched_book::SortedSet{Priority{Sz,Px,Oid,Aid,Dt,Ip,Pt}} = SortedSet{Priority{Sz,Px,Oid,Aid,Dt,Ip,Pt}}()
    total_volume::Sz = 0 # Total volume available in shares
    num_orders::Int32 = Int32(0) # Number of orders in the book
    best_price::Union{Px,Nothing} = nothing # best bid or ask

end

"""
UnmatchedOrder{Sz, Px, Oid, Aid, Dt, Ip} 

An `UnmatchedOrder` is a data structure containing __limit orders__ represented as 
objects of type `Order{Sz, Px, Oid, Aid, Dt, Ip} `.

"""
mutable struct UnmatchedOrderBook{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}
    
    # data -
    bid_unmatched_orders::OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt} # bid orders
    ask_unmatched_orders::OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt} # ask orders
    
    # constructor -
    function UnmatchedOrderBook{Sz, Px, Oid, Aid, Dt, Ip, Pt}() where {Sz, Px, Oid, Aid, Dt, Ip, Pt}
        return new{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
            OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt}(; is_bid_side=true),
            OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt}(; is_bid_side=false),
        )
    end
end


struct Monetary{name,decimals} <: Real where {name<:Symbol, decimals<:Int}
    amount::FixedDecimal{BigInt,decimals}
end

struct AssetMismatch <: Exception
    base::Symbol
    counter::Symbol
end



# Define Order, OrderQueue objects and relavant methods.





"""
    OrderTraits(allornone::Bool,immediateorcancel::Bool,allow_cross::Bool)

`OrderTraits` specify order traits which modify execution logic.

An instance can be initialized by using the keyword intializer or by using the exported constants
`VANILLA_FILLTYPE`, `IMMEDIATEORCANCEL_FILLTYPE`, `FILLORKILL_FILLTYPE`.

The default execution logic is represented by `VANILLA_FILLTYPE`.

__Note:__ This feature is not well supported yet.
Other than the constants described above, use non-vanilla modes with caution.

"""
Base.@kwdef struct OrderTraits
    allornone::Bool = false
    immediateorcancel::Bool = false
    allow_cross::Bool = true
end

# === CONCRETE TYPES ABOBE (EXPORTED) =========================================================================================== %