#!/bin/bash

# 循环运行 generate_job.py 的脚本
# 参数说明：
# --register: 从 x11 到 x30
# -j: <register>-(1|2).txt 来回变动
# -p: 端口号，每次加100，从3800开始

# 初始端口号
port=3800

# 循环从 x11 到 x30
for i in {11..30}; do
    register="x${i}"
    
    # 对于每个register，运行两次：一次用-1.txt，一次用-2.txt
    for suffix in 1 2; do
        job_file="${register}-${suffix}.txt"
        
        echo "正在运行: --register ${register} -j ${job_file} -p ${port}"
        
        # 执行命令
        python3 generate_job.py --register ${register} -j ${job_file} -p ${port} --qemu-number 16 --xmlrpc-url http://admin:longrandomtokenadmin@127.0.0.1:9999/RPC2/
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ]; then
            echo "✓ 成功执行: ${register} ${job_file} 端口 ${port}"
        else
            echo "✗ 执行失败: ${register} ${job_file} 端口 ${port}"
        fi
        
        # 端口号增加100
        port=$((port + 100))
        
        # 可选：添加延迟，避免过快执行
        sleep 1
    done
done

echo "所有任务完成！"
echo "总共运行了 $((21 * 2)) 个任务，端口从 3800 到 $((port - 100))"
