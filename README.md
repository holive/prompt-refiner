# Prompt Refiner

Improve LLM prompts systematically — using benchmark-backed critique patterns instead of intuition.

If a prompt "works" but still feels mediocre, this is how you close the gap.

---

## What This Is

Prompt Refiner is a structured method for improving:

* One-line prompts
* System messages
* SKILL.md files
* Agent instructions
* Any text that guides an LLM

It avoids the common trap of asking a model to judge its own work holistically (which research shows fails). Instead, it:

1. Breaks the prompt into parts
2. Critiques each part independently
3. Produces testable revisions
4. (Optionally) uses a second model to remove self-bias

---

## Why This Exists

LLMs reliably stop at "good enough."

And the intuitive fix — "review your answer" — often makes things worse.

Across multiple benchmarks:

* Models miss ~64% of their own errors when reviewing holistically
* Same-model self-critique yields minimal gains
* Unguided refinement loops barely improve results
* Guided refinement with external feedback can produce massive gains
* Overthinking beyond ~3 rounds reduces quality
* Self-bias compounds each iteration

The consistent finding:

> Refinement works when grounded in structured critique and external feedback.
> It fails when the model is both generator and judge.

Full citations: [`references/research-sources.md`](references/research-sources.md)

---

# How It Works

The method runs in controlled rounds.
Each round has a purpose. Each round stops before continuing.

---

## Step 0 — Size the Task

| Input              | Strategy                        |
| ------------------ | ------------------------------- |
| Short (<5 lines)   | Light pass                      |
| Medium             | Full decomposition              |
| Large (100+ lines) | Sample the weakest 3–5 sections |

---

## Step 1 — Choose Optimization Target

What are you optimizing for?

* Quality
* Determinism
* Token efficiency
* Creativity
* Tool use

Optimization target determines what "better" means.

---

# Round 1 — Decompose

Break the prompt into independent facets:

* Intent
* Constraints
* Context
* Output format
* Examples
* Assumptions
* Failure modes

For each facet:

* Quote the exact problem
* Propose a concrete fix
* Check for constraint conflicts

**Output includes:**

* Revision (or patch / variants / critique-only mode)
* Mandatory test kit:
  * Happy path
  * Edge case
  * Adversarial case

Then stop.

---

# Round 2 — Adversarial Verification

Assume the revision failed.

Ask:

* How would a lazy model interpret this?
* How would a literal model interpret this?
* How would an expert model misinterpret this?
* What implicit knowledge does this rely on?
* What mediocre output is most plausible?

Then stop again.

---

# Round 3 — Ambiguity Detection (Optional)

Simulate three users:

* Expert
* Generalist
* Rushed

If interpretations diverge → ambiguity exists → revise.

---

# Definition of Done

A prompt is complete when:

* Constraints are executable and unambiguous
* No contradictions remain
* Output format enables cross-model consistency
* Test kit covers normal + edge + adversarial
* No high-impact untested risks remain

Not when "we've done 3 rounds."

---

# Output Modes

Not every situation needs a full rewrite.

| Mode                | Use When                        |
| ------------------- | ------------------------------- |
| Full rewrite        | Clear intent, broken structure  |
| Minimal patch       | Mostly good, small fixes needed |
| Variant set (A/B/C) | Key constraints unclear         |
| Critique-only       | Diagnosis before changes        |

---

# Cross-Model Critique (Highest Leverage)

Self-bias is real. Models overrate their own output.

Strongest results come from splitting roles:

**Generator** ≠ **Evaluator**

### Manual Workflow

1. Run Round 1 in Model A
2. Paste output + original prompt into Model B
3. Collect critique
4. Merge based on *testability* (which suggestion is verifiable?)

### Scripted Workflow

```bash
./scripts/cross-critique.sh my-prompt.md
```

Process:
Claude decomposes → Gemini critiques → Claude merges → Gemini verifies

Requirements:

* `claude` CLI
* `gemini` CLI
* Authenticated and in PATH

---

# Where to Use It

## As a Claude Skill

Install:

```
your-skills-directory/
└── prompt-refiner/
```

Triggers automatically when you say things like:

* "Improve this prompt"
* "Why is this output mediocre?"
* "Review my skill"

## As a Manual Method

Works in any environment:

1. Decompose
2. Quote exact gaps
3. Write test kit
4. Adversarial verify
5. (Optional) Cross-model critique

## As a Script

```bash
./scripts/cross-critique.sh prompt.md
./scripts/cross-critique.sh SKILL.md --rounds 2
./scripts/cross-critique.sh prompt.md --output prompt-v2.md
```

---

# Key Design Decisions (Condensed)

**Why decompose instead of holistic review?**
Holistic self-review misses most errors.

**Why mandatory test kits?**
Improvement requires measurable signals.

**Why multiple output modes?**
Forced rewrites can lock in wrong assumptions.

**Why resolve critique conflicts by testability?**
Specificity can be confidently wrong. Verifiability cannot.

**Why exit criteria instead of fixed rounds?**
Some prompts are done immediately. Others need iteration.
Rigid caps degrade quality.

---

# How This Was Built

The skill was written by one model, then independently critiqued by two others.

Each caught structural issues the others missed.

This validated the central principle:

> Separation of generator and evaluator surfaces better improvements than self-review.

---

# File Structure

```
prompt-refiner/
├── SKILL.md
├── scripts/
│   └── cross-critique.sh
├── references/
│   └── research-sources.md
└── README.md
```

---

# License

Use freely.
If you improve it, share findings — iteration is the point.
