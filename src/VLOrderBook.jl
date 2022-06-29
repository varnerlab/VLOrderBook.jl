module VLOrderBook

# include -
include("Include.jl")

# export types -
export BUY_ORDER, SELL_ORDER, VANILLA_FILLTYPE, IMMEDIATEORCANCEL_FILLTYPE, FILLORKILL_FILLTYPE
export OrderBook, Order, OrderTraits, AcctMap, OrderSide
export Monetary, AssetMismatch
export Priority, OneSideUnmatchedBook, UnmatchedOrderBook

# export functions -
export submit_order!,
    insert_unmatched_order!,
    submit_limit_order!,
    cancel_order!,
    submit_market_order!,
    submit_market_order_byfunds!,
    clear_book!,
    book_depth_info,
    volume_bid_ask,
    best_bid_ask,
    n_orders_bid_ask,
    bid_orders,
    ask_orders,
    get_acct,
    write_csv,
    process_file,
    order_types,
    pop_unmatched_order_withinfilter!
end
