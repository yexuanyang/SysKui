# read_result.py 修改说明

## 概述

`read_result.py` 已从 inject_pc 版本修改为适用于 inject_mem（内存故障注入）的版本。

## 主要改动

### 1. 参数变化

**移除的参数：**
- `--register` / `-r`: 不再需要指定寄存器名称

**新增的参数：**
- `--mem-start`: 内存区域起始地址（可选，用于记录到结果中）
- `--mem-end`: 内存区域结束地址（可选，用于记录到结果中）

**保留的参数：**
- `--container`: Docker 容器 ID
- `--input` / `-i`: 任务 ID 输入文件
- `--output` / `-o`: 结果输出文件
- `--suffix`: 日志文件后缀
- `--kernel`: 内核类型

### 2. 日志文件路径

**inject_pc 版本：**
```python
log_path = f"/tmp/log-{args.kernel}-{index}-{args.register}-{args.suffix}.csv"
```

**inject_mem 版本：**
```python
log_path = f"/tmp/log-{args.kernel}-{index}-mem-{args.suffix}.csv"
```

使用 "mem" 替代寄存器名称。

### 3. 输出数据结构

**inject_pc 版本：**
```json
{
  "jobid": {
    "bit_index": [0, 1, 2, 3],
    "panic_count": "2",
    "fault_count": "4",
    "register": "pc",
    "log": {...}
  }
}
```

**inject_mem 版本：**
```json
{
  "jobid": {
    "job_index": 0,
    "injection_type": "ram",
    "addresses": ["0x4e4018bf", "0x6334292b"],
    "bit_indices": ["3", "31"],
    "panic_count": "2",
    "fault_count": "4",
    "log": {...}
  }
}
```

### 4. 新增汇总信息

```json
{
  "summary": {
    "total_jobs": 16,
    "total_panic": 10,
    "total_fault": 64,
    "panic_rate": "10/64",
    "mem_range": "0x40000000-0x80000000"
  }
}
```

### 5. 增强的输出信息

- 显示 panic 百分比
- 显示内存地址范围（如果提供）
- 更详细的任务信息输出

## 使用对比

### inject_pc 用法：

```bash
python3 read_result.py \
    --container abc123 \
    --input jobs.txt \
    --output results.json \
    --register pc \
    --suffix 1 \
    --kernel linux
```

### inject_mem 用法：

```bash
python3 read_result.py \
    --container abc123 \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000
```

## 兼容性

- 仍然兼容相同的容器结构
- 仍然读取相同的 panic_count.txt 和 fault_number.txt 文件
- 日志 CSV 文件格式保持兼容
- jobs.txt 格式保持一致（Python 列表）

## 新功能

1. **自动提取地址和位索引**：从日志文件中解析注入的内存地址和位索引
2. **增强的汇总统计**：包含总任务数、panic 率等
3. **可选的内存范围记录**：将测试的内存范围记录到结果中
4. **更友好的输出**：显示 panic 百分比和格式化的统计信息

## 注意事项

1. 确保日志文件命名格式为：`log-{kernel}-{index}-mem-{suffix}.csv`
2. `--mem-start` 和 `--mem-end` 是可选的，但建议提供以便在结果中记录
3. 脚本会自动从日志中提取地址和位索引信息
4. 对于未完成或失败的任务，会输出警告信息到 stderr

## 测试

```bash
# 使用示例脚本
./example_read_results.sh

# 或者直接运行
python3 read_result.py \
    --container $(docker ps | grep lava-slave | awk '{print $1}') \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000

# 查看结果
cat results.json | jq '.summary'
```
