# Disk Injection Job Submission

This script submits all YAML files in the `generated_disk_yamls` directory to a LAVA server and saves the job IDs.

## Usage

### Basic Usage

Submit all YAML files with default settings:

```bash
python3 submit.py
```

This will:
- Submit all `.yaml` files from `generated_disk_yamls/` directory
- Save job IDs to `jobs.txt` in Python list format: `[id1, id2, id3, ...]`
- Use the default XMLRPC URL

### Custom Options

```bash
# Use custom XMLRPC URL
python3 submit.py --xmlrpc-url "http://admin:token@server:9999/RPC2/"

# Save to a different file
python3 submit.py --output my_jobs.txt

# Verbose mode (show each submission)
python3 submit.py --verbose

# Dry run (don't actually submit, just list files)
python3 submit.py --dry-run

# Use a different YAML directory
python3 submit.py --yaml-dir path/to/yamls
```

### Combined Options

```bash
python3 submit.py \
    --xmlrpc-url "http://admin:mytoken@10.161.28.20:9999/RPC2/" \
    --yaml-dir generated_disk_yamls \
    --output jobs.txt \
    --verbose
```

## Parameters

| Parameter | Short | Default | Description |
|-----------|-------|---------|-------------|
| `--xmlrpc-url` | - | `http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/` | LAVA server XMLRPC URL |
| `--yaml-dir` | - | `generated_disk_yamls` | Directory containing YAML files |
| `--output` | `-o` | `jobs.txt` | Output file to save job IDs |
| `--verbose` | `-v` | `False` | Print each submission |
| `--dry-run` | - | `False` | List files without submitting |

## Output Format

The job IDs are saved in Python list format:

```
[12345, 12346, 12347, 12348, ...]
```

This format can be easily loaded in Python:

```python
with open('jobs.txt', 'r') as f:
    job_ids = eval(f.read().strip())
    print(f"Total jobs: {len(job_ids)}")
    print(f"First job: {job_ids[0]}")
```

## Example Workflow

1. **Dry run to verify** (recommended first step):
   ```bash
   python3 submit.py --dry-run
   ```

2. **Submit jobs**:
   ```bash
   python3 submit.py --verbose
   ```

3. **Check the output**:
   ```bash
   cat jobs.txt
   ```

4. **Monitor jobs** (example):
   ```python
   import xmlrpc.client
   
   server = xmlrpc.client.ServerProxy("http://admin:token@server:9999/RPC2/")
   
   with open('jobs.txt', 'r') as f:
       job_ids = eval(f.read().strip())
   
   for job_id in job_ids[:5]:  # Check first 5 jobs
       status = server.scheduler.job_state(job_id)
       print(f"Job {job_id}: {status}")
   ```

## Notes

- The script will skip files that fail to submit and continue with the rest
- Progress is shown every 10 jobs (or use `--verbose` to see each one)
- Failed submissions are reported at the end
- Job IDs are only saved if at least one job is successfully submitted

## Troubleshooting

**Error: "Directory generated_disk_yamls does not exist"**
- Make sure you're in the correct directory
- Or use `--yaml-dir` to specify the correct path

**Error: "No YAML files found"**
- Check that the directory contains `.yaml` files
- Verify the file permissions

**Error: "Error connecting to LAVA server"**
- Verify the XMLRPC URL is correct
- Check network connectivity
- Verify credentials in the URL

**Some jobs failed to submit**
- Check the error messages for specific failures
- Verify the YAML file format is correct
- Check LAVA server logs for more details
