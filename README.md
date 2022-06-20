# VLOrderBook
This project was modified based on https://github.com/p-casgrain/LimitOrderBook.jl<br>
The project Money can be find in https://github.com/swiesend/Money.jl

## Extended Features
1. Fix some bug for the original package "https://github.com/p-casgrain/LimitOrderBook.jl"

2. Function "write_csv" and "process_file" will save the current statue of orderbook, the files will be save into CSV file

3. There will be a notify feature send to the client/broker. In other word, the broker will need to start listening mode.
To implement this feature, a client/broker script need to  run, then if the order did not match immediately, it will be stored some place. As soon as it matched, it will notify the client/broker.
For the detailed design, please see "test/WebSocket/test/client.jl"
