#!/bin/bash

declare -a clients
for((i=1;i<=$1;i++));do
	lua test_throughput.lua $2 >> log/$!.log &
	echo client:$!
	clients[i]=$!
done

wait ${clients[1]}
