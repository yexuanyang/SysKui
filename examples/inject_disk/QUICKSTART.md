# LAVA Job Submission - Quick Start Guide

## 📋 概述

`submit.py` 脚本用于批量提交 `generated_disk_yamls` 目录中的所有 YAML 文件到 LAVA 服务器，并将任务 ID 保存到 `jobs.txt` 文件中。

## 🚀 快速开始

### 1. 基本使用（推荐）

```bash
# 查看将要提交的文件（不实际提交）
python3 submit.py --dry-run

# 提交所有任务
python3 submit.py

# 验证结果
python3 test_jobs.py jobs.txt
```

### 2. 详细输出模式

```bash
# 显示每个任务的提交详情
python3 submit.py --verbose
```

### 3. 自定义配置

```bash
python3 submit.py \
    --xmlrpc-url "http://admin:token@server:9999/RPC2/" \
    --yaml-dir generated_disk_yamls \
    --output jobs.txt \
    --verbose
```

## 📊 输出格式

`jobs.txt` 使用 Python 列表格式存储任务 ID：

```python
[12345, 12346, 12347, 12348, ...]
```

**优点：**
- ✅ 易于 Python 程序读取（使用 `eval()` 或 `ast.literal_eval()`）
- ✅ 紧凑格式，单行存储
- ✅ 保持顺序

## 📁 文件说明

| 文件 | 用途 |
|------|------|
| `submit.py` | 主提交脚本 |
| `test_jobs.py` | 验证 jobs.txt 格式 |
| `create_mock_jobs.py` | 创建模拟数据用于测试 |
| `example_submit.sh` | 完整工作流示例 |
| `README_SUBMIT.md` | 详细文档 |

## 🔧 常用参数

```bash
--xmlrpc-url URL    # LAVA 服务器地址
--yaml-dir DIR      # YAML 文件目录
--output FILE       # 输出文件名
--verbose           # 详细输出
--dry-run           # 模拟运行
```

## 📖 使用示例

### 示例 1: 标准提交流程

```bash
# Step 1: 预检查
python3 submit.py --dry-run | head -20

# Step 2: 提交任务
python3 submit.py

# Step 3: 验证输出
cat jobs.txt
python3 test_jobs.py jobs.txt
```

### 示例 2: 读取并使用任务 ID

```python
# read_jobs.py
with open('jobs.txt', 'r') as f:
    job_ids = eval(f.read().strip())

print(f"Total jobs: {len(job_ids)}")
print(f"Job IDs: {job_ids[:10]}...")  # 前 10 个
```

### 示例 3: 监控任务状态

```python
# monitor_jobs.py
import xmlrpc.client

server = xmlrpc.client.ServerProxy("http://admin:token@server:9999/RPC2/")

with open('jobs.txt', 'r') as f:
    job_ids = eval(f.read().strip())

for job_id in job_ids[:5]:
    try:
        status = server.scheduler.job_state(job_id)
        print(f"Job {job_id}: {status}")
    except Exception as e:
        print(f"Job {job_id}: Error - {e}")
```

## ⚙️ 工作流程

```
┌─────────────────┐
│ 生成 YAML 文件  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ submit.py       │
│ --dry-run       │  (可选) 预检查
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ submit.py       │  提交到 LAVA
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ jobs.txt        │  保存任务 ID
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ test_jobs.py    │  (可选) 验证
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 监控/收集结果   │
└─────────────────┘
```

## 🧪 测试功能

在实际提交前，可以使用 mock 测试：

```bash
# 创建模拟的 jobs.txt
python3 create_mock_jobs.py

# 验证格式
python3 test_jobs.py jobs_mock.txt
```

## ⚠️ 注意事项

1. **640 个任务**：当前有 640 个 YAML 文件要提交
2. **提交时间**：大量任务提交需要时间，请耐心等待
3. **网络连接**：确保与 LAVA 服务器的连接稳定
4. **凭证**：确保 XMLRPC URL 中的用户名和 token 正确

## 🐛 故障排除

| 问题 | 解决方案 |
|------|----------|
| 找不到 YAML 文件 | 检查 `--yaml-dir` 路径是否正确 |
| 连接服务器失败 | 验证 `--xmlrpc-url` 和网络连接 |
| 部分任务失败 | 查看错误信息，检查 YAML 格式 |
| jobs.txt 为空 | 检查是否有任务成功提交 |

## 📞 获取帮助

```bash
python3 submit.py --help
```

查看所有可用参数和使用示例。
