# Ralph PRD Generator

An Agent Skill for Claude Code that generates Product Requirements Documents (PRDs) and specifications optimized for [Ralph](https://github.com/anthropics/ralph) autonomous development.

[中文版](#中文版)

---

## Overview

This skill helps you convert app ideas into complete Ralph-compatible project structures:

- **PROMPT.md** - Main development instructions with RALPH_STATUS block
- **@fix_plan.md** - Phased, prioritized task checklist
- **specs/*.md** - Detailed technical specifications
- **@AGENT.md** - Build and run instructions

## Installation

### Claude Code (Global)

```bash
# Copy to user skills directory
cp -r ralph-prd-generator ~/.claude/skills/
```

### Claude Code (Project-specific)

```bash
# Copy to project skills directory
cp -r ralph-prd-generator .claude/skills/
```

### Claude.ai (Pro/Max/Team/Enterprise)

1. Zip the skill directory
2. Go to Settings > Features
3. Upload the .zip file

### Claude API

```python
import anthropic

client = anthropic.Anthropic()

skill = client.beta.skills.create(
    display_title="Ralph PRD Generator",
    files=files_from_dir("./ralph-prd-generator"),
    betas=["skills-2025-10-02"]
)
```

## Usage

### Basic Usage

Simply describe your app idea:

```
Create a PRD for a habit tracking app with streaks, reminders, and statistics.
```

Claude will:
1. Ask clarifying questions if needed
2. Generate PROMPT.md with development instructions
3. Generate @fix_plan.md with phased tasks
4. Generate specs/ files with technical details

### With Existing Requirements

```
I have these requirements. Convert them to Ralph format:

- User authentication with email/password
- CRUD operations for tasks
- Dashboard with charts
- Built with React and Express
```

### Validate Existing Project

```
Validate my Ralph project structure at ./my-project
```

## Skill Structure

```
ralph-prd-generator/
├── SKILL.md                           # Main instructions
├── README.md                          # This file
├── references/
│   ├── prd-templates.md               # Full templates by project type
│   ├── task-breakdown.md              # Task granularity patterns
│   ├── ralph-format.md                # File format specifications
│   └── speckit-integration.md         # Spec-Kit integration guide
└── scripts/
    ├── validate_ralph_project.py      # Project structure validator
    └── speckit_to_ralph.py            # Spec-Kit to Ralph converter
```

## Features

### PRD Generation

| Feature | Description |
|---------|-------------|
| Requirements Gathering | Asks clarifying questions for incomplete ideas |
| PROMPT.md Generation | Creates development instructions with RALPH_STATUS |
| Task Breakdown | Generates phased @fix_plan.md with 5-30 min tasks |
| Spec Generation | Creates data models, API endpoints, UI components |
| Validation | Checks project structure before delivery |

### Project Templates

| Project Type | Generated Specs |
|--------------|-----------------|
| Web Application | data-models.md, api-endpoints.md, ui-components.md |
| CLI Tool | commands.md |
| REST API | data-models.md, api-endpoints.md, authentication.md |

### Scripts

#### validate_ralph_project.py

Validates Ralph project structure:

```bash
python scripts/validate_ralph_project.py ./my-project
```

Checks:
- Required files exist (PROMPT.md, @fix_plan.md)
- RALPH_STATUS and EXIT_SIGNAL blocks present
- Proper phase structure and task markers
- specs/ directory contents

#### speckit_to_ralph.py

Converts Spec-Kit projects to Ralph format:

```bash
python scripts/speckit_to_ralph.py ./speckit-project ./ralph-output
```

Converts:
- `constitution.md` → Quality standards in PROMPT.md
- `spec.md` → Mission and specs/requirements.md
- `plan.md` → Technical requirements in PROMPT.md
- `tasks.md` → @fix_plan.md with phases
- `data-model.md` → specs/data-models.md

## Spec-Kit Integration

Use [GitHub's Spec-Kit](https://github.com/github/spec-kit) for planning, then Ralph for implementation:

```bash
# 1. Use Spec-Kit for planning
specify init my-app --ai claude
cd my-app && claude

/speckit.constitution Focus on quality, testing, UX
/speckit.specify Build a todo app with projects and tasks
/speckit.plan Use React, TypeScript, Express, PostgreSQL
/speckit.tasks

# 2. Convert to Ralph format
python scripts/speckit_to_ralph.py . ./ralph-output

# 3. Run Ralph for autonomous implementation
cd ralph-output && ralph --monitor
```

## Example Output

For "Create a PRD for a note-taking CLI":

**PROMPT.md:**
```markdown
# Quicknote Development Instructions

You are Ralph, an autonomous AI development agent building a CLI note-taking tool.

## Your Mission
Build a command-line tool for quickly capturing notes as markdown files...

## Technical Requirements
| Component | Technology |
|-----------|------------|
| Runtime | Node.js 18+ |
| Language | TypeScript |
...

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
...
```

**@fix_plan.md:**
```markdown
# Fix Plan - Quicknote

## Phase 1: Foundation
- [ ] Initialize Node.js project with TypeScript
- [ ] Set up Commander.js CLI structure
...

## Phase 2: Core Commands
- [ ] Implement `add` command
- [ ] Implement `list` command
...
```

## Tips

1. **Be specific about your tech stack** - The more details you provide, the better the generated specs
2. **Review and customize** - Generated PRDs are starting points; adjust to your needs
3. **Use the validator** - Run validation before starting Ralph to catch issues early
4. **Start with MVP** - List what's out of scope to keep initial development focused

## License

MIT License - Feel free to modify and redistribute.

---

# 中文版

# Ralph PRD 生成器

一个用于 Claude Code 的 Agent 技能，可生成针对 [Ralph](https://github.com/anthropics/ralph) 自主开发优化的产品需求文档（PRD）和规格说明。

---

## 概述

此技能帮助您将应用创意转换为完整的 Ralph 兼容项目结构：

- **PROMPT.md** - 包含 RALPH_STATUS 块的主要开发指令
- **@fix_plan.md** - 分阶段的优先级任务清单
- **specs/*.md** - 详细的技术规格说明
- **@AGENT.md** - 构建和运行说明

## 安装

### Claude Code（全局安装）

```bash
# 复制到用户技能目录
cp -r ralph-prd-generator ~/.claude/skills/
```

### Claude Code（项目特定）

```bash
# 复制到项目技能目录
cp -r ralph-prd-generator .claude/skills/
```

### Claude.ai（Pro/Max/Team/Enterprise）

1. 将技能目录打包成 zip 文件
2. 进入 Settings > Features
3. 上传 .zip 文件

### Claude API

```python
import anthropic

client = anthropic.Anthropic()

skill = client.beta.skills.create(
    display_title="Ralph PRD Generator",
    files=files_from_dir("./ralph-prd-generator"),
    betas=["skills-2025-10-02"]
)
```

## 使用方法

### 基本用法

只需描述您的应用创意：

```
为一个带有连续打卡、提醒和统计功能的习惯追踪应用创建 PRD。
```

Claude 将会：
1. 如需要则提出澄清问题
2. 生成包含开发指令的 PROMPT.md
3. 生成包含分阶段任务的 @fix_plan.md
4. 生成包含技术细节的 specs/ 文件

### 使用现有需求

```
我有这些需求，请转换为 Ralph 格式：

- 使用邮箱/密码的用户认证
- 任务的增删改查操作
- 带图表的仪表板
- 使用 React 和 Express 构建
```

### 验证现有项目

```
验证 ./my-project 目录下的 Ralph 项目结构
```

## 技能结构

```
ralph-prd-generator/
├── SKILL.md                           # 主要指令
├── README.md                          # 本文件
├── references/
│   ├── prd-templates.md               # 按项目类型的完整模板
│   ├── task-breakdown.md              # 任务粒度模式
│   ├── ralph-format.md                # 文件格式规范
│   └── speckit-integration.md         # Spec-Kit 集成指南
└── scripts/
    ├── validate_ralph_project.py      # 项目结构验证器
    └── speckit_to_ralph.py            # Spec-Kit 到 Ralph 转换器
```

## 功能特性

### PRD 生成

| 功能 | 描述 |
|------|------|
| 需求收集 | 对不完整的创意提出澄清问题 |
| PROMPT.md 生成 | 创建包含 RALPH_STATUS 的开发指令 |
| 任务分解 | 生成包含 5-30 分钟任务的分阶段 @fix_plan.md |
| 规格生成 | 创建数据模型、API 端点、UI 组件 |
| 验证 | 在交付前检查项目结构 |

### 项目模板

| 项目类型 | 生成的规格文件 |
|----------|----------------|
| Web 应用 | data-models.md, api-endpoints.md, ui-components.md |
| CLI 工具 | commands.md |
| REST API | data-models.md, api-endpoints.md, authentication.md |

### 脚本工具

#### validate_ralph_project.py

验证 Ralph 项目结构：

```bash
python scripts/validate_ralph_project.py ./my-project
```

检查项目：
- 必需文件是否存在（PROMPT.md, @fix_plan.md）
- RALPH_STATUS 和 EXIT_SIGNAL 块是否存在
- 阶段结构和任务标记是否正确
- specs/ 目录内容

#### speckit_to_ralph.py

将 Spec-Kit 项目转换为 Ralph 格式：

```bash
python scripts/speckit_to_ralph.py ./speckit-project ./ralph-output
```

转换内容：
- `constitution.md` → PROMPT.md 中的质量标准
- `spec.md` → 任务说明和 specs/requirements.md
- `plan.md` → PROMPT.md 中的技术要求
- `tasks.md` → 带阶段的 @fix_plan.md
- `data-model.md` → specs/data-models.md

## Spec-Kit 集成

使用 [GitHub 的 Spec-Kit](https://github.com/github/spec-kit) 进行规划，然后用 Ralph 实现：

```bash
# 1. 使用 Spec-Kit 进行规划
specify init my-app --ai claude
cd my-app && claude

/speckit.constitution 专注于代码质量、测试、用户体验
/speckit.specify 构建一个带有项目和任务的待办应用
/speckit.plan 使用 React、TypeScript、Express、PostgreSQL
/speckit.tasks

# 2. 转换为 Ralph 格式
python scripts/speckit_to_ralph.py . ./ralph-output

# 3. 运行 Ralph 进行自主实现
cd ralph-output && ralph --monitor
```

## 输出示例

对于"为笔记 CLI 工具创建 PRD"：

**PROMPT.md：**
```markdown
# Quicknote 开发指令

你是 Ralph，一个正在构建 CLI 笔记工具的自主 AI 开发代理。

## 你的任务
构建一个用于快速捕获笔记为 markdown 文件的命令行工具...

## 技术要求
| 组件 | 技术 |
|------|------|
| 运行时 | Node.js 18+ |
| 语言 | TypeScript |
...

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
...
```

**@fix_plan.md：**
```markdown
# 修复计划 - Quicknote

## 阶段 1：基础
- [ ] 使用 TypeScript 初始化 Node.js 项目
- [ ] 设置 Commander.js CLI 结构
...

## 阶段 2：核心命令
- [ ] 实现 `add` 命令
- [ ] 实现 `list` 命令
...
```

## 使用技巧

1. **明确指定技术栈** - 提供的细节越多，生成的规格越好
2. **审查和自定义** - 生成的 PRD 是起点，请根据需要调整
3. **使用验证器** - 在启动 Ralph 之前运行验证以提前发现问题
4. **从 MVP 开始** - 列出范围外的内容以保持初始开发的专注

## 许可证

MIT 许可证 - 可自由修改和重新分发。
