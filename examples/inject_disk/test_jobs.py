#!/usr/bin/env python3
"""
Test script to verify jobs.txt can be read correctly
"""


def test_jobs_file(filename="jobs.txt"):
    """Test reading and parsing jobs.txt file"""
    try:
        with open(filename, "r") as f:
            content = f.read().strip()

        # Parse the job IDs
        job_ids = eval(content)

        # Verify it's a list
        assert isinstance(job_ids, list), "Job IDs should be a list"

        # Print info
        print(f"✓ Successfully read {filename}")
        print(f"✓ Total jobs: {len(job_ids)}")

        if job_ids:
            print(f"✓ First job ID: {job_ids[0]}")
            print(f"✓ Last job ID: {job_ids[-1]}")

            # Verify all are integers
            all_ints = all(isinstance(jid, int) for jid in job_ids)
            if all_ints:
                print("✓ All job IDs are integers")
            else:
                print("⚠ Warning: Not all job IDs are integers")

            # Sample of job IDs
            sample_size = min(10, len(job_ids))
            print(f"\nSample job IDs (first {sample_size}):")
            for i, jid in enumerate(job_ids[:sample_size]):
                print(f"  {i + 1}. {jid}")

        return job_ids

    except FileNotFoundError:
        print(f"✗ Error: {filename} not found")
        print("  Run submit.py first to generate the file")
        return None
    except Exception as e:
        print(f"✗ Error reading {filename}: {e}")
        return None


if __name__ == "__main__":
    import sys

    filename = sys.argv[1] if len(sys.argv) > 1 else "jobs.txt"
    test_jobs_file(filename)
