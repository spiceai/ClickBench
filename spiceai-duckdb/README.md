# Spice.ai OSS (DuckDB Engine)

[Spice.ai OSS](https://github.com/spiceai/spiceai) is a unified SQL query interface and portable runtime that accelerates and queries data from any database, data warehouse, or data lake. This benchmark uses Spice.ai OSS with the **DuckDB** acceleration engine.

## DuckDB Engine

This variant uses DuckDB as the acceleration engine within Spice.ai OSS. DuckDB provides:
- Mature columnar analytical processing
- Extensive SQL feature support
- Efficient Parquet handling
- Battle-tested query optimization

## Hardware Configuration

Recommended hardware (for fair ClickBench comparison):
- **Instance**: AWS c6a.4xlarge
- **vCPUs**: 16
- **RAM**: 32 GB
- **Storage**: 500 GB gp2 SSD
- **OS**: Ubuntu 22.04 or later

## Running the Benchmark

### Prerequisites
- Linux/macOS system with bash
- sudo access (for cache clearing)
- `bc` utility installed
- Internet connection for downloading Spice.ai OSS and dataset

### Quick Start

```bash
# Clone the repository
git clone https://github.com/ClickHouse/ClickBench
cd ClickBench/spiceai-duckdb

# Run the complete benchmark (automated)
bash run.sh
```

### What the Benchmark Does

The `run.sh` script performs the following:

1. **Installs Spice.ai OSS** - Downloads and installs the latest Spice CLI
2. **Downloads Dataset** - Fetches the ClickBench hits.parquet file (~14.5 GB, 100M rows)
3. **Loads Data** - Configures Spice to accelerate the dataset using the DuckDB engine
4. **Runs Queries** - Executes all 43 ClickBench queries with:
   - 3 runs per query
   - True cold runs (Spice runtime restarted between each run)
   - System cache clearing before each run
5. **Outputs Results** - Generates timing results in ClickBench format

### Benchmark Details

- **Cold Runs**: Each query execution restarts the Spice runtime completely to ensure true cold performance (no warm cache effects)
- **Query Count**: 43 standard ClickBench queries
- **Runs per Query**: 3
- **Result Format**: Minimum of 3 runs is reported for leaderboard
- **Cache Clearing**: Uses `sync` and `echo 3 > /proc/sys/vm/drop_caches` before each run

### Configuration

The benchmark uses `spicepod.yaml` to configure the dataset:

```yaml
version: v1beta1
kind: Spicepod
name: clickbench-duckdb

datasets:
  - from: file:hits.parquet
    name: hits
    acceleration:
      enabled: true
      engine: duckdb
      mode: file
```

### Results

Results are saved in multiple formats:
- `log.txt` - Full benchmark output
- `result.csv` - CSV format with query number, run number, and timing
- `results.json` - JSON array of timing arrays for each query

### Comparison with Native DuckDB

This benchmark measures Spice.ai OSS with DuckDB as the acceleration engine, which includes:
- Spice runtime overhead
- Query protocol translation
- Additional abstraction layers

For native DuckDB performance, see the separate `duckdb/` benchmark directory.

### Version Information

Run `spice version` after installation to see the exact version being benchmarked.

## Manual Testing

To manually test individual queries:

```bash
# Start Spice runtime
spice run &

# Wait for initialization
sleep 5

# Run a query
echo "SELECT COUNT(*) FROM hits;" | spice sql

# Stop runtime
pkill spiced
```

## Performance Notes

- DuckDB engine provides excellent SQL compatibility
- Performance includes Spice.ai runtime overhead
- Cold run performance includes runtime startup overhead (~2-5 seconds)
- This tests the integration of DuckDB within Spice.ai's unified query interface
