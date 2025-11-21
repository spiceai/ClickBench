#!/bin/bash

set -e

echo "Installing Spice.ai OSS..."
curl https://install.spiceai.org | /bin/bash
export PATH="$HOME/.spice/bin:$PATH"

# Verify installation
spice version

echo "Downloading ClickBench dataset..."
wget --continue --progress=dot:giga 'https://datasets.clickhouse.com/hits_compatible/hits.parquet'

echo "Starting Spice runtime and loading data with DuckDB engine..."
# Kill any existing Spice processes
pkill -9 spiced || true
sleep 2

# Start Spice runtime in background
spice run > spice.log 2>&1 &
SPICE_PID=$!

# Wait for Spice to initialize and load the dataset
echo "Waiting for dataset to be accelerated..."
sleep 30

# Check if data is loaded
echo "SELECT COUNT(*) FROM hits;" | spice sql || {
    echo "Failed to load data. Check spice.log for details."
    cat spice.log
    exit 1
}

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

# Get data size in bytes
DATA_SIZE=$(stat -f%z hits.parquet 2>/dev/null || stat -c%s hits.parquet 2>/dev/null)

echo "Data size: $DATA_SIZE bytes"

echo ""
echo "Formatting results..."

# Extract timing results and format as JSON with proper indentation
RESULTS=$(cat log.txt | grep -P '^\[' | sed 's/^/        /' | sed 's/,$//')

# Create JSON output
cat > results/c6a.4xlarge.json <<EOF
{
    "system": "Spice.ai OSS (DuckDB)",
    "date": "$(date +%Y-%m-%d)",
    "machine": "c6a.4xlarge",
    "cluster_size": 1,
    "proprietary": "no",
    "tuned": "no",
    "tags": ["Rust", "column-oriented", "distributed", "cold-run"],
    "load_time": 0,
    "data_size": ${DATA_SIZE},
    "result": [
${RESULTS}
    ]
}
EOF

echo ""
echo "Results saved to results/c6a.4xlarge.json"
cat results/c6a.4xlarge.json
