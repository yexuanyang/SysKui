#!/usr/bin/env python3
"""
Mock test to demonstrate the jobs.txt format without actually submitting to LAVA
This creates a sample jobs.txt with fake job IDs
"""


def create_mock_jobs_file(num_jobs=640, output_file="jobs_mock.txt", start_id=10000):
    """Create a mock jobs.txt file with fake job IDs"""

    # Generate mock job IDs
    job_ids = list(range(start_id, start_id + num_jobs))

    # Save to file in the same format as submit.py
    with open(output_file, "w") as f:
        f.write(str(job_ids) + "\n")

    print(f"Created mock jobs file: {output_file}")
    print(f"  Total jobs: {len(job_ids)}")
    print(f"  First job ID: {job_ids[0]}")
    print(f"  Last job ID: {job_ids[-1]}")
    print("\nFile format (first 100 chars):")

    with open(output_file, "r") as f:
        content = f.read()
        print(f"  {content[:100]}...")

    return job_ids


def test_mock_file(filename="jobs_mock.txt"):
    """Test reading the mock file"""
    print(f"\nTesting {filename}...")

    with open(filename, "r") as f:
        content = f.read().strip()

    job_ids = eval(content)

    print(f"✓ Successfully parsed {len(job_ids)} job IDs")
    print(
        f"✓ Format verification: {type(job_ids).__name__} containing {type(job_ids[0]).__name__}s"
    )

    return job_ids


if __name__ == "__main__":
    # Create mock file
    job_ids = create_mock_jobs_file(num_jobs=640, output_file="jobs_mock.txt")

    # Test reading it
    test_mock_file("jobs_mock.txt")

    print("\n" + "=" * 60)
    print("This demonstrates the format that submit.py will create.")
    print("Run 'python3 test_jobs.py jobs_mock.txt' to verify.")
    print("=" * 60)
