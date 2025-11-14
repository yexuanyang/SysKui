#!/usr/bin/env python3
"""
Read and analyze results from disk fault injection jobs.

This script collects panic counts and fault information from LAVA jobs
that performed disk fault injection tests.
"""

import argparse
import json
import os
import re
import subprocess
import sys


def parse_yaml_for_injection_info(yaml_file):
    """
    Parse YAML file to extract injection offset and size.

    Returns:
        tuple: (offset_bytes, size_bytes) or (None, None) if parsing fails
    """
    try:
        with open(yaml_file, "r") as f:
            content = f.read()
            # Extract offset from: skip=624149208
            offset_match = re.search(r"skip=(\d+)", content)
            # Extract size from: count=1048576 seek=
            size_match = re.search(r"count=(\d+)\s+seek=", content)

            if offset_match and size_match:
                return int(offset_match.group(1)), int(size_match.group(1))
    except Exception:
        pass
    return None, None


def main():
    parser = argparse.ArgumentParser(
        prog="read_result", description="Read results from disk fault injection jobs"
    )
    parser.add_argument(
        "--container", required=True, help="Docker container ID of lava-slave"
    )
    parser.add_argument(
        "--output", "-o", required=True, help="Output JSON file for results"
    )
    parser.add_argument(
        "--input", "-i", required=True, help="Input file containing job IDs (jobs.txt)"
    )
    parser.add_argument(
        "--yaml-dir",
        default="generated_disk_yamls",
        help="Directory containing generated YAML files (default: generated_disk_yamls)",
    )

    args = parser.parse_args()

    # Read job IDs from input file
    with open(args.input, "r") as f:
        jobs = eval(f.read().strip())

    results = {}
    total_panic = 0
    total_fault = 0
    completed_jobs = 0
    failed_jobs = 0

    print(f"Processing {len(jobs)} jobs...\n")

    for index, jobid in enumerate(jobs):
        # Paths in container
        dir_path = f"/tmp/{jobid}"
        panic_file = os.path.join(dir_path, "panic_count.txt")
        fault_file = os.path.join(dir_path, "fault_number.txt")

        # Output files
        stdout_file = f"/tmp/inject_disk_program_{index}.out"
        stderr_file = f"/tmp/inject_disk_program_{index}.err"

        # Read panic count
        panic_count_raw = subprocess.run(
            ["docker", "exec", args.container, "cat", panic_file],
            capture_output=True,
            text=True,
        ).stdout.strip()

        # Read fault count
        fault_count_raw = subprocess.run(
            ["docker", "exec", args.container, "cat", fault_file],
            capture_output=True,
            text=True,
        ).stdout.strip()

        # Read stdout for injection details
        stdout_content = subprocess.run(
            ["docker", "exec", args.container, "cat", stdout_file],
            capture_output=True,
            text=True,
        ).stdout

        # Read stderr for errors
        stderr_content = subprocess.run(
            ["docker", "exec", args.container, "cat", stderr_file],
            capture_output=True,
            text=True,
        ).stdout

        # Parse injection info from YAML file
        yaml_file = os.path.join(args.yaml_dir, f"disk_inject_{index}.yaml")
        inject_offset, inject_size = parse_yaml_for_injection_info(yaml_file)

        # Process counts
        if panic_count_raw and fault_count_raw:
            panic_count = int(panic_count_raw, 10)
            fault_count = int(fault_count_raw, 10)
            total_panic += panic_count
            total_fault += fault_count
            completed_jobs += 1
            status = "completed"
        else:
            panic_count = 0
            fault_count = 0
            failed_jobs += 1
            status = "incomplete/failed"
            print(f"⚠ Job {jobid} (index: {index}): {status}", file=sys.stderr)

        # Store results for this job
        results[str(jobid)] = {
            "job_index": index,
            "injection_type": "disk",
            "inject_offset_bytes": inject_offset,
            "inject_size_bytes": inject_size,
            "inject_offset_mb": round(inject_offset / (1024 * 1024), 2)
            if inject_offset
            else None,
            "inject_size_mb": round(inject_size / (1024 * 1024), 2)
            if inject_size
            else None,
            "panic_count": panic_count,
            "fault_count": fault_count,
            "status": status,
            "stdout_preview": stdout_content[:500] if stdout_content else "",
            "stderr_preview": stderr_content[:500] if stderr_content else "",
        }

        # Print progress
        if (index + 1) % 50 == 0 or (index + 1) == len(jobs):
            print(f"Progress: {index + 1}/{len(jobs)} jobs processed")

    # Calculate summary statistics
    panic_rate = (total_panic / total_fault * 100) if total_fault > 0 else 0

    results["summary"] = {
        "total_jobs": len(jobs),
        "completed_jobs": completed_jobs,
        "failed_jobs": failed_jobs,
        "total_panic": total_panic,
        "total_fault": total_fault,
        "panic_rate_percent": round(panic_rate, 2),
        "panic_rate": f"{total_panic}/{total_fault}",
    }

    # Save results to JSON file
    with open(args.output, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Total jobs: {len(jobs)}")
    print(f"Completed: {completed_jobs}")
    print(f"Failed/Incomplete: {failed_jobs}")
    print(f"Total panic: {total_panic}")
    print(f"Total fault: {total_fault}")
    print(f"Panic rate: {panic_rate:.2f}% ({total_panic}/{total_fault})")
    print("=" * 60)
    print(f"Results saved to: {args.output}")


if __name__ == "__main__":
    main()
