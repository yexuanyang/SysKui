#!/bin/bash

# 循环运行 read_result.py 的脚本
# 参数说明：
# -i: x[3-30]-(1|2).txt 来回选择
# -o: /root/lava-qemu-flip/exp-results/x[3-30]-(1|2).json 对应的输出文件

# 固定的容器ID和输出目录
CONTAINER_ID="31a6dc5f7fc6"
OUTPUT_DIR="/root/lava-qemu-flip/exp-results"

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

echo "开始循环执行 read_result.py"
echo "容器ID: $CONTAINER_ID"
echo "输出目录: $OUTPUT_DIR"
echo "处理范围: x3 到 x30，每个寄存器处理 -1.txt 和 -2.txt"
echo ""

success_count=0
fail_count=0

# 循环从 x3 到 x30
for i in {3..30}; do
    register="x${i}"
    
    # 对于每个register，处理两个文件：-1.txt 和 -2.txt
    for suffix in 1 2; do
        input_file="${register}-${suffix}.txt"
        output_file="${OUTPUT_DIR}/${register}-${suffix}.json"
        
        # 检查输入文件是否存在
        if [ ! -f "$input_file" ]; then
            echo "⚠️  警告: 输入文件 ${input_file} 不存在，跳过"
            continue
        fi
        
        echo "[$((success_count + fail_count + 1))] 处理: ${input_file} -> ${output_file}"
        
        # 执行命令
        python3 read_result.py --container "$CONTAINER_ID" -o "$output_file" -i "$input_file" --register "$register"
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "✓ 成功: ${input_file} -> ${output_file}"
            success_count=$((success_count + 1))
            
            # 检查输出文件是否真的被创建
            if [ -f "$output_file" ]; then
                file_size=$(stat -c%s "$output_file" 2>/dev/null || echo "0")
                echo "  输出文件大小: ${file_size} 字节"
            else
                echo "  ⚠️  输出文件未找到"
            fi
        else
            echo "✗ 失败: ${input_file}"
            fail_count=$((fail_count + 1))
        fi
        
        # 添加短暂延迟
        sleep 0.5
        echo ""
    done
done

echo "===== 执行总结 ====="
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "总计: $((success_count + fail_count)) 个任务"
echo "输出目录: ${OUTPUT_DIR}"

# 显示生成的输出文件
echo ""
echo "生成的输出文件:"
if [ -d "$OUTPUT_DIR" ]; then
    ls -la "$OUTPUT_DIR"/*.json 2>/dev/null || echo "没有找到 .json 文件"
else
    echo "输出目录不存在"
fi
