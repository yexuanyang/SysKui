# 修改说明：从寄存器注入到内存随机注入

## 概述

本脚本已从 **寄存器故障注入** 模式修改为 **内存区域随机故障注入** 模式。

## 主要改动

### 1. 参数变化

**原始版本（inject_pc 风格）:**
- `--register`: 指定要注入故障的寄存器名称（如 pc）
- 每个任务注入 4 个连续的位（number*4 到 number*4+3）

**新版本（inject_mem）:**
- `--mem-start`: 内存区域起始地址（十六进制格式）
- `--mem-end`: 内存区域结束地址（十六进制格式）
- `--faults-per-job`: 每个任务注入的随机故障数量（默认 4）
- `--seed`: 可选的随机种子，用于可重现的测试

### 2. 故障注入方式

**原始版本:**
```python
pairs = [
    (register, number * 4),
    (register, number * 4 + 1),
    (register, number * 4 + 2),
    (register, number * 4 + 3),
]
```
- 固定注入特定寄存器的连续 4 个位

**新版本:**
```python
for _ in range(faults_per_job):
    addr = random.randint(mem_start, mem_end)
    bit_idx = random.randint(0, 63)
    injection_params.append((hex(addr), bit_idx))
```
- 在指定内存范围内随机选择地址
- 随机选择位索引（0-63）
- 支持自定义故障数量

### 3. snapinject 命令变化

**原始版本:**
```jinja
snapinject --fault-type reg --fault-location {{register}} --bit-index {{bit_index}}
```

**新版本:**
```jinja
snapinject --fault-type ram --fault-location {{address}} --bit-index {{bit_index}}
```

### 4. 使用场景对比

| 特性 | inject_pc (寄存器) | inject_mem (内存) |
|------|-------------------|------------------|
| 目标 | CPU 寄存器 | RAM 内存地址 |
| 位置选择 | 固定（顺序递增） | 随机 |
| 覆盖范围 | 单个寄存器的位 | 大范围内存区域 |
| 可重现性 | 完全确定 | 可通过 seed 控制 |
| 适用场景 | 测试特定寄存器敏感性 | 测试内存错误影响 |

## 使用示例对比

### inject_pc 示例:
```bash
python3 generate_job.py \
    --register pc \
    --qemu-number 16 \
    --xmlrpc-url "..." \
    --job-output jobs.txt \
    --port-start 2000 \
    --suffix 1 \
    --kernel linux
```

### inject_mem 示例:
```bash
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 16 \
    --faults-per-job 4 \
    --xmlrpc-url "..." \
    --job-output jobs.txt \
    --port-start 2000 \
    --suffix 1 \
    --kernel linux \
    --seed 42
```

## 技术细节

### 内存地址生成
- 使用 `random.randint(mem_start, mem_end)` 在范围内均匀随机选择
- 地址以十六进制字符串格式存储在 YAML 配置中
- 支持完整的 64 位地址空间

### 位索引生成
- 范围: 0-63（支持 8 字节/64 位数据）
- 使用 `random.randint(0, 63)` 随机选择
- 与 snapinject 的 `--bit-index` 参数兼容

### 可重现性
- 通过 `--seed` 参数设置随机种子
- 相同的 seed 产生相同的故障序列
- 便于调试和验证

## 注意事项

1. **内存范围选择**: 确保选择的内存范围是有效的 RAM 地址，可被客户操作系统访问
2. **故障数量**: `--faults-per-job` 越大，每个任务执行时间越长
3. **QEMU 数量**: 不像 inject_pc 受寄存器位数限制，inject_mem 的 QEMU 数量可根据需要设置
4. **性能考虑**: 大范围随机注入可能需要更多时间来覆盖关键区域

## 依赖的 fliputils.py 功能

脚本依赖 `SysKui/flip_simulation/gdb/fliputils.py` 中的 `snapinject` 函数，具体使用参数：

- `--fault-type ram`: 指定注入类型为内存
- `--fault-location <address>`: 十六进制内存地址
- `--bit-index <bit>`: 要翻转的位索引
- `--observe-time 10s`: 注入后观察时间
- `--snapshot-tag foo`: 快照标签
- `--serial-socket <socket>`: 串口 socket 路径
