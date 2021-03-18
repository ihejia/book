#!/bin/bash
ping -c 10 61.139.2.69 2>&1 |tee ping.log && grep icmp ping.log | awk -F " " '{print $7}' |awk -F = '{print NR,$2}' |awk '{sum+=$2} END {print "Ping times Avg =", sum/NR}'
