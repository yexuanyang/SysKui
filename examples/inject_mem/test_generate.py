#!/usr/bin/env python3
"""
Test script to verify the generate_job.py functionality without submitting to LAVA
"""

import os
import sys

# Add current directory to path to import generate_job
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import random

from generate_job import gen_data


def test_gen_data():
    """Test the gen_data function"""
    # Set seed for reproducibility
    random.seed(42)

    # Test parameters
    mem_start = 0x40000000
    mem_end = 0x80000000
    number = 0
    port_start = 2000
    suffix = 1
    kernel = "linux"
    faults_per_job = 4

    # Generate data
    data = gen_data(
        mem_start, mem_end, number, port_start, suffix, kernel, faults_per_job
    )

    # Verify data structure
    print("Generated data structure:")
    print(f"  Number: {data['number']}")
    print(f"  GDB Socket: {data['gdb_socket']}")
    print(f"  QMP Socket: {data['qmp_socket']}")
    print(f"  SSH Port: {data['ssh_port']}")
    print(f"  Serial Socket: {data['serial_socket']}")
    print(f"  Logfile: {data['logfile']}")
    print(f"  Output: {data['output']}")
    print(f"  Error Output: {data['error_output']}")
    print(f"  Kernel: {data['kernel']}")
    print(f"  Memory Start: {data['mem_start']}")
    print(f"  Memory End: {data['mem_end']}")
    print(f"\nInjection Parameters ({len(data['injection_params'])} faults):")

    for i, (addr, bit_idx) in enumerate(data["injection_params"]):
        print(f"    Fault {i + 1}: Address={addr}, Bit Index={bit_idx}")

        # Verify address is in range
        addr_int = int(addr, 16)
        assert mem_start <= addr_int <= mem_end, f"Address {addr} out of range!"

        # Verify bit index is valid
        assert 0 <= bit_idx <= 63, f"Bit index {bit_idx} out of range!"

    print("\n✓ All tests passed!")
    return data


if __name__ == "__main__":
    test_gen_data()
