import argparse
import random
import xmlrpc.client

from jinja2 import Environment, FileSystemLoader


def gen_data(
    mem_start: int,
    mem_end: int,
    number: int,
    port_start: int,
    suffix: int,
    kernel: str,
    faults_per_job: int,
    bytewidth: int,
):
    """
    Generate data for memory fault injection job
    :param: mem_start - start address of memory region to inject faults
    :param: mem_end - end address of memory region to inject faults
    :param: number - the index of qemu instance
    :param: port_start - starting port number for SSH
    :param: suffix - suffix for log files
    :param: kernel - kernel type to use
    :param: faults_per_job - number of faults to inject per job
    :return: the dict to render the config.yaml
    """
    identifier = f"{kernel}-{number}-mem-{suffix}"

    # Generate random memory addresses and bit indices for this job
    injection_params = []
    for _ in range(faults_per_job):
        # Random address within the specified range
        addr = random.randint(mem_start, mem_end)
        # Random bit index (0-7 for byte-level injection, 0-63 for 8-byte)
        bit_idx = random.randint(0, 7)
        injection_params.append((hex(addr), bit_idx))

    data = {
        "number": number,
        "gdb_socket": f"/tmp/gdb-server-{identifier}.sock",
        "injection_params": injection_params,
        "logfile": f"/tmp/log-{identifier}.csv",
        "output": f"/tmp/{identifier}.out",
        "error_output": f"/tmp/{identifier}.err",
        "qmp_socket": f"/tmp/qmp-{identifier}.sock",
        "ssh_port": f"{number + port_start}",
        "serial_socket": f"/tmp/qemu-serial-{identifier}.sock",
        "kernel": kernel,
        "mem_start": hex(mem_start),
        "mem_end": hex(mem_end),
        "bytewidth": bytewidth,
    }
    return data


if __name__ == "__main__":
    # Load template environment
    env = Environment(loader=FileSystemLoader(searchpath="."))
    template = env.get_template("config.yaml.j2")

    jobs = []
    parser = argparse.ArgumentParser(
        prog="generate_job",
        description="Generate LAVA jobs for memory fault injection",
    )
    parser.add_argument(
        "--mem-start",
        type=str,
        help="Start address of memory region (hex format, e.g., 0x40000000)",
        required=True,
    )
    parser.add_argument(
        "--mem-end",
        type=str,
        help="End address of memory region (hex format, e.g., 0x80000000)",
        required=True,
    )
    parser.add_argument(
        "--qemu-number",
        type=int,
        help="Number of QEMU instances to create",
        default=64,
        required=True,
    )
    parser.add_argument(
        "--faults-per-job",
        type=int,
        help="Number of random memory faults to inject per job",
        default=4,
    )
    parser.add_argument(
        "--xmlrpc-url",
        help="xmlrpc url, e.g., http://<user>:<token>@<ip>:<port>/RPC2/",
        default="http://admin:longrandomtokenadmin@10.161.28.20:9999/RPC2/",
        required=True,
    )
    parser.add_argument(
        "--job-output",
        "-j",
        help="job.txt output file path, store the jobs' id",
        default="jobs.txt",
        required=True,
    )
    parser.add_argument(
        "--port-start",
        "-p",
        help="ssh port start number, increase from there by one with each job's creation",
        default=2000,
        type=int,
        required=True,
    )
    parser.add_argument(
        "--suffix",
        help="log csv suffix",
        type=int,
        required=True,
    )
    parser.add_argument(
        "--kernel",
        help="kernel to use",
        type=str,
        choices=["linux", "openeuler", "phytium"],
        required=True,
    )
    parser.add_argument(
        "--seed",
        help="Random seed for reproducibility (optional)",
        type=int,
        default=None,
    )
    parser.add_argument(
        "--bytewidth",
        help="bytewidth of address",
        type=int,
        default=1,
    )

    args = parser.parse_args()

    # Parse memory addresses
    try:
        mem_start = int(args.mem_start, 16)
        mem_end = int(args.mem_end, 16)
        if mem_start > mem_end:
            raise ValueError("mem_start must be less than mem_end")
    except ValueError as e:
        print(f"Error parsing memory addresses: {e}")
        exit(1)

    # Set random seed if provided
    if args.seed is not None:
        random.seed(args.seed)
        print(f"Using random seed: {args.seed}")

    for number in range(0, args.qemu_number):
        # Render template
        rendered_yaml = template.render(
            gen_data(
                mem_start,
                mem_end,
                number,
                args.port_start,
                args.suffix,
                args.kernel,
                args.faults_per_job,
                args.bytewidth,
            )
        )
        # Submit job
        server = xmlrpc.client.ServerProxy(args.xmlrpc_url)
        jobid = server.scheduler.submit_job(rendered_yaml)
        print(jobid)
        jobs.append(jobid)
    with open(args.job_output, "w") as f:
        f.write(str(jobs) + "\n")
