# Research Sources

Each technique in the prompt-refiner skill is grounded in published, benchmarked work. This file maps techniques to their sources so you can verify claims or dig deeper.

## Decompose-then-critique (DECRIM pattern)

**Source:** Amazon Science, EMNLP 2024 — "LLM Self-Correction with DeCRIM: Decompose, Critique, and Refine for Enhanced Following of Instructions with Multiple Constraints"
**Key finding:** Decomposing into sub-constraints before critiquing yielded +7.3% on RealInstruct and +8.0% on IFEval. Using the same model as generator AND critic produced minimal gains — separation is essential.
**Link:** https://assets.amazon.science/54/04/2dd88903469b9c7e2ef48769eb1c/

## Chain of Verification (CoVe)

**Source:** Meta AI, 2023 — "Chain-of-Verification Reduces Hallucination in Large Language Models" (arXiv:2309.11495)
**Key finding:** Generating independent verification questions then answering them doubled precision on Wikidata (0.17→0.36) and reduced hallucinations 50–70% across QA benchmarks.
**Link:** https://arxiv.org/abs/2309.11495

## Self-Consistency over Self-Correction

**Source:** Wang et al., 2022 — "Self-Consistency Improves Chain of Thought Reasoning in Language Models" (arXiv:2203.11171)
**Key finding:** Sampling multiple reasoning paths and voting outperforms iterative self-correction at equivalent token cost. +17.9% on GSM8K, +12.2% on AQuA.
**Link:** https://arxiv.org/abs/2203.11171

## Self-bias and same-model critique failure

**Source:** Huang et al., Google DeepMind, ICLR 2024 — "Large Language Models Cannot Self-Correct Reasoning Yet" (arXiv:2310.01798)
**Key finding:** LLMs cannot reliably self-correct reasoning without external feedback. Many positive published results used weak initial prompts. Pre-hoc prompting (putting critique guidance in the initial prompt) often beats post-hoc self-correction at lower cost.
**Link:** https://arxiv.org/abs/2310.01798

## Cross-model critique rationale

**Source (self-bias):** Studies across 6 LLMs, 4 languages, 3 tasks — models systematically overrate own generations, bias amplifies monotonically over iterations.
**Source (sycophancy):** RLHF-trained models change correct answers when prompted "your answer may be wrong" — creating a toxic feedback loop.
**Practical implication:** Using Model A to generate and Model B to critique breaks both failure modes.

## Cap iterations at 2–3

**Source:** Tsinghua University, ACL 2025 — "Understanding the Dark Side of LLMs' Intrinsic Self-Correction" (arXiv:2412.14959)
**Key finding:** Three cognitive-bias-like failure modes: overthinking (rumination without progress), cognitive overload (2000+ token prompts causing information loss), answer wavering (flipping correct answers during correction).
**Link:** https://arxiv.org/abs/2412.14959

## Blind spot rate (64.5%)

**Source:** Self-Correction Bench, 2025 (arXiv:2507.02778)
**Key finding:** Average 64.5% blind spot rate across 14 models — models detect errors in user input but systematically miss errors in their own output.
**Link:** https://arxiv.org/abs/2507.02778

## NVIDIA RefineBench (guided vs unguided)

**Source:** NVIDIA, November 2025 — RefineBench across 1,000 problems, 11 domains
**Key finding:** Unguided self-refinement: Gemini 2.5 Pro improved just +1.8% over 5 iterations. Guided refinement (explicit external feedback): GPT-4.1 jumped 23.4%→95.5%, Claude Opus 18.7%→98.4%. Bottleneck is error identification, not repair.
**Link:** https://www.emergentmind.com/topics/refinebench

## Evaluator-Optimizer workflow

**Source:** Anthropic, December 2024 — "Building Effective Agents"
**Key finding:** One LLM generates, another evaluates in a loop. Heuristic: use when human feedback demonstrably improves responses AND an LLM can provide meaningful feedback. Start simple, add agentic complexity only when needed.
**Link:** https://www.anthropic.com/research/building-effective-agents
**Code:** https://github.com/anthropics/anthropic-cookbook/tree/main/patterns/agents
