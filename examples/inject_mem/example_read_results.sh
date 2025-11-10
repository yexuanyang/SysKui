#!/bin/bash
# Example script for reading memory injection results

# Configuration
CONTAINER_ID="your_lava_slave_container_id"  # Replace with actual container ID
JOBS_FILE="jobs.txt"
OUTPUT_FILE="results.json"
SUFFIX=1
KERNEL="linux"
MEM_START="0x40000000"
MEM_END="0x80000000"

# Run the read_result script
python3 read_result.py \
    --container "$CONTAINER_ID" \
    --input "$JOBS_FILE" \
    --output "$OUTPUT_FILE" \
    --suffix "$SUFFIX" \
    --kernel "$KERNEL" \
    --mem-start "$MEM_START" \
    --mem-end "$MEM_END"

echo ""
echo "Results saved to: $OUTPUT_FILE"
echo ""
echo "To view the results:"
echo "  cat $OUTPUT_FILE | jq '.summary'"
echo "  cat $OUTPUT_FILE | jq '.\"12345\"'  # View specific job result"
