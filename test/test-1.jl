begin # Create (Deterministic) Limit Order Generator
    MyOrderSubTypes = (Int64,Float64,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}
    MyUOBType = UnmatchedOrderBook{Int64, Float64, Int64, Int64, DateTime, String, Integer}

    using Base.Iterators: cycle, take, zip, flatten
    orderid_iter = Base.Iterators.countfrom(1)
    sign_iter = cycle([1,-1,-1,1,1,-1])
    side_iter = ( s>0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
    spread_iter = cycle([3 2 3 2 2 2 3 2 3 4 2 2 3 2 3 2 3 3 2 2 3 2 5 2 2 2 2 2 4 2 3 6 5 6 3 2 3 5 4]*1e-2)
    price_iter = ( Float32(100.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
    size_iter = cycle([2,5,3,4,10,15,1,6,13,11,4,1,5])
    # zip them all together
    lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)
end

begin # Create (Deterministic) Market Order Generator
    mkt_size_iter = cycle([10,20,30,15,25,5,7])
    mkt_side_iter = cycle([SELL_ORDER,BUY_ORDER,BUY_ORDER,SELL_ORDER,BUY_ORDER,SELL_ORDER])
    mkt_order_info_iter = zip(mkt_size_iter,mkt_side_iter)
end

@testset "Submit and Cancel 1" begin # Add and delete all orders, verify book is empty, verify account tracking
    ob = MyLOBType() #Initialize empty book
    uob = MyUOBType()

    order_info_lst = take(lmt_order_info_iter,50000)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,uob,orderid,side,price,size,10101)
    end
    @test length(ob.acct_map[10101]) == 50000 # Check account order tracking
    # Cancel them all
    for (orderid, price, size, side) in order_info_lst
        cancel_order!(ob,orderid,side,price)
    end
    # Check emptiness
    @test isempty(ob.bid_orders)
    @test isempty(ob.ask_orders)
    @test isempty(ob.acct_map[10101])
end