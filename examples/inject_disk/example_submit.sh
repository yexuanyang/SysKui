#!/bin/bash
# Example workflow for submitting disk injection jobs to LAVA

set -e  # Exit on error

echo "=== Disk Injection Job Submission Workflow ==="
echo ""

# Step 1: Dry run to check what will be submitted
echo "Step 1: Dry run to verify files..."
python3 submit.py --dry-run | head -30
echo ""
read -p "Continue with submission? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Submission cancelled."
    exit 0
fi

# Step 2: Submit jobs
echo ""
echo "Step 2: Submitting jobs to LAVA server..."
python3 submit.py \
    --xmlrpc-url "http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/" \
    --yaml-dir generated_disk_yamls \
    --output jobs.txt

# Step 3: Verify the output
echo ""
echo "Step 3: Verifying jobs.txt..."
python3 test_jobs.py jobs.txt

echo ""
echo "=== Submission Complete ==="
echo "Job IDs have been saved to jobs.txt"
echo ""
echo "Next steps:"
echo "  1. Monitor jobs on LAVA web interface"
echo "  2. Wait for jobs to complete"
echo "  3. Collect and analyze results"
