---
name: prompt-refiner
description: Iterative prompt and skill revision using research-backed critique patterns. Use when the user wants to improve a prompt, refine a skill's instructions, review system prompts, audit prompt quality, or debug why an LLM interaction isn't producing optimal results. Also triggers when the user says things like "this prompt isn't working well", "make this prompt better", "review my skill", "why is the output mediocre", or "help me get better results from this". Works on any text that instructs an LLM — prompts, skills, system messages, agent instructions.
metadata:
  complements: [prompt-ideator, skill-healthcheck, skill-plan, grammar-checker]
---

# Prompt Refiner

Iteratively improves prompts, skills, and LLM instructions using critique patterns grounded in published benchmarks. Designed to close the gap between "good enough" and "optimal" LLM output.

## Core Principle

**The value of iteration depends on the quality and source of the feedback signal, not on the number of loops.** When critique comes from external grounding (a different model, a checklist, test cases, a rubric), refinement reliably improves quality. When the same model judges its own work without external anchoring, performance frequently degrades due to self-bias.

## Execution Rules

1. **One round at a time.** Execute only the current round, output the result, and stop. Ask the user before proceeding. Do not simulate future rounds or critique your own revision in the same response.
2. **Do no harm.** If the original prompt is clear, concise, and lacks obvious failure modes, say so. Do not add complexity to fill facets. A simple prompt that works beats a heavily engineered one that doesn't.
3. **No leaked implementation details.** Do not include references to scripts, CLIs, orchestration tools, or model names in the revised prompt unless the original already contains them.
4. **Require evidence, not labels.** Don't name-drop research or methodologies in your output. Demonstrate improvement through concrete before/after changes and test cases. Research references are for this skill's internal guidance, not for the user-facing revision.

## Step 0: Size the Task

Before decomposing, assess what you're working with:

- **Short prompt (under ~5 lines):** Light pass — check Intent + Output format + one test case. Skip the full facet list.
- **Medium prompt or system message:** Full decomposition using the facets below.
- **Large skill or instruction set (100+ lines):** Sample-based critique — identify the 3–5 weakest sections and target those. Don't rewrite the whole document unless asked.

## Step 1: Choose an Optimization Target

Ask (or infer) what the user is optimizing for. Default is quality-first.

- **Quality-first** (default): maximize correctness, reduce ambiguity, close failure modes
- **Token-light**: preserve correctness while minimizing prompt length
- **Deterministic**: maximize output consistency across runs
- **Creative**: maximize range, voice, and unexpected outputs — deprioritize rigid constraints
- **Tool-using**: optimize for tool calls, structured output, or agent workflows

This shapes which facets matter most and how aggressively to constrain.

## Round 1: Decompose

Don't evaluate the prompt as a whole — this triggers the 64.5% blind spot. Decompose into components and critique each independently.

**Apply only facets relevant to the input. If a facet reveals no gaps, skip it.** For each flagged facet, you must provide: (1) the exact ambiguous phrase or gap, quoted, (2) why it's a problem in 1–2 sentences, (3) a concrete replacement or fix.

### Core Facets (all prompt types)

1. **Intent** — What is this actually asking for? Could a model reasonably misinterpret the objective?
2. **Constraints** — What boundaries exist? Are they explicit or assumed? Missing constraints are the #1 source of "good enough" outputs.
3. **Context provided** — What background does the model get? What's missing that the author takes for granted?
4. **Examples** — Are there examples? Do they cover edge cases or only the happy path?
5. **Output format** — Is the expected shape specified? Underspecified format leads to the model's default.
6. **Failure modes** — What's the simplest wrong answer this allows? What would a lazy interpretation produce?
7. **Assumptions** — What does this assume about the model's knowledge, context, or capabilities?

### Skill-Specific Facets (when reviewing SKILL.md or system prompts)

8. **Trigger accuracy** — Does the description cover all cases where this should fire?
9. **Instruction clarity** — Could a model follow these without the original author's context?
10. **Progressive disclosure** — Is the body concise with clear pointers to reference files? (Meaning: metadata loads first, then skill body, then bundled references only when needed.)
11. **Edge case coverage** — What inputs would break the assumptions?

### Constraint Conflict Check

After facet analysis, list any instructions that contradict each other (e.g., "be concise" vs "be thorough," "don't ask questions" vs "clarify requirements"). Resolve conflicts using this priority: **user's core goal > safety > output schema > style**.

### Round 1 Output

Choose the appropriate output mode:

- **Full rewrite** — when intent and constraints are sufficiently clear
- **Minimal patch** — when the prompt is mostly good; show only the specific lines changed
- **Variant set** — when key constraints are unknown; produce 2–3 options (A/B/C) that make different tradeoffs, labeled with what each prioritizes
- **Critique-only** — when the user explicitly wants diagnosis before any rewriting

Format:

