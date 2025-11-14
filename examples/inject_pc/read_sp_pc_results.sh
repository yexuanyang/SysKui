#!/bin/bash

# 为 sp 和/或 pc 寄存器批量读取测试结果
# 使用方法: ./read_sp_pc_results.sh [container_id] [registers] [output_dir] [suffix_start] [suffix_end] [input_dir] [kernel] [--yes]
# 例如: ./read_sp_pc_results.sh abc123 "sp,pc" /root/lava-qemu-flip/exp-results/results 1 3 /root/lava-qemu-flip/exp-results/jobs linux
# 例如: ./read_sp_pc_results.sh abc123 "sp" /root/lava-qemu-flip/exp-results/results 1 3 /root/lava-qemu-flip/exp-results/jobs linux
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
CONTAINER_ID=${1:-""}
REGISTERS_INPUT=${2:-"sp,pc"}
OUTPUT_DIR=${3:-"/root/lava-qemu-flip/exp-results/results"}
SUFFIX_START=${4:-1}
SUFFIX_END=${5:-3}
INPUT_DIR=${6:-"/root/lava-qemu-flip/exp-results/jobs"}
KERNEL=${7:-"linux"}

# 将逗号分隔的寄存器字符串转换为数组
IFS=',' read -ra REGISTERS <<< "$REGISTERS_INPUT"

# 如果没有提供容器ID，尝试自动获取
if [ -z "$CONTAINER_ID" ]; then
    echo "未提供容器ID，尝试自动获取..." >&2
    CONTAINER_ID=$(docker ps | grep lava-slave | awk '{print $1}')
    if [ -z "$CONTAINER_ID" ]; then
        echo "错误: 无法找到 lava-slave 容器" >&2
        echo "请手动指定容器ID: ./read_sp_pc_results.sh <container_id> ..." >&2
        exit 1
    fi
    echo "找到容器: ${CONTAINER_ID}" >&2
fi

echo "=========================================="
echo "批量读取故障注入测试结果"
echo "=========================================="
echo "配置参数："
echo "  容器ID: ${CONTAINER_ID}"
echo "  寄存器: ${REGISTERS[*]}"
echo "  输出目录: ${OUTPUT_DIR}"
echo "  输入目录: ${INPUT_DIR}"
echo "  后缀范围: ${SUFFIX_START} 到 ${SUFFIX_END}"
echo "  内核类型: ${KERNEL}"
echo "  预计处理任务数: $((${#REGISTERS[@]} * (SUFFIX_END - SUFFIX_START + 1)))"
echo ""

# 询问是否继续
if [[ "$AUTO_YES" == false ]]; then
    read -p "是否继续执行？(y/N): " -n 1 -r < /dev/tty
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消执行"
        exit 1
    fi
else
    echo "自动确认模式，跳过确认步骤"
fi

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

# 初始化计数器
success_count=0
fail_count=0
skip_count=0
total_count=0

# 记录开始时间
start_time=$(date +%s)

# 循环处理每个寄存器
for register in "${REGISTERS[@]}"; do
    echo ""
    echo "=========================================="
    echo "处理寄存器: ${register}"
    echo "=========================================="
    
    # 循环处理每个后缀
    for suffix in $(seq $SUFFIX_START $SUFFIX_END); do
        total_count=$((total_count + 1))
        identifier="${KERNEL}-${register}-${suffix}"
        input_file="${INPUT_DIR}/${identifier}.txt"
        output_file="${OUTPUT_DIR}/${identifier}.json"
        
        echo ""
        echo "[任务 ${total_count}] 处理:"
        echo "  寄存器: ${register}"
        echo "  后缀: ${suffix}"
        echo "  输入: ${input_file}"
        echo "  输出: ${output_file}"
        
        # 检查输入文件是否存在
        if [ ! -f "$input_file" ]; then
            echo "  ⚠️  跳过: 输入文件不存在"
            skip_count=$((skip_count + 1))
            continue
        fi
        
        # 检查输出文件是否已存在
        if [ -f "$output_file" ]; then
            echo "  ℹ️  输出文件已存在，将被覆盖"
        fi
        
        # 执行命令
        python3 read_result.py \
            --kernel "$KERNEL" \
            --container "$CONTAINER_ID" \
            -o "$output_file" \
            -i "$input_file" \
            --register "$register" \
            --suffix "$suffix"
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            success_count=$((success_count + 1))
            
            # 检查输出文件大小
            if [ -f "$output_file" ]; then
                file_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null || echo "0")
                echo "  ✓ 成功 (输出文件: ${file_size} 字节)"
                
                # 尝试提取关键信息
                if command -v jq &> /dev/null && [ -f "$output_file" ]; then
                    total_panic=$(jq -r '.total_panic // 0' "$output_file" 2>/dev/null)
                    total_fault=$(jq -r '.total_fault // 0' "$output_file" 2>/dev/null)
                    if [ -n "$total_panic" ] && [ -n "$total_fault" ]; then
                        echo "  📊 Panic/Fault: ${total_panic}/${total_fault}"
                    fi
                fi
            else
                echo "  ✓ 命令成功，但输出文件未找到"
            fi
        else
            echo "  ✗ 失败"
            fail_count=$((fail_count + 1))
        fi
        
        # 显示进度
        processed=$((success_count + fail_count))
        total_expected=$((${#REGISTERS[@]} * (SUFFIX_END - SUFFIX_START + 1)))
        if [ $total_expected -gt 0 ]; then
            progress=$((processed * 100 / total_expected))
            echo "  进度: ${processed}/${total_expected} (${progress}%)"
        fi
        
        # 添加短暂延迟
        sleep 0.3
    done
done

# 计算执行时间
end_time=$(date +%s)
duration=$((end_time - start_time))

# 打印执行总结
echo ""
echo "=========================================="
echo "执行总结"
echo "=========================================="
echo "处理的寄存器: ${REGISTERS[*]}"
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "跳过: ${skip_count} 个任务 (文件不存在)"
echo "总计: ${total_count} 个任务"
echo "执行时间: ${duration} 秒"
echo "输出目录: ${OUTPUT_DIR}"
echo ""

# 显示生成的输出文件统计
echo "输出文件统计:"
if [ -d "$OUTPUT_DIR" ]; then
    for reg in "${REGISTERS[@]}"; do
        json_files=$(find "$OUTPUT_DIR" -name "${KERNEL}-${reg}-*.json" -type f 2>/dev/null | wc -l)
        echo "  ${reg}: ${json_files} 个 JSON 文件"
    done
    
    total_json=$(find "$OUTPUT_DIR" -name "${KERNEL}-*.json" -type f 2>/dev/null | wc -l)
    echo "  总计: ${total_json} 个 JSON 文件"
    
    if [ $total_json -gt 0 ]; then
        echo ""
        echo "最近生成的文件 (最多显示10个):"
        find "$OUTPUT_DIR" -name "${KERNEL}-*.json" -type f -printf "%T@ %p\n" 2>/dev/null | \
        sort -nr | head -10 | while read timestamp file; do
            size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
            basename_file=$(basename "$file")
            echo "  ${basename_file} (${size} 字节)"
        done
    fi
else
    echo "输出目录不存在"
fi

echo ""
echo "查看结果示例:"
for reg in "${REGISTERS[@]}"; do
    example_file="${OUTPUT_DIR}/${KERNEL}-${reg}-${SUFFIX_START}.json"
    if [ -f "$example_file" ]; then
        echo "  cat ${example_file} | jq '.summary'"
    fi
done
echo "=========================================="
