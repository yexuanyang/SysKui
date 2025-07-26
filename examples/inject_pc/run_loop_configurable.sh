#!/bin/bash

# 可配置的循环运行脚本
# 使用方法: ./run_loop_configurable.sh [start_register] [end_register] [start_port] [port_increment]
# 例如: ./run_loop_configurable.sh 10 30 3800 100

# 默认参数
START_REGISTER=${1:-10}
END_REGISTER=${2:-30}
START_PORT=${3:-3800}
PORT_INCREMENT=${4:-100}

echo "配置参数："
echo "  Register 范围: x${START_REGISTER} 到 x${END_REGISTER}"
echo "  起始端口: ${START_PORT}"
echo "  端口递增: ${PORT_INCREMENT}"
echo "  预计运行任务数: $(((END_REGISTER - START_REGISTER + 1) * 2))"
echo ""

# 询问是否继续
read -p "是否继续执行？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消执行"
    exit 1
fi

# 初始端口号
port=$START_PORT
success_count=0
fail_count=0

# 循环从指定范围
for i in $(seq $START_REGISTER $END_REGISTER); do
    register="x${i}"
    
    # 检查对应的文件是否存在
    for suffix in 1 2; do
        job_file="${register}-${suffix}.txt"
        
        if [ ! -f "$job_file" ]; then
            echo "⚠️  警告: 文件 ${job_file} 不存在，跳过"
            port=$((port + PORT_INCREMENT))
            continue
        fi
        
        echo "[$((success_count + fail_count + 1))] 正在运行: --register ${register} -j ${job_file} -p ${port}"
        
        # 执行命令
        python3 generate_job.py --suffix ${suffix} --register ${register} -j ${job_file} -p ${port} --qemu-number 16 --xmlrpc-url http://admin:longrandomtokenadmin@127.0.0.1:9999/RPC2/
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "✓ 成功: ${register} ${job_file} 端口 ${port}"
            success_count=$((success_count + 1))
        else
            echo "✗ 失败: ${register} ${job_file} 端口 ${port}"
            fail_count=$((fail_count + 1))
        fi
        
        # 端口号递增
        port=$((port + PORT_INCREMENT))
        
        # 添加短暂延迟
        sleep 0.5
    done
done

echo ""
echo "===== 执行总结 ====="
echo "成功: ${success_count} 个任务"
echo "失败: ${fail_count} 个任务"
echo "总计: $((success_count + fail_count)) 个任务"
echo "端口范围: ${START_PORT} 到 $((port - PORT_INCREMENT))"
