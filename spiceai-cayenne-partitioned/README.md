# Spice.ai (Cayenne Engine) - Partitioned

[Spice.ai](https://spice.ai) is a unified SQL query interface and portable runtime that accelerates and queries data from any database, data warehouse, or data lake. This benchmark uses Spice.ai with the **Cayenne** acceleration engine on **partitioned Parquet files from S3**.

## Cayenne Engine

Cayenne is Spice.ai's native high-performance query engine optimized for analytical workloads. It provides:
- Native Parquet support with efficient columnar processing
- Advanced query optimization
- Zero-copy data access where possible

## Partitioned Dataset

This variant uses the partitioned ClickBench dataset:
- **Source**: `https://datasets.clickhouse.com/hits_compatible/athena_partitioned/`
- **Format**: Partitioned Parquet files (100 files)
- **Rows**: ~100 million
- **Size**: ~14.5 GB

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
- Internet connection for downloading Spice.ai and accessing dataset

### Quick Start

```bash
# Clone the repository
git clone https://github.com/ClickHouse/ClickBench
cd ClickBench/spiceai-cayenne-partitioned

# Run the complete benchmark (automated)
bash run.sh
```

### What the Benchmark Does

The `run.sh` script performs the following:

1. **Installs Spice.ai** - Downloads and installs the latest Spice CLI
2. **Loads Data from HTTPS** - Configures Spice to accelerate the partitioned dataset using the Cayenne engine
3. **Waits for Acceleration** - Allows time for data to be loaded and accelerated
4. **Runs Queries** - Executes all 43 ClickBench queries with:
   - 3 runs per query
   - True cold runs (Spice runtime restarted between each run)
   - System cache clearing before each run
5. **Outputs Results** - Generates timing results in ClickBench JSON format

### Benchmark Details

- **Cold Runs**: Each query execution restarts the Spice runtime completely to ensure true cold performance (no warm cache effects)
- **Query Count**: 43 standard ClickBench queries
- **Runs per Query**: 3
- **Result Format**: JSON with timing arrays in `results/c6a.4xlarge.json`
- **Cache Clearing**: Uses `sync` and `echo 3 > /proc/sys/vm/drop_caches` before each run

### Configuration

The benchmark uses `spicepod.yaml` to configure the dataset:

```yaml
version: v1beta1
kind: Spicepod
name: clickbench-cayenne-partitioned

datasets:
  - from: https://datasets.clickhouse.com/hits_compatible/athena_partitioned/
    name: hits
    params:
      file_format: parquet
    acceleration:
      enabled: true
      engine: cayenne
      mode: file
```

### Results

Results are saved to `results/c6a.4xlarge.json` in the standard ClickBench format.

### Known Limitations

Some queries may fail or return null if they use features not yet fully supported by the Cayenne engine. This is expected and acceptable for ClickBench submissions.

### Version Information

Run `spice version` after installation to see the exact version being benchmarked.

## Comparison with Non-Partitioned

This partitioned variant loads data directly from HTTPS partitioned Parquet files, which may have different performance characteristics compared to the non-partitioned local file variant.
