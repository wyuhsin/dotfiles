---
name: performance-monitor-maintenance
description: 生成和维护通用的 Windows 与 Linux 性能检测脚本，提供可配置的进程监控、按进程和日期命名的记录文件、统一 CSV 输出及通俗指标名称。用于创建、改造、解释、验证或排障 CPU、内存、进程及系统指标。
---

# 通用性能检测脚本

## 定位

将 Skill 的 `scripts/` 目录作为唯一事实来源和可直接运行的模板。脚本已经通用化，不要恢复固定产品进程名、设备路径或宽表 CSV，除非用户明确要求兼容旧设备。

当前入口：

- Skill Windows：`scripts/monitor.bat`，转调同目录的 `scripts/monitor-windows.ps1`
- Skill Linux：`scripts/monitor-linux.sh`
- 指标词典：[`references/metric-glossary.md`](references/metric-glossary.md)

## 统一输出契约

让两个平台输出相同的长表 CSV，列顺序固定为：

```text
timestamp,hostname,os,scope,target,metric_name,source_field,value,unit,status
```

- `metric_name` 使用通俗中文，例如“当前实际内存”“历史最大虚拟内存”“处理器使用率”。
- `source_field` 只用于技术追溯，例如 `VmRSS`、`VmPeak`，不要把它作为主要展示名称。
- `value` 只写数值，不把单位拼进数值；无法读取时留空，并在 `status` 说明原因。
- 时间使用 UTC 的 `yyyy-MM-ddTHH:mm:ssZ`；内存统一使用 MB，速率或比例使用明确单位。
- `scope` 使用 `system` 或 `process`；`target` 写主机名、进程名或“进程名[PID]”。
- 不把缺失值写成 `0`，不把一次采样得到的累计计数伪装成速率。

每次启动都新建一个记录文件，不追加到固定文件名。文件名格式为：

```text
进程1-进程2_yyyyMMdd_HHmmss.csv
```

进程名来自参数定义；非法文件名字符会转换为 `-`。使用 `-a` 时文件名使用 `all-processes_yyyyMMdd_HHmmss.csv`。发生同秒重名时追加数字后缀。

不同系统的底层接口不完全相同，因此保持“输出结构、核心指标名称、单位和状态表达”一致；确实只在某个平台可读的指标可以额外输出，或使用 `不支持` 状态说明，不要伪造等价值。

## 参数化运行

### Linux

```sh
./scripts/monitor-linux.sh -p nginx,sshd -i 5 -n 12 -o ./records
./scripts/monitor-linux.sh -p nginx -p sshd -i 10 -n 1 -o ./records
./scripts/monitor-linux.sh -a -i 10 -n 0 -o ./records
```

- `-p name1,name2`：按进程名精确匹配；必须定义一个或多个进程。
- `-p name`：可重复传入，用于追加多个进程。
- `-a`：显式采集所有可读取进程，不能和 `-p` 同时使用。
- `-i seconds`：采样间隔，默认 `5` 秒。
- `-n samples`：采样次数，默认 `1`；`0` 表示持续运行。
- `-o directory`：输出目录，默认当前目录；脚本自动按进程和日期生成 CSV 文件名。
- `-r proc-root`：仅用于测试时替换 `/proc` 根目录。

保持 POSIX `sh` 兼容。进程不存在、权限不足、`/proc` 字段不存在或输出目录不可写时输出空值和状态，不用零值掩盖失败。

### Windows

```powershell
.\scripts\monitor.bat -ProcessName s-series,explorer -IntervalSeconds 5 -Samples 12 -Output .\records
powershell.exe -NoProfile -File .\scripts\monitor-windows.ps1 -ProcessName s-series,explorer -IntervalSeconds 10 -Samples 0 -OutputDirectory .\records
```

- `-ProcessName name1,name2`：按进程名采集；必须定义一个或多个进程。
- `-ProcessName name`：可重复传入，用于追加多个进程。
- `-IncludeAllProcesses`：显式采集所有可读取进程，不能和 `-ProcessName` 同时使用。
- `-IntervalSeconds`：采样间隔，默认 `5` 秒。
- `-Samples`：采样次数，默认 `1`；`0` 表示持续运行。
- `-OutputDirectory`：输出目录，默认当前目录；`-Output` 仍可作为兼容别名。

脚本每次启动都会在输出目录创建 `进程1-进程2_yyyyMMdd_HHmmss.csv`。

进程 CPU 使用率需要相邻两次采样；第一次采样可以留空并写明“需要下一次采样”。在非 Windows 环境不要宣称已经验证 CIM、`Get-Process` 或 Windows 权限行为。

## 修改工作流

1. 先读取 Skill `scripts/` 中的模板，确认用户要改的是通用默认行为、参数、输出契约还是平台专属采集。
2. 新增指标时同时更新两个平台的 `metric_name`、`source_field`、单位和失败状态；能统一就统一，不能统一就明确标记不支持。
3. 修改进程匹配时保持参数化，要求通过参数明确定义进程，不把具体产品进程名写回默认逻辑；修改路径时保持输出目录可配置。
4. 解释 `VmPeak`、`VmSize`、`VmRSS` 等字段时，使用 [指标词典](references/metric-glossary.md) 的通俗名称和含义。
5. 只在用户明确要求时改变 CSV 列顺序、字段名或数据类型；改变前检查是否有下游脚本依赖。
6. 通用修订直接更新 Skill `scripts/`，并保持三个入口脚本的参数和输出契约同步。
7. 不写入密码、Token、设备凭据或完整远程访问 URL；不自动注册 Windows 任务计划、服务或 Linux systemd 服务。

## 验证工作流

1. Linux 执行 `sh -n scripts/monitor-linux.sh`，有 `shellcheck` 时再执行静态检查。
2. Windows 在目标 Windows 环境执行 PowerShell 解析或受控单次运行；当前 macOS 只能做文本检查。
3. 使用临时输出目录做一次采样，检查文件名是否包含进程名和日期，表头、字段数、中文指标名、单位、空值状态和 UTC 时间。
4. 用两个已知进程、重复 `-p` 参数和一个不存在的进程验证匹配与失败行为；用 `-a` 前评估数据量。
5. 连续采样时验证第二次采样以后才出现 CPU 速率类指标，避免把累计 CPU 时间当作使用率。
6. 交付时区分静态检查、当前开发机试运行、Windows 实机验证和 Linux 目标设备验证。

## 兼容性边界

- 历史版本中的固定路径、固定进程名单、`pause`、设备编号文件和旧宽表字段只保留在历史参考中。
- 如果用户要求恢复旧设备兼容，先单独设计兼容模式，不要破坏通用输出默认值。
- 任何需要长期运行的部署动作都必须由用户明确授权，并单独验证日志轮转、停止方式和失败重启。
