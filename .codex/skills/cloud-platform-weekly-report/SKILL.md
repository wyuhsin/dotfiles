---
name: cloud-platform-weekly-report
description: Token-efficient workflow for maintaining Haiwell cloud-platform-team member reports, project progress, the platform operations document link, department weekly reports, and annual rollups in /Users/haiwell/cloud-platform-management. Use when the user asks to pull, clean, check coverage for, generate, revise, or summarize 云平台项目组周报/成员周报/部门周报, including DWS report retrieval, DingTalk project-progress AITable reads, and the integrated platform operations workflow.
---

# 云平台项目组周报

以 `/Users/haiwell/cloud-platform-management` 为统一项目，保持钉钉只读；部门周报的“云平台运行情况”只放配置中的钉钉文档链接，不读取运行周报正文，先用脚本缩小上下文，再处理正文。

## 快速入口

先运行：

```bash
ruby /Users/haiwell/.codex/skills/cloud-platform-weekly-report/scripts/weekly_context.rb \
  --project-root /Users/haiwell/cloud-platform-management \
  --live
```

- 只查本地状态时去掉 `--live`。
- 指定周期时传 `--date YYYY-MM-DD`；脚本自动换算 ISO 周一至周日。
- 需要重新拉取已归档成员正文时加 `--show-report-ids`。
- 用户只问覆盖率、缺失成员或数据源状态时，返回脚本摘要后停止。

脚本分别只查询一次成员周报收件箱和部门周报作者发件箱。输出是本次执行清单；不要再全量列目录、读取所有历史周报或重复调用 DWS 收发箱。

## 固定流程

1. **确定范围**
   - `data/department.yaml.report_author` 是部门周报作者；当前为翁宇欣。
   - `data/members.yaml` 只维护成员周报贡献者，不包含部门周报作者。
   - 应用 `data/department.yaml` 的永久排除项；当前不自动恢复被排除成员。
   - 周期使用 ISO 周一至周日、`Asia/Shanghai`。

2. **获取成员周报**
   - 复用脚本返回的 `action`：仅对 `fetch` 调用 `dws report entry get`。
   - `skip` 表示本地已有；除非用户要求刷新，不再拉正文。
   - 成员周报只从收件箱获取；部门周报作者的发件箱周报不是成员周报，不进入成员归档、缺失名单或覆盖率。
   - 清洗 HTML 颜色/样式但保留标题和嵌套列表，尤其是“版本 → 关键进展 → 子项目 → 明细”。
   - 不补造进展、数字、负责人或日期；新归档先标 `submitted`。

3. **确定部门周报基线**
   - 读取脚本输出的 `department_report.action`。
   - `fetch_authoritative`：使用输出的精确 `report_id` 调用一次 `dws report entry get`。钉钉正文是该周期的内容权威版本，必须保留用户修改后的措辞、章节和多层缩进，并同步到标准本地路径；不得再用成员周报、TODO、项目进度表或运行报告重新生成后覆盖它。
   - `generate_local_draft`：目标周期的钉钉发件箱尚无部门周报，才可综合各来源生成本地可编辑草稿。本地草稿只是一份工作副本，不是后续汇总的最终内容来源。
   - `check_outbox`：当前仅做了本地检查；生成或修订前先用 `--live` 核对发件箱。
   - 钉钉版本存在后，如果上游事实发生变化，只单独列出建议修订，不静默改写钉钉同步内容。
   - 所有 DWS 读取加 `--format json`；未经用户明确要求，不调用提交命令。

4. **获取项目进度**
   - 以 `config/data-sources.yaml` 的 `project-progress` AI 表格为权威来源。
   - 每次只调用一次 `base get` 和一次批量 `table get` 刷新结构。
   - 查询记录时传 `--field-ids`，只取周报需要的字段；不要把全表原始 JSON注入上下文。
   - “项目迭代 + 任务表”提供状态、阶段和计划日期；变更、风险、缺陷表只补充相关事项。
   - 读取结果是时点快照；无明确日期时不得写成“本周发生”。

5. **获取运行情况**
   - 直接使用脚本输出的 `platform_ops.document_url`。
   - “云平台运行情况”章节只放该钉钉文档链接，不摘录运行指标、故障、交付、性能、容量或风险，也不把这些内容写入部门周报其他章节。
   - 不读取、匹配或校验 `reports/weekly/` 正文。
   - 部门周报流程不得隐式触发运行模块的采集、生成、钉钉同步或 Git 操作；用户明确要求维护平台运行报告时，在项目根目录遵循根 `AGENTS.md` 和项目内 Skills。

6. **生成部门周报**
   - 仅当 `department_report.action` 为 `generate_local_draft` 时执行本节。
   - 从 `templates/department-weekly.md` 创建目标文件。
   - 自 `2026-W31` 起固定八章及顺序，不增删、不改名。
   - 项目状态与计划日期以 AI 表格为准；成员周报补充当周事实。冲突时并列保留并标“待核实”。
   - 成员覆盖只计算 `data/members.yaml` 中的成员周报贡献者；部门周报作者不进入分母或分子。
   - 来源只用于生成过程中的事实核对，不写入部门周报文件。
   - 禁止在输出中写入 `<!-- source: ... -->`、成员周报路径、外部记录 ID 或“来源”字段；成员覆盖表只显示成员和状态。
   - 未经确认保持 `draft`；不得直接发布、更新远程文档或发送消息。

## Token 约束

- 先脚本、后正文；只读取目标周文件。
- 每个目标周期最多各查一次成员收件箱和作者发件箱；正文只拉执行清单要求的精确 `report_id`。
- AI 表格先取结构，再按字段裁剪记录；不读取无关列和全量附件。
- “云平台运行情况”只取配置中的一个链接，不读取平台运行报告正文或资源 JSON。
- 不在报告文件中输出来源、成员周报路径、技术 ID、DWS `agentDisplay`、全量目录或已确认规则。
- 状态问题用短表或计数回答；生成任务才加载完整模板与来源正文。

## 完成检查

运行项目 `AGENTS.md` 的验证命令，并额外确认：

- 部门周报作者未进入成员清单、覆盖率或缺失名单；有效成员、排除项和覆盖率一致。
- 最深一层 Markdown 嵌套可正确渲染。
- 第一章有 AI 表格读取日期，事实已在生成过程中与目标记录核对。
- 部门周报源文件中不存在来源注释、成员周报路径或外部记录 ID。
- 第五章仅包含脚本输出的钉钉文档链接，运行指标或风险未出现在其他章节。
- 若发件箱存在同周期部门周报，本地标准文件与钉钉正文一致，且没有被其他来源重新生成覆盖。
- 本次没有未经授权的钉钉写入、远程同步、提交或推送。