```
## Round 1

### Changes Made (or: Diagnosis)
- [Facet]: [Exact phrase quoted] → [Fix and why]

### [Revised Prompt / Patch / Variants / Diagnosis]
[The actual content]

### Test Kit
- Happy path: [input] → [expected output shape]
- Edge case: [input] → [expected output shape]
- Adversarial: [input] → [expected behavior]
```

The test kit is mandatory. It's the external grounding anchor that makes this revision testable even without a second model.

After outputting, **stop and ask**: "Want to proceed to Round 2 (Verification), or test this first?"

---

## Round 2: Verify

Answer these adversarial questions about the revision. The framing is deliberately skeptical to counteract self-bias:

1. **Assume this prompt failed to produce a great answer. What is the most likely reason why?**
2. **Interpret this prompt as three personas**: a lazy model (does the minimum), an overly literal model (follows the letter, ignores the spirit), and a domain expert model (knows too much, over-optimizes). Do their outputs diverge? Where?
3. **What implicit knowledge does this prompt rely on?** What would someone need to already know for this to work?
4. **What's the most plausible mediocre output?** Not absurd failure — the realistic "good enough" result that technically satisfies the prompt but misses the user's actual goal.

If any answer reveals a gap, fix it. Update the test kit if the gap suggests a missing test case.

After outputting, **stop and ask**: "Want to proceed to Round 3, or test this?"

---

## Round 3 (optional): Ambiguity Detection

Simulate three users encountering this prompt for the first time: a domain expert, a generalist, and someone in a rush. Generate each interpretation. If they diverge, the prompt is ambiguous — the divergence points show exactly where. Interpretations must be genuinely different (leading to different outputs), not paraphrases of each other.

---

## Definition of Done

Stop refining when ALL of these are true:

1. All constraints in the prompt are **executable** (verifiable, unambiguous, non-contradictory)
2. The test kit has at least one happy path, one edge case, and one adversarial test
3. The output format is specified clearly enough that two different models would produce structurally similar results (unless creative intent requires otherwise)
4. No remaining concerns are both high-impact and untested

Stop early (even at Round 0) if the prompt already meets these criteria. Continue past Round 3 only if a remaining concern is high-impact, testable, and the user agrees.

---

## Cross-Model Critique

Everything above works with a single model anchored to checklists and test kits. But the research is clear: **using a separate model as critic produces substantially better results.**

If the user has access to a second model (Gemini, ChatGPT, etc.):
- Suggest they paste the Round 1 output into the second model with a critique prompt
- The user pastes the response back, and you merge findings
- Resolve conflicts by **testability**: prefer the critique that leads to a clearer, verifiable instruction that passes the test kit — not merely the most detailed or specific one

For automated cross-model orchestration in Claude Code environments, see `scripts/cross-critique.sh`.

---

## What NOT to Do

- **Don't run all rounds in one shot** — stop after each round
- **Don't invent problems** — if the prompt is good, say so
- **Don't force all facets** — skip those with no gaps
- **Don't always force a full rewrite** — patches, variants, and critique-only are valid modes
- **Don't name-drop research in your output** — demonstrate improvement, don't cite papers
- **Don't strip creativity from creative prompts** — adapt critique style to intent
- **Don't fill facets with generic commentary** ("needs more clarity") — quote the exact problem, explain why, provide replacement text
- **Don't leak orchestration details** into revised prompts

## Examples: Before and After

### Example 1: Short prompt (light pass)

**Before:**
```
Review this code and tell me if there are any issues.
```

**Round 1 (light pass — Intent + Output format + test case):**
- **Intent**: "Review" and "issues" are vague. Bugs? Style? Security? Performance?
- **Output format**: Unspecified → will produce a wall of mixed-priority bullet points.

**After:**
```
Review this code for correctness bugs and security issues only. For each issue:
1. Quote the problematic line(s)
2. Explain what could go wrong in production
3. Suggest a fix

If no correctness or security issues exist, say "No issues found."
```

**Test kit:**
- Happy path: code with an obvious null pointer → catches it, quotes line, suggests fix
- Edge case: code that's correct but has style issues → says "No issues found"
- Adversarial: code with a subtle race condition → identifies it despite complexity

### Example 2: Long skill (sample-based critique)

**Before:** A 200-line SKILL.md with 15 sections.

**Round 1 (sample-based — target weakest sections):**
- Identified 3 sections with gaps: trigger description too narrow, output format buried at line 180, no edge case handling for empty input.
- Remaining 12 sections: adequate, no changes.
- Produced minimal patches for the 3 weak sections only.

Note what transfers across examples: the decomposition method and test kit requirement. What doesn't transfer: the specific facets flagged, the output mode chosen, the level of rewrite.

## References

- `scripts/cross-critique.sh` — Cross-model orchestration for environments with a second CLI model
- `references/research-sources.md` — Papers and benchmarks backing each technique in this skill
