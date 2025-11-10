# read_result.py 快速参考

## 基本用法

```bash
python3 read_result.py \
    --container <container_id> \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000
```

## 必需参数

| 参数 | 短选项 | 说明 | 示例 |
|------|--------|------|------|
| `--container` | - | LAVA slave 容器 ID | `abc123def456` |
| `--input` | `-i` | 任务 ID 文件 | `jobs.txt` |
| `--output` | `-o` | 结果输出文件 | `results.json` |
| `--suffix` | - | 日志文件后缀 | `1` |
| `--kernel` | - | 内核类型 | `linux`/`openeuler`/`phytium` |

## 可选参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--mem-start` | 内存范围起始地址 | `0x40000000` |
| `--mem-end` | 内存范围结束地址 | `0x80000000` |

## 获取容器 ID

```bash
# 查找 lava-slave 容器
docker ps | grep lava-slave

# 自动获取容器 ID
CONTAINER_ID=$(docker ps | grep lava-slave | awk '{print $1}')
```

## 输出结果

### 控制台输出

```
Job 12345 (index: 0)
  Injection type: ram
  Addresses: ['0x4e4018bf', '0x6334292b', ...]
  Bit indices: ['3', '31', ...]
  Panic count: 2
  Fault count: 4
----------------------------------------
...
========================================
Total panic/total fault: 10/64
Panic rate: 15.62%
Results saved to: results.json
```

### JSON 输出

```json
{
  "12345": {
    "job_index": 0,
    "injection_type": "ram",
    "addresses": ["0x4e4018bf", "0x6334292b"],
    "bit_indices": ["3", "31"],
    "panic_count": "2",
    "fault_count": "4",
    "log": {...}
  },
  "summary": {
    "total_jobs": 16,
    "total_panic": 10,
    "total_fault": 64,
    "panic_rate": "10/64",
    "mem_range": "0x40000000-0x80000000"
  }
}
```

## 分析结果

### 使用 jq 查看汇总

```bash
cat results.json | jq '.summary'
```

### 查看特定任务

```bash
cat results.json | jq '.\"12345\"'
```

### 统计有 panic 的任务

```bash
cat results.json | jq '[to_entries[] | select(.key | test("^[0-9]+$")) | select(.value.panic_count != "0")] | length'
```

### 列出所有 panic 任务

```bash
cat results.json | jq '[to_entries[] | select(.key | test("^[0-9]+$")) | select(.value.panic_count != "0") | {job: .key, panics: .value.panic_count, faults: .value.fault_count}]'
```

### 计算平均 panic 率

```bash
cat results.json | jq '.summary | (.total_panic / .total_fault * 100)'
```

## 完整工作流示例

```bash
# 1. 提交任务
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 16 \
    --faults-per-job 4 \
    --xmlrpc-url "http://admin:token@server:9999/RPC2/" \
    --job-output jobs.txt \
    --suffix 1 \
    --kernel linux \
    --seed 42

# 2. 等待任务完成...

# 3. 获取容器 ID
docker ps | grep lava-slave

# 4. 读取结果
python3 read_result.py \
    --container abc123 \
    --input jobs.txt \
    --output results.json \
    --suffix 1 \
    --kernel linux \
    --mem-start 0x40000000 \
    --mem-end 0x80000000

# 5. 分析结果
cat results.json | jq '.summary'
```

## 故障排查

### 问题：找不到日志文件

**错误：** `cat: /tmp/log-linux-0-mem-1.csv: No such file or directory`

**解决：**
- 确认任务已完成
- 检查 `--suffix` 参数是否与生成时一致
- 检查 `--kernel` 参数是否正确

### 问题：任务未完成

**输出：** `12345 should resubmit or not finished`

**解决：**
- 检查 LAVA Web 界面查看任务状态
- 等待任务完成后重新运行
- 如果任务失败，需要重新提交

### 问题：容器 ID 错误

**错误：** `Error: No such container: abc123`

**解决：**
```bash
# 重新获取正确的容器 ID
docker ps | grep lava-slave
```

## 脚本位置

```
inject_mem/
├── read_result.py              # 主脚本
├── example_read_results.sh     # 使用示例
└── READ_RESULT_CHANGES.md      # 详细修改说明
```
