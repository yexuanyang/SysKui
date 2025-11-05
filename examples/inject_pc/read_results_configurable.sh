#!/bin/bash

# 可配置的循环读取结果脚本
# 使用方法: ./read_results_configurable.sh [container_id] [start_register] [end_register] [output_dir] [suffix_start] [suffix_end] [input_dir] [--yes] [kernel]
# 例如: ./read_results_configurable.sh 31a6dc5f7fc6 3 30 /root/lava-qemu-flip/exp-results/results 2 20 /root/lava-qemu-flip/exp-results/jobs linux
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
CONTAINER_ID=${1:-"31a6dc5f7fc6"}
START_REGISTER=${2:-0}
END_REGISTER=${3:-30}
OUTPUT_DIR=${4:-"/root/lava-qemu-flip/exp-results/results"}
SUFFIX_START=${5:-2}
SUFFIX_END=${6:-4}
INPUT_DIR=${7:-"/root/lava-qemu-flip/exp-results/jobs"}
KERNEL=${8:-"linux"}

echo "配置参数：" >&2
echo "  容器ID: ${CONTAINER_ID}" >&2
echo "  Register 范围: x${START_REGISTER} 到 x${END_REGISTER}" >&2
echo "  输出目录: ${OUTPUT_DIR}" >&2
echo "  后缀开始处: ${SUFFIX_START}" >&2
echo "  后缀结束处: ${SUFFIX_END}" >&2
echo "  预计处理任务数: $(((END_REGISTER - START_REGISTER + 1) * (SUFFIX_END - SUFFIX_START + 1)))" >&2
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

# 循环从指定范围
for i in $(seq $START_REGISTER $END_REGISTER); do
    register="x${i}"
    
    # 对于每个register，处理多个文件：-1.txt, -2.txt, -3.txt ... -${suffix}.txt
    for suffix in $(seq $SUFFIX_START $SUFFIX_END); do
        identifier="${KERNEL}-${register}-${suffix}"
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
        
        # 执行命令
        python3 read_result.py --container "$CONTAINER_ID" -o "$output_file" -i "$input_file" --register "$register" --suffix "$suffix"
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            success_count=$((success_count + 1))
            
            # 检查输出文件是否真的被创建并获取大小
            if [ -f "$output_file" ]; then
                file_size=$(stat -c%s "$output_file" 2>/dev/null || echo "0")
                echo "✓ 成功: 输出文件大小 ${file_size} 字节"
            else
                echo "✓ 命令执行成功，但输出文件未找到"
            fi
        else
            echo "✗ 失败: ${input_file}"
            fail_count=$((fail_count + 1))
        fi
        
        # 显示进度
        total_expected=$((((END_REGISTER - START_REGISTER + 1) * (SUFFIX_END - SUFFIX_START + 1)) - skip_count))
        completed=$((success_count + fail_count))
        if [ $total_expected -gt 0 ]; then
            progress=$((completed * 100 / total_expected))
            echo "    进度: ${completed}/${total_expected} (${progress}%)"
        fi
        
        # 添加短暂延迟
        sleep 0.3
        echo ""
    done
done

# 计算执行时间
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "===== 执行总结 ====="
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "跳过: ${skip_count} 个任务 (文件不存在)"
echo "总计: $((success_count + fail_count)) 个处理任务"
echo "执行时间: ${duration} 秒"
echo "输出目录: ${OUTPUT_DIR}"

# 显示生成的输出文件统计
echo ""
echo "输出文件统计:"
if [ -d "$OUTPUT_DIR" ]; then
    json_files=$(find "$OUTPUT_DIR" -name "x*.json" -type f 2>/dev/null | wc -l)
    echo "找到 ${json_files} 个 .json 输出文件"
    
    if [ $json_files -gt 0 ]; then
        echo ""
        echo "最近生成的文件 (最多显示10个):"
        find "$OUTPUT_DIR" -name "x*.json" -type f -printf "%T@ %p\n" 2>/dev/null | \
        sort -nr | head -10 | while read timestamp file; do
            size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            basename_file=$(basename "$file")
            echo "  ${basename_file} (${size} 字节)"
        done
    fi
else
    echo "输出目录不存在"
fi
