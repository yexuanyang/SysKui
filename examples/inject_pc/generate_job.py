import argparse
import xmlrpc.client

from jinja2 import Environment, FileSystemLoader


def gen_data(register: str, number: int):
    """
    :param: register - the register to inject faults
    :param: number - the index of qemu instance
    :return: the dict to render the config.yaml
    """
    data = {
        "number": number,
        "gdb_socket": f"/tmp/gdb-server-{number}.sock",
        "pairs": [
            (register, number * 4),
            (register, number * 4 + 1),
            (register, number * 4 + 2),
            (register, number * 4 + 3),
        ],
        "logfile": f"/tmp/log-{number}.csv",
        "output": f"/tmp/{number}.out",
        "error_output": f"/tmp/{number}.err",
        "qmp_socket": f"/tmp/qmp-{number}.sock",
        "ssh_port": f"{number + 2000}",
        "serial_socket": f"/tmp/qemu-serial-{number}.sock",
    }
    return data


if __name__ == "__main__":
    # Load template environment
    env = Environment(loader=FileSystemLoader(searchpath="."))
    template = env.get_template("config.yaml.j2")

    jobs = []
    parser = argparse.ArgumentParser(prog="generate_job")
    parser.add_argument(
        "--register",
        type=str,
        help="The register inject faults to",
        required=True
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

    args = parser.parse_args()

    for number in range(0, args.qemu_number):
        # Render template
        rendered_yaml = template.render(gen_data(args.register, number))
        # Submit job
        server = xmlrpc.client.ServerProxy(args.xmlrpc_url)
        jobid = server.scheduler.submit_job(rendered_yaml)
        print(jobid)
        jobs.append(jobid)
    with open("jobs.txt", "w") as f:
        f.write(str(jobs) + "\n")
