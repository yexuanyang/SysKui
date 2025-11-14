#!/bin/bash
# Example: Read disk injection results

# Get container ID
CONTAINER_ID=$(docker ps | grep local-lab-slave-0 | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: lava-slave container not found"
    echo "Run: docker ps | grep lava-slave"
    exit 1
fi

echo "Using container: $CONTAINER_ID"
echo ""

# Read results
python3 read_result.py \
    --container "$CONTAINER_ID" \
    --input jobs.txt \
    --output results.json \
    --yaml-dir generated_disk_yamls

echo ""
echo "View summary:"
echo "  cat results.json | jq '.summary'"
echo ""
echo "View specific job:"
echo "  cat results.json | jq '.\"12345\"'"
