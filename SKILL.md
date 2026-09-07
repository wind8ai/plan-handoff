---
name: plan-handoff
description: 将口头方案、Plan Mode 结果或已有设计整理为可追踪的实施计划，用于新建计划或更新同一目标的计划。
---

# Plan handoff

查证当前仓库，写出可交接的计划，不开始实施。

## 查证仓库

用 `git rev-parse --show-toplevel` 确认当前仓库工作目录。失败时请用户指定仓库。在该目录中查证并生成计划，不混用其他分支或工作目录的内容。

主干和普通分支均适用。使用 Git worktree 并行开发时，计划保存在当前工作树中。

读取用户材料、适用的仓库规则，以及直接相关的源码、测试和配置。确认现有行为、改动位置和验证入口后停止扩展检索。

区分用户已确认的行为、仓库事实、尚未决定的产品问题和普通实现建议。标准库、成功退出码、测试的组织方式等工程选择可沿用仓库惯例，无需逐项询问。

## 选择计划路径

遵循当前仓库及相关子项目的目录约定；无约定时用根目录 `plans/`。跨组件工作只写一份计划。

在选定目录查找同一目标的计划。同一目标的计划在原文件中更新，保留完整路径及历史编号；新的目标使用 `YYYY-MM-DD_topic.md`，英文主题用小写连字符。日期采用用户指定日期，否则用本地日期。

同名文件已存在时先读内容：同一目标更新原文件，独立目标换用更具体的主题。用 [路径解析器](scripts/resolve-plan-target.sh) 检查目标：

```bash
bash <skill-dir>/scripts/resolve-plan-target.sh --repo "$REPO_ROOT" --plan-root plans --date YYYY-MM-DD --topic topic-name
bash <skill-dir>/scripts/resolve-plan-target.sh --repo "$REPO_ROOT" --existing path/to/existing-plan.md
```

`target_mode=review` 表示文件已存在，需要先核实目标。

## 写计划

使用 [默认模板](references/plan-template.md)，删去不适用的可选内容。计划须让没有前序对话的执行者能够定位、实施和验证。

- YAML 值直接跟在字段后，同一行写完。`goal` 用单引号包住，内容中的单引号写成两个单引号。默认 `status: draft`；用户已批准且所有产品问题均已明确时才用 `approved`。
- 保留已确认行为，引用准确路径和符号，不把推测写成仓库事实。
- 每步写明改动位置、动作和完成结果。测试指向具体文件，验证写出能加载对应测试的命令和预期结果。
- 实现建议与产品要求分开。对尚未决定的问题，列出候选行为及其对步骤、测试的影响；受影响的步骤等待用户作出决定，不预选默认方案，计划保持 `draft`。
- 下一步写接手者首先要做的事。用户只要求记录尚未决定的问题时，写入计划后结束，不等待现场决定。

仅修改目标计划，保留已有改动。除非用户明确要求，不修改源码、测试、其他文档，不暂存、提交或发布。

## 校验与交付

脚本使用 Bash 3.2+、Git 和 awk，不需要 Python 或额外安装依赖。

用 [校验器](scripts/validate-plan.sh) 检查路径、必需章节、步骤清单和状态：

```bash
bash <skill-dir>/scripts/validate-plan.sh <plan-file>
bash <skill-dir>/scripts/validate-plan.sh --existing <historical-plan-file>
```

脚本只接受模板约定的两行字段：`status: draft`（也可为 approved 或 done）和单行单引号 `goal`。它不解析完整 YAML，不检查测试是否被命令实际加载；这些内容由 Agent 结合仓库核实。更新旧计划时，将头部和章节整理为当前模板格式。路径参数使用仓库相对路径，不包含父目录跳转或符号链接。

比较写入前后的 Git 状态和文件差异，确认只改目标计划。用 `git diff --check -- <plan-file>` 检查已跟踪文件；新文件直接检查空白和模板残留。结构通过后，复查实施步骤和下一步是否擅自采用了尚未决定的方案。

最后报告路径、状态、校验结果和尚未决定的问题。
