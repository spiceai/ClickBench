#!/bin/bash

TRIES=3
QUERY_NUM=1

cat queries.sql | while read -r query; do
    echo -n "["
    for i in $(seq 1 $TRIES); do
        # Clear caches for cold run
        sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
        
        # Stop and restart Spice runtime to ensure true cold run
        pkill -9 spiced || true
        sleep 2

        # Delete .spice directory to ensure no cached data
        rm -rf $HOME/.spice
        
        # Start Spice runtime in background
        spice run > /tmp/spice_${QUERY_NUM}_${i}.log 2>&1 &
        SPICE_PID=$!
        
        # Wait for Spice to be ready (check if it's responding)
        READY=0
        for attempt in $(seq 1 30); do
            if echo "SELECT 1;" | spice sql > /dev/null 2>&1; then
                READY=1
                break
            fi
            sleep 1
        done
        
        if [ $READY -eq 0 ]; then
            echo -n "null"
            [[ "$i" != $TRIES ]] && echo -n ", "
            echo "${QUERY_NUM},${i},null" >> result.csv
            kill $SPICE_PID 2>/dev/null || true
            pkill -9 spiced || true
            continue
        fi
        
        # Execute query with timing
        RESULT=$(echo "$query" | /usr/bin/time -f '%e' spice sql 2>&1 > /tmp/query_result_${QUERY_NUM}_${i}.txt)
        
        # Extract timing from time output (last line)
        DURATION=$(echo "$RESULT" | tail -n 1 | grep -oE '[0-9]+\.[0-9]+')
        
        if [ -z "$DURATION" ]; then
            echo -n "null"
        else
            echo -n "$DURATION"
        fi
        
        [[ "$i" != $TRIES ]] && echo -n ", "
        
        echo "${QUERY_NUM},${i},${DURATION:-null}" >> result.csv
        
        # Stop Spice runtime
        kill $SPICE_PID 2>/dev/null || true
        pkill -9 spiced || true
        sleep 1
    done
    echo "],"
    
    QUERY_NUM=$((QUERY_NUM + 1))
done
