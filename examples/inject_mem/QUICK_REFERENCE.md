# 快速参考指南

## 基本用法

```bash
python3 generate_job.py \
    --mem-start <起始地址> \
    --mem-end <结束地址> \
    --qemu-number <实例数量> \
    --faults-per-job <每个任务的故障数> \
    --xmlrpc-url <LAVA服务器URL> \
    --job-output <输出文件> \
    --port-start <起始端口> \
    --suffix <后缀> \
    --kernel <内核类型>
```

## 实际示例

### 1. 基本内存注入
```bash
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 10 \
    --faults-per-job 4 \
    --xmlrpc-url "http://admin:token@10.161.28.20:9999/RPC2/" \
    --job-output jobs.txt \
    --port-start 2000 \
    --suffix 1 \
    --kernel linux
```

### 2. 可重现测试（带种子）
```bash
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 5 \
    --faults-per-job 8 \
    --seed 42 \
    --xmlrpc-url "http://admin:token@10.161.28.20:9999/RPC2/" \
    --job-output jobs.txt \
    --port-start 3000 \
    --suffix 2 \
    --kernel openeuler
```

### 3. 大规模测试
```bash
python3 generate_job.py \
    --mem-start 0x00000000 \
    --mem-end 0xFFFFFFFF \
    --qemu-number 100 \
    --faults-per-job 10 \
    --xmlrpc-url "http://admin:token@10.161.28.20:9999/RPC2/" \
    --job-output jobs_large.txt \
    --port-start 4000 \
    --suffix 3 \
    --kernel phytium
```

## 参数说明

| 参数 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `--mem-start` | ✓ | - | 内存区域起始地址（十六进制） |
| `--mem-end` | ✓ | - | 内存区域结束地址（十六进制） |
| `--qemu-number` | ✓ | 64 | QEMU 实例数量 |
| `--faults-per-job` | ✗ | 4 | 每个任务注入的故障数 |
| `--xmlrpc-url` | ✓ | - | LAVA 服务器 XMLRPC URL |
| `--job-output` / `-j` | ✓ | jobs.txt | 任务 ID 输出文件 |
| `--port-start` / `-p` | ✓ | 2000 | SSH 起始端口号 |
| `--suffix` | ✓ | - | 日志文件后缀 |
| `--kernel` | ✓ | - | 内核类型（linux/openeuler/phytium） |
| `--seed` | ✗ | None | 随机种子（用于可重现） |

## 工作流程

1. **生成任务**
   ```bash
   python3 generate_job.py [参数...]
   ```

2. **查看生成的任务 ID**
   ```bash
   cat jobs.txt
   ```

3. **等待任务完成**
   - 使用 LAVA Web 界面监控
   - 或使用 LAVA CLI 工具

4. **读取结果**
   ```bash
   python3 read_result.py --container <容器ID>
   ```

## 故障注入说明

每个任务会：
1. 在指定内存范围内随机选择 `--faults-per-job` 个地址
2. 为每个地址随机选择一个位（0-63）
3. 使用 `snapinject` 以 `--fault-type ram` 模式注入故障
4. 每次注入前创建快照，注入后观察 10 秒
5. 恢复快照以进行下一次注入

## 输出文件

每个任务生成：
- `/tmp/log-{kernel}-{number}-mem-{suffix}.csv` - 故障注入日志
- `/tmp/{kernel}-{number}-mem-{suffix}.out` - 标准输出
- `/tmp/{kernel}-{number}-mem-{suffix}.err` - 错误输出

## 调试技巧

### 测试配置生成（不提交任务）
```bash
python3 test_generate.py
python3 test_template.py
```

### 验证内存范围
确保选择的内存范围在虚拟机的有效 RAM 中：
```bash
# 在 QEMU 中使用 GDB 查看内存映射
(gdb) info mtree
```

### 调整故障数量
- 少量故障（1-4）：快速测试
- 中等数量（5-10）：平衡测试
- 大量故障（10+）：详尽测试

## 常见问题

**Q: 内存地址应该选择什么范围？**
A: 取决于你的目标系统。通常：
- Linux: 0x40000000-0x80000000（1GB RAM）
- 可以使用 `info mtree` 查看实际 RAM 范围

**Q: qemu-number 应该设置多少？**
A: 没有限制，但要考虑：
- 系统资源（每个 QEMU 实例需要内存）
- 测试时间（更多实例 = 更长时间）
- 建议从 10-20 开始

**Q: faults-per-job 太多会怎样？**
A: 每个故障注入需要时间，太多会导致：
- 任务执行时间过长
- 可能超时
- 建议 4-10 个故障/任务

**Q: 如何确保结果可重现？**
A: 使用 `--seed` 参数：
```bash
--seed 42  # 使用固定种子
```

## 文件列表

```
inject_mem/
├── generate_job.py          # 主脚本
├── config.yaml.j2            # YAML 模板
├── README.md                 # 详细说明
├── CHANGES.md                # 修改说明
├── QUICK_REFERENCE.md        # 本文件
├── example_run.sh            # 示例运行脚本
├── test_generate.py          # 数据生成测试
└── test_template.py          # 模板渲染测试
```
