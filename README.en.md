# Galatea

> A goal-driven autonomous loop skill: give it a goal, first co-design with you what "good/done" means as a checkable rubric, then — once locked — let the agent unattended-iterate: refine, self-grade, prune, verify, closing in round after round until the deliverable meets the bar, converges, or needs your decision.

The name comes from the Pygmalion myth: a sculptor refines an ivory statue, Galatea, against the ideal in his mind until she is good enough — and comes to life. That is exactly what this project does: **define the ideal first (the rubric), then chisel the deliverable against it until it "comes alive".**

## The problem it solves

The hard part of running an agent autonomously toward an **open-ended / subjective** goal isn't model capability — it's the **lack of a judge**. When the agent is both player and referee, it tends to declare fake progress just to satisfy the loop, drifting further off course (the classic autonomous-agent failure mode).

Galatea compresses human involvement down to the **one point that genuinely needs a human** — defining what "good" means. Do that step carefully together, lock it, and the loop never interrupts you again.

## Design highlights

- **Two phases with a hard gate**: Phase 0 co-designs and freezes the rubric with you; Phase 1 runs unattended, reading only that frozen standard.
- **Judge separated from executor**: each round an independent judge agent grades against the rubric; the agent making changes never grades its own work — no self-dealing.
- **Fresh context per round + on-disk memory**: the engine restarts the process each round (fresh context, resistant to context rot); cross-round memory lives entirely in `state.md` / `log.md` on disk.
- **Never blocks**: anything needing a decision goes into `pending.md` and the loop moves on — it never hangs waiting for you.
- **Three knobs**: autonomy (propose-only / auto-fix objective / fully autonomous), impact boundary (directories and operations that are off-limits), post-convergence behavior (stop / tighten and re-sweep / move to next goal).
- **Stagnation circuit breaker**: if no progress (no new commit) for N consecutive rounds, the loop halts itself — no burning the budget spinning in place.
- **Event notifications**: on convergence / needs-decision / circuit-open / repeated failure, it pings you through a channel you configure (e.g. email), so unattended never means out of the loop.
- **Rubric quality self-check before freezing**: a bad rubric is a bad judge and wastes every round, so the rubric itself is checked against a quality checklist before it's locked.
- **Tiered adversarial review**: multi-subagent opposition kicks in only at high-stakes moments (passing a criterion / declaring convergence / getting stuck) — a prosecutor red-team vs. defender for acceptance to catch fake progress, two competing planners cross-critiquing to avoid tunnel vision — while ordinary small-step rounds stay lightweight.
- **Resource maximization within a hard safety line**: it's encouraged to fully leverage available compute (parallel sub-agents), installed skills, MCP servers, and tools instead of reinventing — while an **overriding environment safety line** forbids destructive / irreversible / out-of-scope / outbound actions under unattended, permission-skipped runs; when in doubt it hands the decision back to you.
- **Run report**: on any exit (converged / circuit-open / max-rounds / failed), a `run-report.md` is auto-generated — a markdown process overview (summary + milestone timeline + rubric-progress history + key decisions) so that after an unattended run you can see the whole journey at a glance.

## When to use / not use

**Use it** for tasks that have a goal, a definable notion of "done", and are iterable with feedback — e.g. bringing a set of documents up to a spec, getting a module's test suite fully green, producing a research report with adequate coverage, locating and fixing a reproducible bug, iterating a proposal until it can support a decision.

**Don't use it** for one-off small edits; for purely subjective tasks where no standard can be written (aesthetics / prose style — use "generate N variants and pick" instead); or for high-blast-radius, irreversible operations.

## Usage

1. Invoke it and state your goal.
2. **Phase 0**: the skill spins up a dedicated, **git-managed task directory** for the goal, then works with you to break the goal into a checkable rubric, confirms and freezes it, and generates the per-round `iterate-prompt.md`. (If the goal is to work on an existing repo, it operates inside that repo instead.)
3. **Phase 1**: start the unattended loop with the engine (run it in a persistent environment / tmux so disconnects don't matter). **Run from the galatea project root**:

   ```bash
   bash engine/loop.sh <goal-directory> [max-rounds]
   ```

   The engine repeatedly runs one round with a fresh context; it backs off exponentially on usage limits, halts itself if there's no progress for several rounds, and exits automatically once converged. Each round's output lands in `<goal-directory>/logs/` for post-mortems.
   For notifications, point the `GALATEA_NOTIFY_CMD` env var at your own notify command (see the email example in `engine/notify.sh`).

## Safety

- The unattended loop relies on skipping interactive confirmation (e.g. `--dangerously-skip-permissions`), so **set the impact boundary in Phase 0 first** (no push / no delete / off-limit directories) and run it in an isolated environment.
- By default each round's passing changes are committed via `git commit` as a checkpoint, so a bad round can be reverted.

## Layout

```
galatea/
├─ SKILL.md                  # Core: Phase 0 co-design protocol + Phase 1 loop spec + behavior constraints
├─ engine/
│  ├─ loop.sh                # The outer loop engine (fresh-context restart + usage backoff + convergence exit)
│  ├─ circuit_breaker.sh     # Stagnation circuit breaker: halt after N consecutive rounds with no progress
│  └─ notify.sh              # Key-event notifications (GALATEA_NOTIFY_CMD; includes email example)
├─ templates/                # Starter templates for each output file
│  ├─ rubric.template.md     # Checkable rubric (frozen in Phase 0)
│  ├─ iterate-prompt.template.md   # Per-round instruction (executed repeatedly in Phase 1)
│  ├─ finalize-prompt.template.md  # Post-convergence wrap-up instruction
│  ├─ state.template.md      # Cross-round memory: current state snapshot
│  ├─ log.template.md        # Cross-round memory: append-only round log
│  ├─ pending.template.md    # Items needing your decision
│  ├─ run-report.template.md # Run overview report
│  └─ gitignore.template     # .gitignore for the task directory
├─ README.md                 # Chinese
├─ README.en.md              # English
└─ LICENSE
```

## Status

Draft. Issues / PRs welcome.

## License

MIT
