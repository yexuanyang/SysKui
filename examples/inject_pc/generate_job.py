import argparse
import xmlrpc.client

from jinja2 import Environment, FileSystemLoader


def gen_data(register: str, number: int, port_start: int, suffix: int, kernel: str):
    """
    :param: register - the register to inject faults
    :param: number - the index of qemu instance
    :return: the dict to render the config.yaml
    """
    identifier = f"{kernel}-{number}-{register}-{suffix}"
    data = {
        "number": number,
        "gdb_socket": f"/tmp/gdb-server-{identifier}.sock",
        "pairs": [
            (register, number * 4),
            (register, number * 4 + 1),
            (register, number * 4 + 2),
            (register, number * 4 + 3),
        ],
        "logfile": f"/tmp/log-{identifier}.csv",
        "output": f"/tmp/{identifier}.out",
        "error_output": f"/tmp/{identifier}.err",
        "qmp_socket": f"/tmp/qmp-{identifier}.sock",
        "ssh_port": f"{number + port_start}",
        "serial_socket": f"/tmp/qemu-serial-{identifier}.sock",
        "kernel": kernel,
    }
    return data


if __name__ == "__main__":
    # Load template environment
    env = Environment(loader=FileSystemLoader(searchpath="."))
    template = env.get_template("config.yaml.j2")

    jobs = []
    parser = argparse.ArgumentParser(prog="generate_job")
    parser.add_argument(
        "--register", type=str, help="The register inject faults to", required=True
    )
    parser.add_argument(
        "--qemu-number",
        type=int,
        help="QEMU device number",
        default=64,
        required=True,
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

    args = parser.parse_args()

    for number in range(0, args.qemu_number):
        # Render template
        rendered_yaml = template.render(
            gen_data(args.register, number, args.port_start, args.suffix, args.kernel)
        )
        # Submit job
        server = xmlrpc.client.ServerProxy(args.xmlrpc_url)
        jobid = server.scheduler.submit_job(rendered_yaml)
        print(jobid)
        jobs.append(jobid)
    with open(args.job_output, "w") as f:
        f.write(str(jobs) + "\n")
