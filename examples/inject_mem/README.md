# inject_mem

This example shows how to inject random faults to memory regions in SysKui.

`generate_job.py` generates jobs which will launch QEMU and inject random faults to specified memory regions, and submit them to LAVA. The generated `job_id`s will be stored in file `jobs.txt`.

## Key Features

- **Random Memory Fault Injection**: Injects faults at random memory addresses within a specified range
- **Configurable Fault Count**: Each job can inject multiple faults (default: 4 faults per job)
- **Bit-level Precision**: Randomly selects bit positions (0-63) for each fault
- **Reproducibility**: Optional random seed parameter for reproducible fault injection patterns

## Parameters

- `--mem-start`: Start address of the memory region in hex format (e.g., `0x40000000`)
- `--mem-end`: End address of the memory region in hex format (e.g., `0x80000000`)
- `--qemu-number`: Number of QEMU instances to create (default: 64)
- `--faults-per-job`: Number of random memory faults to inject per job (default: 4)
- `--xmlrpc-url`: LAVA server XMLRPC URL
- `--job-output` / `-j`: Output file path to store job IDs (default: `jobs.txt`)
- `--port-start` / `-p`: Starting SSH port number (default: 2000)
- `--suffix`: Log CSV suffix number
- `--kernel`: Kernel to use (choices: `linux`, `openeuler`, `phytium`)
- `--seed`: Optional random seed for reproducibility

## How It Works

1. For each QEMU instance, the script generates `--faults-per-job` random fault injection parameters
2. Each fault consists of:
   - A random memory address within the range `[mem_start, mem_end]`
   - A random bit index (0-63) to flip
3. The faults are injected using `snapinject` with `--fault-type ram`
4. Each injection is logged to a CSV file for analysis

## Usage Example

```bash
# Generate 16 jobs, each injecting 4 random memory faults in the range 0x40000000-0x80000000
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 16 \
    --faults-per-job 4 \
    --xmlrpc-url "http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/" \
    --job-output jobs.txt \
    --port-start 2000 \
    --suffix 1 \
    --kernel linux \
    --seed 42

# Check the generated job IDs
cat jobs.txt

# Wait for LAVA jobs to finish...

# Use docker ps to see the lava-slave container
docker ps

# Read results
python3 read_result.py \
    --container <container_id> \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000
```

## Reading Results

After jobs complete, use `read_result.py` to collect and analyze results:

```bash
python3 read_result.py \
    --container <lava_slave_container_id> \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000
```

### read_result.py Parameters

- `--container`: Docker container ID of lava-slave
- `--input` / `-i`: Input file containing job IDs (e.g., `jobs.txt`)
- `--output` / `-o`: Output JSON file for results (e.g., `results.json`)
- `--suffix`: Log file suffix used in generation
- `--kernel`: Kernel type used (`linux`, `openeuler`, or `phytium`)
- `--mem-start`: (Optional) Memory range start for reference
- `--mem-end`: (Optional) Memory range end for reference

### Output Format

The results are saved in JSON format with the following structure:

```json
{
  "12345": {
    "job_index": 0,
    "injection_type": "ram",
    "addresses": ["0x4e4018bf", "0x6334292b", ...],
    "bit_indices": ["3", "31", ...],
    "panic_count": "2",
    "fault_count": "4",
    "log": { ... }
  },
  "total_panic": 10,
  "total_fault": 64,
  "summary": {
    "total_jobs": 16,
    "total_panic": 10,
    "total_fault": 64,
    "panic_rate": "10/64",
    "mem_range": "0x40000000-0x80000000"
  }
}
```

### Analyzing Results

```bash
# View summary
cat results.json | jq '.summary'

# View specific job
cat results.json | jq '.\"12345\"'

# Count panics per job
cat results.json | jq '[to_entries[] | select(.key | test("^[0-9]+$")) | .value.panic_count | tonumber] | add'

# List all jobs with panics
cat results.json | jq '[to_entries[] | select(.key | test("^[0-9]+$")) | select(.value.panic_count != "0") | {job: .key, panics: .value.panic_count}]'
```

## Differences from inject_pc

- **inject_pc**: Injects faults to CPU registers (e.g., PC register bits)
- **inject_mem**: Injects faults to random memory addresses within a specified range
- The memory version provides more flexibility in fault location and can cover larger address spaces
- Each job can inject multiple random faults at different addresses and bit positions

## Notes

- The memory address range should be valid RAM addresses accessible by the guest OS
- Use `--seed` parameter to generate reproducible fault patterns for debugging
- Adjust `--faults-per-job` based on your testing requirements (more faults = more comprehensive testing but longer execution time)
- The `snapinject` command creates a snapshot before injection and restores it after observation, ensuring each fault is tested independently
