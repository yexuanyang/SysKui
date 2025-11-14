#!/bin/bash

# 可配置的循环运行脚本 - 内存故障注入版本
# 使用方法: ./run_loop_configurable.sh [mem_start] [mem_end] [start_port] [port_increment] [suffix_start] [suffix_end] [output_dir] [kernel] [qemu_number] [faults_per_job]
# 例如: ./run_loop_configurable.sh 0x40000000 0x80000000 3800 100 1 10 /root/lava-qemu-flip/exp-results/jobs linux 16 4
# ./run_loop_configurable.sh 0x40000000 0x13fffffff 22000 64 1 10 /root/lava-qemu-flip/exp-results/jobs linux 64 1
# Kernel code
# ./run_loop_configurable.sh 0x40210000 0x41d4ffff 22000 64 11 20 /root/lava-qemu-flip/exp-results/jobs linux 64 1
# Kernel data
# ./run_loop_configurable.sh 0x42650000 0x42b1ffff 22000 64 21 30 /root/lava-qemu-flip/exp-results/jobs linux 64 1
# 

# 默认参数
MEM_START=${1:-"0x40000000"}
MEM_END=${2:-"0x80000000"}
START_PORT=${3:-3800}
PORT_INCREMENT=${4:-100}
SUFFIX_START=${5:-1}
SUFFIX_END=${6:-10}
OUTPUT_DIR=${7:-"/root/lava-qemu-flip/exp-results/jobs"}
KERNEL=${8:-"linux"}
QEMU_NUMBER=${9:-16}
FAULTS_PER_JOB=${10:-4}

echo "配置参数："
echo "  内存范围: ${MEM_START} 到 ${MEM_END}"
echo "  起始端口: ${START_PORT}"
echo "  端口递增: ${PORT_INCREMENT}"
echo "  后缀开始处(包含): ${SUFFIX_START}"
echo "  后缀结束处(包含): ${SUFFIX_END}"
echo "  内核类型: ${KERNEL}"
echo "  每个任务的QEMU实例数: ${QEMU_NUMBER}"
echo "  每个任务注入的故障数: ${FAULTS_PER_JOB}"
echo "  预计运行任务数: $((SUFFIX_END - SUFFIX_START + 1))"
echo "  输出目录: ${OUTPUT_DIR}"
echo ""

# 询问是否继续
read -p "是否继续执行？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消执行"
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p "${OUTPUT_DIR}"

# 初始端口号
port=$START_PORT
success_count=0
fail_count=0

# 循环从指定后缀范围
for suffix in $(seq $SUFFIX_START $SUFFIX_END); do
    job_file="${OUTPUT_DIR}/${KERNEL}-mem-${suffix}.txt"
    
    echo "[$((success_count + fail_count + 1))] 正在运行: --kernel ${KERNEL} --suffix ${suffix} --mem-start ${MEM_START} --mem-end ${MEM_END} -j ${job_file} -p ${port} --qemu-number ${QEMU_NUMBER} --faults-per-job ${FAULTS_PER_JOB}"
    
    # 执行命令
    python3 generate_job.py \
        --kernel ${KERNEL} \
        --suffix ${suffix} \
        --mem-start ${MEM_START} \
        --mem-end ${MEM_END} \
        -j ${job_file} \
        -p ${port} \
        --qemu-number ${QEMU_NUMBER} \
        --faults-per-job ${FAULTS_PER_JOB} \
        --xmlrpc-url http://admin:longrandomtokenadmin@127.0.0.1:9999/RPC2/
    
    # 检查命令是否成功执行
    if [ $? -eq 0 ]; then
        echo "✓ 成功: ${job_file} 端口范围 ${port}-$((port + QEMU_NUMBER - 1))"
        success_count=$((success_count + 1))
    else
        echo "✗ 失败: ${job_file} 端口 ${port}"
        fail_count=$((fail_count + 1))
    fi
    
    # 端口号递增
    port=$((port + PORT_INCREMENT))
    
    # 添加短暂延迟
    sleep 0.5
done

echo ""
echo "===== 执行总结 ====="
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "总计: $((success_count + fail_count)) 个任务"
echo "端口范围: ${START_PORT} 到 $((port - PORT_INCREMENT + QEMU_NUMBER - 1))"
echo "生成的任务文件位于: ${OUTPUT_DIR}/"
