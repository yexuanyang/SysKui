#!/bin/bash

# 可配置的循环读取内存注入结果脚本
# 使用方法: ./read_results_configurable.sh [start_address] [end_address] [container_id] [suffix_start] [suffix_end] [output_dir] [input_dir] [kernel] [--yes]
# 例如: ./read_results_configurable.sh 0x42650000 0x42b1ffff 31a6dc5f7fc6 1 4 /root/lava-qemu-flip/exp-results/results /root/lava-qemu-flip/exp-results/jobs linux
# 添加 --yes 或 -y 参数可跳过确认直接执行

# 检查是否有 --yes 或 -y 参数
AUTO_YES=false
for arg in "$@"; do
    if [[ "$arg" == "--yes" ]] || [[ "$arg" == "-y" ]]; then
        AUTO_YES=true
        break
    fi
done

# 默认参数
MEM_START=${1:-"0x40000000"}
MEM_END=${2:-"0x80000000"}
CONTAINER_ID=${3:-"31a6dc5f7fc6"}
SUFFIX_START=${4:-1}
SUFFIX_END=${5:-4}
OUTPUT_DIR=${6:-"/root/lava-qemu-flip/exp-results/results"}
INPUT_DIR=${7:-"/root/lava-qemu-flip/exp-results/jobs"}
KERNEL=${8:-"linux"}

echo "配置参数：" >&2
echo "  容器ID: ${CONTAINER_ID}" >&2
echo "  内存地址范围: ${MEM_START} 到 ${MEM_END}" >&2
echo "  输出目录: ${OUTPUT_DIR}" >&2
echo "  后缀范围: ${SUFFIX_START} 到 ${SUFFIX_END}" >&2
echo "  输入目录: ${INPUT_DIR}" >&2
echo "  内核: ${KERNEL}" >&2
echo "  预计处理任务数: $((SUFFIX_END - SUFFIX_START + 1))" >&2
echo "" >&2

# 询问是否继续（从 /dev/tty 读取以支持输出重定向场景）
if [[ "$AUTO_YES" == false ]]; then
    read -p "是否继续执行？(y/N): " -n 1 -r < /dev/tty
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消执行"
        exit 1
    fi
else
    echo "自动确认模式，跳过确认步骤" >&2
fi

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

success_count=0
fail_count=0
skip_count=0

# 记录开始时间
start_time=$(date +%s)

# 循环处理指定后缀范围的任务
for suffix in $(seq $SUFFIX_START $SUFFIX_END); do
    identifier="${KERNEL}-mem-${suffix}"
    input_file="${INPUT_DIR}/${identifier}.txt"
    output_file="${OUTPUT_DIR}/${identifier}.json"
    
    # 检查输入文件是否存在
    if [ ! -f "$input_file" ]; then
        echo "⚠️  跳过: 输入文件 ${input_file} 不存在"
        skip_count=$((skip_count + 1))
        continue
    fi
    
    # 检查输出文件是否已存在
    if [ -f "$output_file" ]; then
        echo "ℹ️  注意: 输出文件 ${output_file} 已存在，将被覆盖"
    fi
    
    task_num=$((success_count + fail_count + 1))
    echo "[$task_num] 处理: ${input_file}"
    echo "    输出到: ${output_file}"
    echo "    内存范围: ${MEM_START} - ${MEM_END}"
    
    # 执行命令
    python3 read_result.py \
        --kernel "$KERNEL" \
        --container "$CONTAINER_ID" \
        --output "$output_file" \
        --input "$input_file" \
        --suffix "$suffix" \
        --mem-start "$MEM_START" \
        --mem-end "$MEM_END"
    
    # 检查命令是否成功执行
    if [ $? -eq 0 ]; then
        success_count=$((success_count + 1))
        
        # 检查输出文件是否真的被创建并获取大小
        if [ -f "$output_file" ]; then
            file_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null || echo "0")
            echo "✓ 成功: 输出文件大小 ${file_size} 字节"
            
            # 显示统计信息
            if command -v jq &> /dev/null; then
                total_panic=$(jq -r '.total_panic // 0' "$output_file" 2>/dev/null)
                total_fault=$(jq -r '.total_fault // 0' "$output_file" 2>/dev/null)
                if [ -n "$total_panic" ] && [ -n "$total_fault" ] && [ "$total_fault" != "0" ]; then
                    panic_rate=$(awk "BEGIN {printf \"%.2f\", ($total_panic/$total_fault)*100}")
                    echo "  统计: Panic ${total_panic}/${total_fault} (${panic_rate}%)"
                fi
            fi
        else
            echo "✓ 命令执行成功，但输出文件未找到"
        fi
    else
        echo "✗ 失败: ${input_file}"
        fail_count=$((fail_count + 1))
    fi
    
    echo "----------------------------------------"
done

# 记录结束时间
end_time=$(date +%s)
duration=$((end_time - start_time))

# 输出总结
echo ""
echo "========================================"
echo "处理完成！"
echo "  成功: ${success_count}"
echo "  失败: ${fail_count}"
echo "  跳过: ${skip_count}"
echo "  总计: $((success_count + fail_count + skip_count))"
echo "  耗时: ${duration} 秒"
echo "========================================"
echo ""

if [ $fail_count -gt 0 ]; then
    echo "⚠️  有 ${fail_count} 个任务失败，请检查日志"
    exit 1
fi

exit 0
