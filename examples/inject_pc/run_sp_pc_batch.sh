#!/bin/bash

# 为 sp 和/或 pc 寄存器批量创建故障注入任务
# 使用方法: ./run_sp_pc_batch.sh [registers] [start_port] [port_increment] [suffix_start] [suffix_end] [output_dir] [kernel]
# 例如: ./run_sp_pc_batch.sh "sp,pc" 5000 100 1 3 /root/lava-qemu-flip/exp-results/jobs linux
# 例如: ./run_sp_pc_batch.sh "sp" 5000 100 1 3 /root/lava-qemu-flip/exp-results/jobs linux
# 例如: ./run_sp_pc_batch.sh "pc" 5000 100 1 3 /root/lava-qemu-flip/exp-results/jobs linux
# ./run_sp_pc_batch.sh "SCTLR_EL1,TTBR0_EL1,TTBR1_EL1,TCR_EL1" 2000 16 1 4 /root/lava-qemu-flip/exp-results/jobs linux

# 默认参数
REGISTERS_INPUT=${1:-"sp,pc"}
START_PORT=${2:-5000}
PORT_INCREMENT=${3:-100}
SUFFIX_START=${4:-1}
SUFFIX_END=${5:-3}
OUTPUT_DIR=${6:-"/root/lava-qemu-flip/exp-results/jobs"}
KERNEL=${7:-"linux"}
XMLRPC_URL=${8:-"http://admin:longrandomtokenadmin@127.0.0.1:9999/RPC2/"}
QEMU_NUMBER=${9:-16}

# 将逗号分隔的寄存器字符串转换为数组
IFS=',' read -ra REGISTERS <<< "$REGISTERS_INPUT"

echo "=========================================="
echo "批量创建故障注入任务"
echo "=========================================="
echo "配置参数："
echo "  寄存器: ${REGISTERS[*]}"
echo "  起始端口: ${START_PORT}"
echo "  端口递增: ${PORT_INCREMENT}"
echo "  后缀范围: ${SUFFIX_START} 到 ${SUFFIX_END}"
echo "  输出目录: ${OUTPUT_DIR}"
echo "  内核类型: ${KERNEL}"
echo "  QEMU 实例数: ${QEMU_NUMBER}"
echo "  XMLRPC URL: ${XMLRPC_URL}"
echo "  预计任务数: $((${#REGISTERS[@]} * (SUFFIX_END - SUFFIX_START + 1)))"
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

# 初始化计数器
port=$START_PORT
success_count=0
fail_count=0
total_count=0

# 循环处理每个寄存器
for register in "${REGISTERS[@]}"; do
    echo ""
    echo "=========================================="
    echo "处理寄存器: ${register}"
    echo "=========================================="
    
    # 循环处理每个后缀
    for suffix in $(seq $SUFFIX_START $SUFFIX_END); do
        total_count=$((total_count + 1))
        job_file="${OUTPUT_DIR}/${KERNEL}-${register}-${suffix}.txt"
        
        echo ""
        echo "[任务 ${total_count}] 正在创建任务:"
        echo "  寄存器: ${register}"
        echo "  后缀: ${suffix}"
        echo "  端口: ${port}"
        echo "  输出文件: ${job_file}"
        
        # 执行命令
        python3 generate_job.py \
            --kernel ${KERNEL} \
            --suffix ${suffix} \
            --register ${register} \
            -j ${job_file} \
            -p ${port} \
            --qemu-number ${QEMU_NUMBER} \
            --xmlrpc-url ${XMLRPC_URL}
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "  ✓ 成功创建"
            success_count=$((success_count + 1))
            
            # 显示生成的任务 ID（如果文件存在）
            if [ -f "${job_file}" ]; then
                job_count=$(cat "${job_file}" | grep -o "," | wc -l)
                job_count=$((job_count + 1))
                echo "  ✓ 已提交 ${job_count} 个 job"
            fi
        else
            echo "  ✗ 创建失败"
            fail_count=$((fail_count + 1))
        fi
        
        # 端口号递增
        port=$((port + PORT_INCREMENT))
        
        # 添加短暂延迟，避免服务器压力过大
        sleep 0.5
    done
done

# 打印执行总结
echo ""
echo "=========================================="
echo "执行总结"
echo "=========================================="
echo "处理的寄存器: ${REGISTERS[*]}"
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "总计: ${total_count} 个任务"
echo "端口范围: ${START_PORT} 到 $((port - PORT_INCREMENT))"
echo "输出目录: ${OUTPUT_DIR}"
echo ""
echo "查看生成的文件:"
for reg in "${REGISTERS[@]}"; do
    echo "  ls -lh ${OUTPUT_DIR}/${KERNEL}-${reg}-*.txt"
done
echo ""
echo "查看任务 ID 示例:"
for reg in "${REGISTERS[@]}"; do
    echo "  cat ${OUTPUT_DIR}/${KERNEL}-${reg}-${SUFFIX_START}.txt"
done
echo "=========================================="
