# plan-handoff

将口头方案、Plan Mode 结果或已有设计整理为仓库内可追踪的实施计划，供后续执行或跨会话交接。

## 安装

```bash
npx skills add wind8ai/plan-handoff
```

也可将本仓库复制或链接到 Agent 支持的 Skill 目录。脚本使用 Bash 3.2+、Git 和 awk，不需要 Python 或安装第三方库。通过 `bash <script>` 调用。

脚本检查模板规定的单行头部、路径、必需章节、步骤和状态，不提供完整 YAML 解析或测试覆盖分析。Agent 仍需核实计划内容和验证命令。

## 使用

要求 Agent 使用 plan-handoff 整理方案。它会查证当前仓库工作目录的源码与约定，使用默认模板写计划，并检查结构和文件变更。

支持主干、普通分支和 Git worktree 并行开发，计划始终写入当前工作目录。

计划优先遵循仓库或子项目约定，默认放在根目录 `plans/`。新文件采用 `YYYY-MM-DD_topic.md`，英文主题使用小写连字符；同一目标更新原文件，保留历史编号。

有尚未决定的产品问题时保持 `draft`，受影响的步骤等待用户作出决定。生成计划不会开始实施或提交。

## 文件

- [SKILL.md](SKILL.md)：操作流程。
- [默认模板](references/plan-template.md)：计划结构。
- [路径解析器](scripts/resolve-plan-target.sh)：新建与更新的路径检查。
- [校验器](scripts/validate-plan.sh)：约定的单行头部、章节、步骤和状态检查。
