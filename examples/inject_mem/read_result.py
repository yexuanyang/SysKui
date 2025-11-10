import argparse
import json
import os
import subprocess
import sys

if __name__ == "__main__":
    results = {}
    parser = argparse.ArgumentParser(
        prog="read_result", description="Read results from memory fault injection jobs"
    )
    parser.add_argument("--container", required=True, help="container id of lava-slave")
    parser.add_argument("--output", "-o", required=True, help="result output file")
    parser.add_argument(
        "--input", "-i", required=True, help="job input file, store the jobs' id"
    )
    parser.add_argument(
        "--suffix",
        required=True,
        help="the suffix of log file in container",
    )
    parser.add_argument(
        "--kernel",
        help="kernel to use",
        type=str,
        choices=["linux", "openeuler", "phytium"],
        required=True,
    )
    parser.add_argument(
        "--mem-start",
        help="Start address of memory region (for reference)",
        type=str,
        default=None,
    )
    parser.add_argument(
        "--mem-end",
        help="End address of memory region (for reference)",
        type=str,
        default=None,
    )

    args = parser.parse_args()

    with open(args.input, "r") as f:
        jobs = eval(f.read())

        total_fault = 0
        total_panic = 0
        for index, jobid in enumerate(jobs):
            dir_path = f"/tmp/{jobid}"
            # Memory injection uses "mem" instead of register name
            log_path = f"/tmp/log-{args.kernel}-{index}-mem-{args.suffix}.csv"
            panic_file = os.path.join(dir_path, "panic_count.txt")
            fault_file = os.path.join(dir_path, "fault_number.txt")

            panic_count = subprocess.run(
                ["docker", "exec", args.container, "cat", panic_file],
                capture_output=True,
                text=True,
            ).stdout
            fault_count = subprocess.run(
                ["docker", "exec", args.container, "cat", fault_file],
                capture_output=True,
                text=True,
            ).stdout
            log_str = subprocess.run(
                ["docker", "exec", args.container, "cat", log_path],
                capture_output=True,
                text=True,
            ).stdout
            log_str_lines = log_str.splitlines()
            log = {}
            keys = []
            injection_type = "ram"  # Memory injection type
            addresses = []
            bit_indices = []

            for i, line in enumerate(log_str_lines):
                if i == 0:
                    keys = line.split(",")
                    continue
                if line.strip():  # Skip empty lines
                    values = line.split(",")
                    for idx, v in enumerate(values):
                        if idx < len(keys):
                            log.setdefault(keys[idx], [])
                            log[keys[idx]].append(v)

                    # Extract address and bit index from log if available
                    if len(values) > 1:
                        # Assuming format: type, address, bit_index, ...
                        if len(values) > 1 and values[1] not in addresses:
                            addresses.append(values[1])  # address
                        if len(values) > 2 and values[2] not in bit_indices:
                            bit_indices.append(values[2])  # bit index

            if panic_count != "" and fault_count != "":
                total_panic += int(panic_count, 10)
                total_fault += int(fault_count, 10)
            else:
                print(f"{jobid} should resubmit or not finished", file=sys.stderr)
                panic_count = 0
                fault_count = 0

            results[jobid] = {
                "job_index": index,
                "injection_type": injection_type,
                "addresses": addresses,
                "bit_indices": bit_indices,
                "panic_count": panic_count,
                "fault_count": fault_count,
                "log": log,
            }

            print(f"Job {jobid} (index: {index})")
            print(f"  Injection type: {injection_type}")
            print(f"  Addresses: {addresses if addresses else 'N/A'}")
            print(f"  Bit indices: {bit_indices if bit_indices else 'N/A'}")
            print(f"  Panic count: {panic_count}")
            print(f"  Fault count: {fault_count}")
            print("-" * 40)

        results["total_panic"] = total_panic
        results["total_fault"] = total_fault
        results["summary"] = {
            "total_jobs": len(jobs),
            "total_panic": total_panic,
            "total_fault": total_fault,
            "panic_rate": f"{total_panic}/{total_fault}" if total_fault > 0 else "0/0",
        }

        if args.mem_start and args.mem_end:
            results["summary"]["mem_range"] = f"{args.mem_start}-{args.mem_end}"

        with open(args.output, "w") as f:
            json.dump(results, f, indent=4, ensure_ascii=False)

        print("=" * 40)
        print(f"Total panic/total fault: {total_panic}/{total_fault}")
        if total_fault > 0:
            panic_percentage = (total_panic / total_fault) * 100
            print(f"Panic rate: {panic_percentage:.2f}%")
        print(f"Results saved to: {args.output}")
