#!/bin/bash
# Example script to generate memory fault injection jobs
# This is a demonstration - modify parameters according to your setup

# Configuration
MEM_START="0x40000000"    # Start of memory region to inject faults
MEM_END="0x80000000"      # End of memory region to inject faults
QEMU_NUMBER=16            # Number of QEMU instances
FAULTS_PER_JOB=4          # Number of random faults per job
XMLRPC_URL="http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/"
JOB_OUTPUT="jobs.txt"
PORT_START=2000
SUFFIX=1
KERNEL="linux"
SEED=42                   # Optional: for reproducible results

python3 generate_job.py \
    --mem-start "$MEM_START" \
    --mem-end "$MEM_END" \
    --qemu-number "$QEMU_NUMBER" \
    --faults-per-job "$FAULTS_PER_JOB" \
    --xmlrpc-url "$XMLRPC_URL" \
    --job-output "$JOB_OUTPUT" \
    --port-start "$PORT_START" \
    --suffix "$SUFFIX" \
    --kernel "$KERNEL" \
    --seed "$SEED"

echo "Jobs generated and submitted. Job IDs saved to $JOB_OUTPUT"
