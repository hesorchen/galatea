# Rubric — galatea 发布就绪

> Phase 0 与用户共创，2026-06-26 确认**冻结**。Phase 1 只读不改。

## 目标
- 用户目标：用 galatea 方法论优化 galatea 项目自身，达到「可开源发布」的质量。
- 可验证目标：SKILL.md / engine / templates / README* 通过下列全部 blocker + high 裁判标准，且稳定性验证通过。
- 任务类型：客观可测为主（grep / bash -n / 路径存在性 / 交叉比对）+ 少量主观开放（可读性，由独立 Judge agent 打分）。

## 裁判标准
| # | 维度 | 可勾选标准 | 裁判怎么取证 | 阈值 | 严重度 |
|---|------|-----------|-------------|------|--------|
| R1 | 模板通用性 | 所有 `templates/*.template.md` 为领域无关占位符，无任何具体任务残留 | `grep -riE 'AUC\|best\.pt\|GCF\|test_items_frozen\|score1\|cuid\|population_segments\|521k\|train_v5\|eval_on_frozen'` templates/ + 人工通读每个模板 | grep 命中 0；每个模板只剩通用占位符 + 中性示例标注 | **blocker** |
| R2 | 启动命令可跑通 | README/SKILL 给的启动命令路径与项目真实位置自洽，不写死不存在路径 | 核对命令里每个路径是否存在 / 相对自洽（已知 SKILL.md 启动段写死 `~/.claude/skills/galatea/engine/loop.sh`，项目实际在 `~/claude_space/projects/galatea/`） | 命令能照抄执行，路径真实或有明确安装说明 | high |
| R3 | 跨文件一致性 | SKILL / README / README.en / templates 间：产物文件清单、三旋钮命名、单轮流程步骤、目录结构无矛盾 | 四处交叉比对清单与命名 | 0 处矛盾 | high |
| R4 | 文档无悬空引用 | 文档引用的所有文件/路径真实存在，无残留 `[NEEDS CLARIFICATION]` / TODO / 未填占位符 | grep 引用路径逐一核对存在性；grep `NEEDS CLARIFICATION\|TODO\|<.*>` | broken 引用 0、残留标记 0 | high |
| R5 | 脚本健壮性 | `engine/*.sh` 过 `bash -n`；关键边界（GOAL_DIR 非 git 仓 / 缺 finalize-prompt / 空或缺 pending）不致命崩且行为符合文档 | `bash -n` 三脚本 + 读码核对每条文档承诺有对应实现 + 构造最小 smoke（fake goal dir + 假 iterate-prompt 回显 echo）验证 loop.sh 不立即崩 | `bash -n` 全过 + smoke 不崩 + 文档承诺行为代码里都有 | high |
| R6 | README↔实现对齐 | README「设计要点」每条都能在 SKILL/engine 找到对应落地，无「宣传了但没实现」 | 逐条 README bullet → 找 SKILL/engine 对应 | 每条有落地；缺则改文档（客观，自改），补功能属主观→提案 | medium |
| R7 | 英文 README 同步 | README.en.md 结构与关键要点对齐 README.md，无缺漏 / 过时 | 章节级 + 要点级比对 | 关键要点无缺漏 | medium |
| R8 | 整体可读自包含 | 新用户只读 README + SKILL 能理解「是什么 / 何时用 / 怎么跑」，无前后矛盾 | 派「新用户」视角 Judge sub-agent 通读，列出看不懂 / 矛盾点 | 无 blocker 级理解障碍 | medium |

> 严重度：blocker / high / medium / low。R1 + R2/R3/R4/R5 必修才算达标。

## 三个旋钮
- **自主度**：② 客观项自改 + 主观项提案。
  - 自改（客观）：模板去污、路径修正、文件清单/命名不一致、bash 语法错、broken 引用、英文同步缺漏。
  - 仅提案（主观，写 `pending.md`）：README 措辞优化、是否新增章节、是否新增功能、设计取舍。
- **影响边界（本任务额外，叠加 SKILL.md 全局安全红线）**：
  - 额外禁止的目录：只在 `~/claude_space/projects/galatea/` 内动手，禁碰外层 claude_space 任何文件。
  - 额外禁止的操作：禁删文件（可改写；确需删除→写 pending）；禁碰 `LICENSE`；禁 `git push`、禁碰 claude_space 外层 git（不在外层 add/commit）；禁系统级（不装 shellcheck 等软件、不 kill 进程）；禁外发（邮件/对外 API 写/付费）。
  - 明确授权的外发/越界操作：无（联网**读**允许，如 web 查 shell 最佳实践）。
- **收敛后行为**：① 停。全 blocker/high 达标 + 稳定性验证通过 → 写 `final-review.md` + `.done`，停机等用户复核。

## Scope 收口
- **范围内**：`SKILL.md` / `engine/*.sh` / `templates/*` / `README.md` / `README.en.md` 的内容质量与一致性。
- **范围外**：不改 `LICENSE`；不真跑一个完整的无人值守业务任务（dogfood，本目标只到「bash -n + 最小 smoke 可跑通」级别）；不新增重大功能（只在现有设计内修缺陷 + 对齐文档↔实现）；不动 claude_space 外层任何文件。

## 达标定义
- 所有 blocker(R1) + high(R2/R3/R4/R5) 项通过，且稳定性验证（对抗式验收）通过 → 达标。
- medium(R6/R7/R8)：客观缺漏（同步缺、broken）必修；主观增补只提案不强制达标。

## 冻结前质量自检（已逐条通过）
- [x] 无残留 `[NEEDS CLARIFICATION]` 标记
- [x] 每条标准可裁判（grep / bash -n / 路径核对 / Judge agent 取证）
- [x] 每条都有阈值，无「适量 / 明显 / 差不多」模糊词
- [x] 严重度已标注，至少一条 blocker（R1）
- [x] scope 收口（范围内/外都写清）
- [x] 标准之间无相互矛盾
- [x] 三个旋钮都已设定
