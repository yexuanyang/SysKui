import os
import random

# --- 1. 参数配置 ---

# 要生成的YAML文件总数
TOTAL_FILES = 640

# SSH端口起始号
BASE_SSH_PORT = 40000

# 注入的偏移范围 (0MB 到 600MB)
MAX_OFFSET_MB = 600

# 注入的数据大小 (1MB)
INJECT_SIZE_MB = 1

# 输出目录
OUTPUT_DIR = "generated_disk_yamls"

# --- 2. 常量计算 ---
BYTES_PER_MB = 1024 * 1024
# 随机偏移量的最大值 (字节)
MAX_OFFSET_BYTES = MAX_OFFSET_MB * BYTES_PER_MB
# 注入的数据块大小 (字节)
INJECT_SIZE_BYTES = INJECT_SIZE_MB * BYTES_PER_MB

# --- 3. LAVA YAML 模板 ---
# 我们使用占位符来替换需要修改的部分:
# __SUFFIX__ : 文件的唯一后缀 (例如: 0, 1, 2...)
# __SSH_PORT__ : 唯一的SSH端口
# __INJECT_OFFSET__ : 随机的字节偏移量
# __INJECT_SIZE__ : 注入的字节大小 (1MB)

yaml_template = """
actions:
- deploy:
    images:
      kernel:
        image_arg: -kernel {kernel}
        url: file:///root/lava-qemu-flip/kernels/linux-6.6
      rootfs:
        image_arg: -drive file={rootfs},format=qcow2,index=0,media=disk
        url: file:///root/lava-qemu-flip/ubuntu-mini.qcow2
    timeout:
      minutes: 5
    to: tmpfs
- boot:
    auto_login:
      login_prompt: 'rros login:'
      password: root
      password_prompt: 'Password:'
      username: root
    fault_inject_params:
      commands:
      # 读取注入点前的 64 字节数据作为参考
      - sshcommand dd if=/dev/vda bs=1 count=64 skip=__INJECT_OFFSET__ | xxd
      # 从 __INJECT_OFFSET__ 字节处开始，写入 __INJECT_SIZE__ 字节的 0
      - sshcommand dd of=/dev/vda if=/dev/zero bs=1 count=__INJECT_SIZE__ seek=__INJECT_OFFSET__ conv=notrunc
      inject_after_boot: true
      qmp_socket: /tmp/qmp-disk_program___SUFFIX__.sock
      serial_socket: /tmp/qemu-serial-disk_program___SUFFIX__.sock
      ssh_host: localhost
      ssh_port: __SSH_PORT__
      stderr: /tmp/inject_disk_program___SUFFIX__.err
      stdout: /tmp/inject_disk_program___SUFFIX__.out
    media: tmpfs
    method: qemu
    prompts:
    - 'root@rros:'
    timeout:
      minutes: 5
- test:
    definitions:
    - from: inline
      name: apache-server
      path: inline/apache-server.yaml
      repository:
        metadata:
          description: server installation
          format: Lava-Test Test Definition 1.0
          name: apache-server
          os:
          - debian
          scope:
          - functional
        run:
          steps:
          - sleep 10
    timeout:
      minutes: 5
context:
  arch: aarch64
  cpu: cortex-a57
  extra_options:
  - -smp 1
  - -append "console=ttyAMA0 root=/dev/vda1 rw"
  - -qmp unix:/tmp/qmp-disk_program___SUFFIX__.sock,server=on,wait=off
  - -device pvpanic-pci
  - -action shutdown=pause,panic=none
  - -chardev socket,path=/tmp/gdb-server-__SUFFIX__.sock,server=on,wait=off,id=gdb0
  - -gdb chardev:gdb0
  guestfs_interface: virtio
  machine: virt
  memory: 4G
  netdevice: user,hostfwd=::__SSH_PORT__-:22
device_type: qemu
job_name: "故障注入磁盘-__SUFFIX__"
priority: medium
timeouts:
  action:
    minutes: 10
  connection:
    minutes: 2
  job:
    minutes: 15
visibility: public
"""

# --- 4. 生成脚本主逻辑 ---


def main():
    # 1. 创建输出目录
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"创建目录: {OUTPUT_DIR}")

    print(f"开始生成 {TOTAL_FILES} 个YAML文件...")

    for i in range(TOTAL_FILES):
        # 2. 计算当前文件的参数
        suffix = str(i)
        ssh_port = BASE_SSH_PORT + i

        # 从 0 到 600MB (包含) 之间随机选择一个字节偏移量
        # random.randint(a, b) 包含 a 和 b
        injection_offset = random.randint(0, MAX_OFFSET_BYTES)

        # 3. 替换模板中的占位符
        content = yaml_template
        content = content.replace("__SUFFIX__", suffix)
        content = content.replace("__SSH_PORT__", str(ssh_port))
        content = content.replace("__INJECT_OFFSET__", str(injection_offset))
        content = content.replace("__INJECT_SIZE__", str(INJECT_SIZE_BYTES))

        # 4. 写入文件
        file_name = f"disk_inject_{i}.yaml"
        file_path = os.path.join(OUTPUT_DIR, file_name)

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

    print("---")
    print(f"成功！ {TOTAL_FILES} 个文件已生成在 '{OUTPUT_DIR}' 目录中。")
    print(f"SSH端口范围: {BASE_SSH_PORT} - {BASE_SSH_PORT + TOTAL_FILES - 1}")
    print(f"注入偏移范围: 0 - {MAX_OFFSET_BYTES} 字节 (0 - {MAX_OFFSET_MB}MB)")
    print(f"注入大小: {INJECT_SIZE_BYTES} 字节 ({INJECT_SIZE_MB}MB)")


if __name__ == "__main__":
    main()
