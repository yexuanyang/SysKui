#!/usr/bin/env python3
"""
Submit all YAML files in generated_disk_yamls directory to LAVA server
and save job IDs to jobs.txt
"""

import argparse
import glob
import os
import sys
import xmlrpc.client


def submit_yaml_files(xmlrpc_url, yaml_dir, output_file, verbose=False):
    """
    Submit all YAML files to LAVA server via XMLRPC

    Args:
        xmlrpc_url: LAVA server XMLRPC URL
        yaml_dir: Directory containing YAML files
        output_file: File to save job IDs
        verbose: Print verbose output

    Returns:
        List of job IDs
    """
    # Connect to LAVA server
    if verbose:
        print(f"Connecting to LAVA server: {xmlrpc_url}")

    try:
        server = xmlrpc.client.ServerProxy(xmlrpc_url)
    except Exception as e:
        print(f"Error connecting to LAVA server: {e}")
        sys.exit(1)

    # Find all YAML files
    yaml_pattern = os.path.join(yaml_dir, "*.yaml")
    yaml_files = sorted(glob.glob(yaml_pattern))

    if not yaml_files:
        print(f"No YAML files found in {yaml_dir}")
        sys.exit(1)

    print(f"Found {len(yaml_files)} YAML files to submit")

    # Submit each YAML file
    job_ids = []
    successful = 0
    failed = 0

    for i, yaml_file in enumerate(yaml_files, 1):
        try:
            # Read YAML file
            with open(yaml_file, "r") as f:
                yaml_content = f.read()

            # Submit job
            job_id = server.scheduler.submit_job(yaml_content)
            job_ids.append(job_id)
            successful += 1

            if verbose:
                print(
                    f"[{i}/{len(yaml_files)}] Submitted {os.path.basename(yaml_file)}: Job ID {job_id}"
                )
            else:
                # Print progress every 10 jobs
                if i % 10 == 0 or i == len(yaml_files):
                    print(f"Progress: {i}/{len(yaml_files)} submitted")

        except Exception as e:
            failed += 1
            print(
                f"[{i}/{len(yaml_files)}] Error submitting {os.path.basename(yaml_file)}: {e}"
            )
            continue

    # Save job IDs to file
    if job_ids:
        with open(output_file, "w") as f:
            f.write(str(job_ids) + "\n")
        print(f"\nSuccessfully submitted {successful} jobs")
        print(f"Failed to submit {failed} jobs")
        print(f"Job IDs saved to {output_file}")
    else:
        print("\nNo jobs were successfully submitted")
        sys.exit(1)

    return job_ids


def main():
    parser = argparse.ArgumentParser(
        description="Submit YAML files to LAVA server and save job IDs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Submit all YAML files with default settings
  python3 submit.py
  
  # Use custom XMLRPC URL and output file
  python3 submit.py --xmlrpc-url "http://admin:token@server:9999/RPC2/" --output jobs.txt
  
  # Verbose mode to see each submission
  python3 submit.py --verbose
        """,
    )

    parser.add_argument(
        "--xmlrpc-url",
        default="http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/",
        help="LAVA server XMLRPC URL (default: %(default)s)",
    )

    parser.add_argument(
        "--yaml-dir",
        default="generated_disk_yamls",
        help="Directory containing YAML files (default: %(default)s)",
    )

    parser.add_argument(
        "--output",
        "-o",
        default="jobs.txt",
        help="Output file to save job IDs (default: %(default)s)",
    )

    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Print verbose output for each submission",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List files that would be submitted without actually submitting",
    )

    args = parser.parse_args()

    # Check if YAML directory exists
    if not os.path.isdir(args.yaml_dir):
        print(f"Error: Directory {args.yaml_dir} does not exist")
        sys.exit(1)

    # Dry run mode
    if args.dry_run:
        yaml_pattern = os.path.join(args.yaml_dir, "*.yaml")
        yaml_files = sorted(glob.glob(yaml_pattern))
        print(f"Found {len(yaml_files)} YAML files:")
        for yaml_file in yaml_files:
            print(f"  - {os.path.basename(yaml_file)}")
        print(f"\nWould save job IDs to: {args.output}")
        return

    # Submit jobs
    job_ids = submit_yaml_files(
        args.xmlrpc_url, args.yaml_dir, args.output, args.verbose
    )

    print(f"\nTotal jobs submitted: {len(job_ids)}")
    if job_ids:
        print(f"First job ID: {job_ids[0]}")
        print(f"Last job ID: {job_ids[-1]}")


if __name__ == "__main__":
    main()
