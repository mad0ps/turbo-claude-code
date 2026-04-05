---
name: model-selection
description: Use when dispatching subagents via Agent tool — guides model tier selection (Haiku/Sonnet/Opus) based on task complexity to minimize cost
---

# Model Selection for Subagents

No global model override is set. Choose model per-task using the `model:` param on Agent tool.

## Decision Flow

```dot
digraph model {
    rankdir=TB;
    node [shape=diamond];

    q1 [label="Search, docs,\nsingle-file lookup?"];
    q2 [label="Code impl, review,\nmulti-file, tests?"];
    q3 [label="Architecture, security,\n5+ file interdeps?"];

    node [shape=box];
    haiku [label="Haiku (default)\nDon't specify model"];
    sonnet [label="Sonnet\nmodel: \"sonnet\""];
    opus [label="Opus\nmodel: \"opus\""];

    q1 -> haiku [label="yes"];
    q1 -> q2 [label="no"];
    q2 -> sonnet [label="yes"];
    q2 -> q3 [label="no"];
    q3 -> opus [label="yes"];
    q3 -> sonnet [label="no, default up"];
}
```

## Quick Reference

| Model | When | Cost vs Haiku |
|-------|------|---------------|
| **Haiku** | Explore, search, grep, docs, simple lookup, episodic-memory, claude-code-guide | 1x |
| **Sonnet** | Multi-file impl, code review, Plan (task decomp), test writing, build errors | ~4x |
| **Opus** | System architecture, security analysis, complex debugging, 5+ file spans | ~19x |

## Escalation

Bad subagent result → escalate model first, rewrite prompt second.

```
Haiku fails → model: "sonnet"
Sonnet fails → model: "opus"
Opus fails → rethink approach
```

90% Haiku · 5% Sonnet · 5% Opus target.
