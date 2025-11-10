#!/usr/bin/env python3
"""
Test the YAML template rendering
"""

import os
import random
import sys

from jinja2 import Environment, FileSystemLoader

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from generate_job import gen_data


def test_template_rendering():
    """Test that the config.yaml.j2 template can be rendered"""
    # Set seed for reproducibility
    random.seed(42)

    # Test parameters
    mem_start = 0x40000000
    mem_end = 0x80000000
    number = 0
    port_start = 2000
    suffix = 1
    kernel = "linux"
    faults_per_job = 2  # Use fewer for readability

    # Generate data
    data = gen_data(
        mem_start, mem_end, number, port_start, suffix, kernel, faults_per_job
    )

    # Load and render template
    env = Environment(loader=FileSystemLoader(searchpath="."))
    template = env.get_template("config.yaml.j2")
    rendered_yaml = template.render(data)

    print("=" * 80)
    print("Rendered YAML Configuration:")
    print("=" * 80)
    print(rendered_yaml)
    print("=" * 80)

    # Basic validation
    assert "snapinject" in rendered_yaml, (
        "snapinject command not found in rendered YAML"
    )
    assert "--fault-type ram" in rendered_yaml, "RAM fault type not specified"
    assert data["mem_start"] in rendered_yaml, "Memory start address not in YAML"
    assert str(data["ssh_port"]) in rendered_yaml, "SSH port not in YAML"

    print("\n✓ Template rendering successful!")
    print(f"✓ {len(data['injection_params'])} fault injection commands generated")


if __name__ == "__main__":
    test_template_rendering()
