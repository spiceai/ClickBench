#!/bin/bash

set -e

echo "Installing Spice.ai OSS..."
curl https://install.spiceai.org | /bin/bash
export PATH="$HOME/.spice/bin:$PATH"

# Verify installation
spice version

echo "Starting Spice runtime and loading data from HTTPS (partitioned) with DuckDB engine..."
# Kill any existing Spice processes
pkill -9 spiced || true
sleep 2

# Start Spice runtime in background
spice run > spice.log 2>&1 &
SPICE_PID=$!

# Wait for Spice to initialize and load the dataset from HTTPS
echo "Waiting for dataset to be accelerated from HTTPS..."
echo "This may take several minutes as data is loaded..."
sleep 60

# Check if data is loaded
RETRIES=10
for i in $(seq 1 $RETRIES); do
    if echo "SELECT COUNT(*) FROM hits;" | spice sql 2>&1 | grep -q "99997497"; then
        echo "Data loaded successfully!"
        break
    fi
    if [ $i -eq $RETRIES ]; then
        echo "Failed to load data after $RETRIES attempts. Check spice.log for details."
        cat spice.log
        exit 1
    fi
    echo "Waiting for data to load... (attempt $i/$RETRIES)"
    sleep 30
done

# Stop Spice before running benchmarks (benchmarks will restart it)
kill $SPICE_PID 2>/dev/null || true
pkill -9 spiced || true
sleep 2

echo "Running benchmarks (3 cold runs per query, 43 queries)..."
echo "This will take a while as each run restarts Spice for true cold runs..."

chmod +x benchmark.sh
./benchmark.sh 2>&1 | tee log.txt

echo ""
echo "Benchmark complete!"
echo ""

# Note: Data size is on remote HTTPS, not local
echo "Data source: HTTPS (partitioned Parquet files)"

echo ""
echo "Formatting results..."

# Extract timing results and format as JSON with proper indentation
RESULTS=$(cat log.txt | grep -P '^\[' | sed 's/^/        /' | sed 's/,$//')

# Create JSON output
cat > results/c6a.4xlarge.json <<EOF
{
    "system": "Spice.ai OSS (DuckDB) Partitioned",
    "date": "$(date +%Y-%m-%d)",
    "machine": "c6a.4xlarge",
    "cluster_size": 1,
    "proprietary": "no",
    "tuned": "no",
    "tags": ["Rust", "column-oriented", "distributed", "cold-run", "partitioned"],
    "load_time": 0,
    "data_size": 0,
    "result": [
${RESULTS}
    ]
}
EOF

echo ""
echo "Results saved to results/c6a.4xlarge.json"
cat results/c6a.4xlarge.json
