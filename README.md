<h1 align="center">Galatea</h1>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://docs.claude.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude%20Code-skill-8A63D2" alt="Claude Code"></a>
  <a href="README.en.md"><img src="https://img.shields.io/badge/README-English-informational" alt="English"></a>
</p>

<p align="center"><strong>目标驱动的自主循环 Skill——制定可量化的标准，由 Agent 无人值守反复迭代、自评、剪枝、探索、验证，逐轮逼近直到达成目标。</strong></p>

<p align="center"><em>名字取自皮格马利翁神话里的少女像 Galatea——工匠依照心中的理想反复打磨象牙像，直到她足够完美。</em></p>

## 快速理解

比如你要整理一份散乱的技术文档：告诉 Agent「用 galatea skill 把这份文档优化到符合技术写作规范」。它会先和你一起把「符合规范」拆成一组可勾选的检查项，确认冻结；然后在后台逐轮自动改进、自评、验证，达标后通知你。全程你只在一开始定义"什么叫好"，之后不用管。

## 它解决什么问题

让 Agent 对一个**开放 / 主观目标**长时间自动跑，最大的坑不是模型不够强，而是**没有合格的裁判**：当 Agent 既当运动员又当裁判，它会倾向于宣告虚假进展来满足循环，越跑越偏（经典的自主 agent 漂移）。

Galatea 把 Agent 对用户的依赖压缩到一开始的**任务目标制定**，锁定目标后，就启动多 Agent 自主探索、优化、评估、对抗验证，直到达成目标。

## 怎么工作

```
你 + Galatea（Phase 0）           Galatea 自己（Phase 1）
─────────────────────────        ─────────────────────
目标 ──→ 共创 rubric ──→ 冻结    每轮：读标准 → 裁判打分
                ↓                       ↓
           不再改标准              假设绑定改进 → 验证
                                       ↓
                                  达标？── 否 → 下一轮
                                   ↓ 是
                                  通知你，退出
```

## 设计要点

**核心机制**
- **两阶段硬闸**：Phase 0 与你共创并冻结 rubric；Phase 1 无人值守循环，只读这份冻结标准。
- **裁判与执行分离**：每轮由一个独立裁判 agent 按 rubric 打分，做改动的 agent 不给自己打分——杜绝放水。
- **每轮全新上下文**：循环由外层引擎重启进程（fresh context，抗上下文污染），跨轮记忆全靠磁盘上的 `state.md` / `log.md`。

**护栏**
- **rubric 冻结前自检**：烂标准 = 烂裁判 = 整轮白烧，冻结前先过质量清单。
- **停滞熔断**：连续多轮无进展（无新 commit）自动停机，防止空转烧光预算。
- **安全红线**：无人值守 + 跳过权限下，绝不做破坏性 / 不可逆 / 越界 / 外发操作。
- **不打断**：需要决策的写入 `pending.md` 继续，绝不挂起等人。

**效率**
- **资源最大化**：鼓励充分调用算力（并行子 agent）、已装 skill、MCP、工具，不重复造轮子。
- **分级对抗**：默认轻量单裁判；只在高风险节点（判达标 / 宣告收敛 / 卡死）才升级多 sub-agent 对抗，不烧冤枉钱。

**可观测**
- **运行总览**：任何方式结束后自动生成 `run-report.md`（任务流转图 + 逐轮状态 + rubric 流转 + 关键决策），无人值守跑完一张图看清全程。
- **关键事件通知**：收敛 / 需决策 / 熔断 / 连续失败时，通过你配置的通道主动通知。

**三个旋钮**：自主度（只提案 / 客观自改 / 全自动）、影响边界（禁碰目录与操作）、收敛后行为（停 / 精修 / 转目标）。每次跑都要定。

## 适用 / 不适用

**适用**：有目标、能定义「合格」、可迭代有反馈的任务——把一批文档优化到符合规范、把模块测试全部跑绿、产出一份覆盖到位的调研报告、定位并修掉一个可复现 bug、把一份方案迭代到能支撑决策。

**不适用**：一次性小改；标准根本写不出来的纯主观任务（审美 / 文风，应改用「生成 N 个变体让人挑」）；高破坏性不可回退的操作。

## 安装

把下面这段话整段复制，发给你的 Agent（如 Claude Code），它会自动克隆并装好这个 skill：

> 帮我安装 Galatea skill：把 https://github.com/hesorchen/galatea.git 克隆到 `~/.claude/skills/galatea`，完成后提醒我重启会话即可调用。

或者手动一行搞定：

```bash
git clone https://github.com/hesorchen/galatea.git ~/.claude/skills/galatea
```

装完**重启会话**（skill 列表在启动时扫描目录），之后说「galatea」或直接描述一个目标即可触发。

## 用法

1. 发起调用并说明目标。
2. **Phase 0**：Skill 会为本目标新建一个 **git 管理的专属任务目录**，然后和你一起把目标拆成可裁判的 rubric，确认并冻结，生成单轮指令 `iterate-prompt.md`。（若目标是改造已有仓库，则在该仓库内工作。）
3. **Phase 1**：用引擎启动无人值守循环（建议跑在常驻环境 / tmux 里，断连不影响）。**在 galatea 项目根目录执行**：

   ```bash
   bash engine/loop.sh <目标专属目录> [最大轮数]
   ```

   引擎会反复以全新上下文执行单轮指令；撞用量上限自动指数退避，连续多轮无进展自动熔断停机，收敛后自动退出。每轮输出落 `<目标专属目录>/logs/` 便于复盘。
   关键事件通知：设环境变量 `GALATEA_NOTIFY_CMD` 指向你的通知命令即可（见 `engine/notify.sh` 内的邮件示例）。

## 安全提醒

- 无人值守循环依赖跳过交互式确认（如 `--dangerously-skip-permissions`），**务必先在 Phase 0 划清影响边界**（禁 push / 禁删 / 禁碰的目录），并在隔离环境中运行。
- 默认每轮通过的改动会 `git commit` 作为 checkpoint，跑坏了可回退。

## 目录结构

```
galatea/
├─ SKILL.md                  # 核心：Phase 0 共创协议 + Phase 1 循环规范 + 行为约束
├─ engine/
│  ├─ loop.sh                # 外层循环引擎（fresh context 重启 + 用量退避 + 收敛退出）
│  ├─ circuit_breaker.sh     # 停滞熔断：连续多轮无进展自动停机
│  └─ notify.sh              # 关键事件通知（GALATEA_NOTIFY_CMD，内含邮件示例）
├─ templates/                # 各产出文件的初始模板
│  ├─ rubric.template.md     # 可裁判标准（Phase 0 冻结）
│  ├─ iterate-prompt.template.md   # 单轮指令（Phase 1 反复执行）
│  ├─ finalize-prompt.template.md  # 收敛后收尾指令
│  ├─ state.template.md      # 跨轮记忆：当前状态
│  ├─ log.template.md        # 跨轮记忆：逐轮日志
│  ├─ pending.template.md    # 需你决策的事项
│  ├─ run-report.template.md # 运行总览报告
│  └─ gitignore.template     # 任务目录的 .gitignore
├─ README.md
├─ README.en.md              # 英文版
└─ LICENSE
```

## 状态

v1.0.0。欢迎 issue / PR。

## License

MIT
