# inject_mem 脚本修改完成总结

## 修改内容

已成功将 `inject_mem` 脚本从**寄存器故障注入**模式改为**内存区域随机故障注入**模式。

## 完成的文件

### 核心文件
1. **generate_job.py** - 主脚本
   - 修改为支持内存地址范围参数
   - 实现随机地址和位索引生成
   - 添加可选的随机种子支持
   - 完整的参数验证和错误处理

2. **config.yaml.j2** - LAVA 任务配置模板
   - 修改为使用 `--fault-type ram` 模式
   - 使用随机生成的内存地址和位索引
   - 保持与 inject_pc 相似的结构以便维护

### 文档文件
3. **README.md** - 详细使用说明
   - 功能特性介绍
   - 参数说明
   - 使用示例
   - 与 inject_pc 的对比

4. **CHANGES.md** - 修改说明文档
   - 参数变化对比
   - 故障注入方式对比
   - 技术细节说明
   - 注意事项

5. **QUICK_REFERENCE.md** - 快速参考指南
   - 快速使用示例
   - 参数速查表
   - 工作流程
   - 常见问题解答

### 辅助文件
6. **example_run.sh** - 示例运行脚本
   - 可执行的示例
   - 包含推荐配置

7. **test_generate.py** - 数据生成测试脚本
   - 验证 gen_data() 函数
   - 测试随机生成逻辑
   - 验证数据范围

8. **test_template.py** - 模板渲染测试脚本
   - 验证 YAML 模板渲染
   - 检查关键配置项
   - 输出示例配置

## 主要特性

### 1. 随机内存故障注入
- 在用户指定的内存范围内随机选择地址
- 随机选择位索引（0-63）
- 每个任务可注入多个故障点

### 2. 灵活配置
- **内存范围**: `--mem-start` 和 `--mem-end` 参数
- **故障数量**: `--faults-per-job` 参数（默认 4）
- **可重现性**: `--seed` 参数支持固定随机种子

### 3. 完整测试
所有 Python 文件已通过语法检查：
- generate_job.py ✓
- test_generate.py ✓
- test_template.py ✓

运行测试验证：
- 数据生成测试通过 ✓
- 模板渲染测试通过 ✓

## 使用方法

### 基本使用
```bash
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 16 \
    --faults-per-job 4 \
    --xmlrpc-url "http://admin:token@server:9999/RPC2/" \
    --job-output jobs.txt \
    --port-start 2000 \
    --suffix 1 \
    --kernel linux
```

### 可重现测试
```bash
python3 generate_job.py \
    --mem-start 0x40000000 \
    --mem-end 0x80000000 \
    --qemu-number 10 \
    --seed 42 \
    ... # 其他参数
```

### 运行测试
```bash
# 测试数据生成
python3 test_generate.py

# 测试模板渲染
python3 test_template.py

# 或使用示例脚本
bash example_run.sh
```

## 技术实现

### 随机生成算法
```python
for _ in range(faults_per_job):
    addr = random.randint(mem_start, mem_end)
    bit_idx = random.randint(0, 63)
    injection_params.append((hex(addr), bit_idx))
```

### snapinject 命令格式
```bash
snapinject \
    --total-fault-number 1 \
    --min-interval 0 \
    --max-interval 0 \
    --fault-type ram \
    --fault-location <随机地址> \
    --bit-index <随机位索引> \
    --observe-time 10s \
    --snapshot-tag foo \
    --serial-socket <socket路径>
```

## 依赖

- Python 3.x
- jinja2 库
- xmlrpc.client（Python 标准库）
- SysKui/flip_simulation/gdb/fliputils.py 中的 snapinject 函数

## 输出

每个任务生成：
- CSV 日志：`/tmp/log-{kernel}-{number}-mem-{suffix}.csv`
- 标准输出：`/tmp/{kernel}-{number}-mem-{suffix}.out`
- 错误输出：`/tmp/{kernel}-{number}-mem-{suffix}.err`
- 任务 ID 列表：`jobs.txt`

## 对比原版 inject_pc

| 特性 | inject_pc | inject_mem（新） |
|------|-----------|-----------------|
| 目标 | CPU 寄存器 | RAM 内存 |
| 位置 | 顺序固定 | 完全随机 |
| 覆盖 | 单寄存器 | 大内存范围 |
| 灵活性 | 低 | 高 |
| 可重现 | 是（完全确定） | 是（通过 seed） |

## 验证状态

- [x] Python 语法检查通过
- [x] 数据生成测试通过
- [x] 模板渲染测试通过
- [x] 文档完整
- [x] 示例脚本可执行

## 后续使用建议

1. 根据实际内存布局调整 `--mem-start` 和 `--mem-end`
2. 根据测试需求调整 `--faults-per-job`
3. 使用 `--seed` 进行可重现的调试
4. 参考 inject_pc 的 read_result.py 实现结果分析

修改完成时间：2025年11月11日
