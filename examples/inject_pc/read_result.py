import argparse
import json
import os
import subprocess

if __name__ == "__main__":
    results = {}
    parser = argparse.ArgumentParser(prog="read_result")
    parser.add_argument("--container", required=True, help="container id of lava-slave")

    args = parser.parse_args()

    with open("jobs.txt", "r") as f:
        jobs = eval(f.read())

        total_fault = 0
        total_panic = 0
        for index, jobid in enumerate(jobs):
            dir_path = f"/tmp/{jobid}"
            bit_index = list(range(index * 4, index * 4 + 4))
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
            total_panic += int(panic_count, 10)
            total_fault += int(fault_count, 10)

            results[jobid] = {
                "bit_index": bit_index,
                "panic_count": panic_count,
                "fault_count": fault_count,
                "register": "pc",
            }

            print(f"bit_index: {bit_index}, register: pc")
            print(f"panic_count: {panic_count}")
            print(f"fault_count: {fault_count}")
            print("-" * 40)

        results["total_panic"] = total_panic
        results["total_fault"] = total_fault
        with open("results.json", "w") as f:
            json.dump(results, f, indent=4, ensure_ascii=False)
        print(f"total_panic/total_fault: {total_panic}/{total_fault}")
