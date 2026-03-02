#!/usr/bin/env bash
# cross-critique.sh — Cross-model prompt/skill refinement using Claude + Gemini
#
# Grounded in:
# - Amazon DECRIM (EMNLP 2024): same-model critique yields minimal gains
# - Self-bias research: models overrate own output, bias amplifies per iteration
# - NVIDIA RefineBench (Nov 2025): guided feedback → 18.7% to 98.4% improvement
#
# Usage:
#   ./cross-critique.sh <file-to-review> [--rounds 2] [--output revised.md]
#
# Requirements:
#   - Claude Code (claude CLI) — primary model for generation + decomposition
#   - Gemini CLI (gemini) — critic model for verification
#   - Both should be authenticated and available in PATH
#
# The script implements a 2-round loop:
#   Round 1 (Claude): Decompose the prompt into facets, identify gaps
#   Round 1 (Gemini): Independently verify the decomposition + find blind spots
#   Round 2 (Claude): Merge critiques, produce revised version
#   Round 2 (Gemini): Final verification of the revision
#
# Design choice: We use Gemini as the critic (not generator) because
# the research shows the critique role benefits most from model diversity.
# The generator can stay as your primary model since you know its idioms.

set -euo pipefail

# --- Config ---
INPUT_FILE="${1:?Usage: cross-critique.sh <file-to-review> [--rounds N] [--output file]}"
MAX_ROUNDS=2
OUTPUT_FILE=""

# Parse optional args
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rounds) MAX_ROUNDS="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="${INPUT_FILE%.md}-revised.md"
fi

CONTENT=$(cat "$INPUT_FILE")
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== Cross-Model Prompt Refinement ==="
echo "Input: $INPUT_FILE"
echo "Rounds: $MAX_ROUNDS"
echo "Output: $OUTPUT_FILE"
echo ""

# --- Round 1: Claude decomposes ---
echo "--- Round 1: Claude decomposes into facets ---"

cat > "$WORK_DIR/decompose-prompt.txt" <<'DECOMPOSE'
You are reviewing a prompt/skill for quality. Decompose it into these facets
and critique each independently. Do NOT evaluate it holistically first.

For each facet, provide:
- Current state (quote or summarize)
- Gap (what's missing or ambiguous)
- Suggested fix (concrete rewording)

Facets:
1. Intent — Is the goal clear? Could it be misinterpreted?
2. Constraints — What boundaries exist? What's assumed vs explicit?
3. Context — What background is provided? What's missing?
4. Examples — Do they cover edge cases or only happy paths?
5. Output format — Is the expected shape specified?
6. Failure modes — What's the simplest wrong answer this allows?
7. Assumptions — What does this assume about the model's capabilities?

After the facet analysis, generate 5 verification questions:
- What would an LLM misinterpret here?
- Would a different model produce the same interpretation?
- What's the most plausible wrong output?
- What implicit knowledge does this rely on?
- Does this accidentally constrain better answers?

Here is the prompt/skill to review:

DECOMPOSE

# Append the actual content
cat "$WORK_DIR/decompose-prompt.txt" <(echo "$CONTENT") > "$WORK_DIR/claude-input.txt"

# Run Claude decomposition
claude -p "$(cat "$WORK_DIR/claude-input.txt")" > "$WORK_DIR/claude-decomposition.txt" 2>/dev/null

echo "  Claude decomposition complete."

# --- Round 1: Gemini independently critiques ---
echo "--- Round 1: Gemini independently critiques ---"

cat > "$WORK_DIR/gemini-prompt.txt" <<GEMINI_PROMPT
You are an independent critic reviewing a prompt/skill AND a first-pass
analysis of it. Your job is to:

1. Find blind spots the first reviewer missed
2. Challenge any suggested fixes that might make things worse
3. Answer the 5 verification questions from a fresh perspective
4. Flag any self-bias patterns (places where the prompt encourages
   the model to judge its own work without external grounding)

Be specific and concrete. Every observation must include a suggested action.

=== ORIGINAL PROMPT/SKILL ===
$CONTENT

=== FIRST REVIEWER'S ANALYSIS ===
$(cat "$WORK_DIR/claude-decomposition.txt")
GEMINI_PROMPT

# Run Gemini critique
gemini -p "$(cat "$WORK_DIR/gemini-prompt.txt")" > "$WORK_DIR/gemini-critique.txt" 2>/dev/null

echo "  Gemini critique complete."

# --- Round 2: Claude merges and revises ---
echo "--- Round 2: Claude merges critiques and revises ---"

cat > "$WORK_DIR/merge-prompt.txt" <<MERGE_PROMPT
You have two independent reviews of a prompt/skill — one from your own
decomposition, one from a separate model acting as critic.

Your job:
1. Merge the findings. Where they agree, the fix is high-confidence.
2. Where they conflict, side with the more specific critique
   (concrete > vague, with-example > without).
3. Produce the REVISED prompt/skill in full — not a diff, the complete
   revised text ready to use.
4. List remaining concerns that need testing with real examples.

=== ORIGINAL ===
$CONTENT

=== YOUR DECOMPOSITION ===
$(cat "$WORK_DIR/claude-decomposition.txt")

=== INDEPENDENT CRITIC (different model) ===
$(cat "$WORK_DIR/gemini-critique.txt")

Output format:
## Changes Made
- [Facet]: [What changed and why]

## Revised Prompt/Skill
[Complete revised text]

## Remaining Concerns
- [Items needing real-world testing]
MERGE_PROMPT

claude -p "$(cat "$WORK_DIR/merge-prompt.txt")" > "$WORK_DIR/revision.txt" 2>/dev/null

echo "  Claude revision complete."

# --- Optional Round 2: Gemini final check ---
if [[ "$MAX_ROUNDS" -ge 2 ]]; then
  echo "--- Round 2: Gemini final verification ---"

  cat > "$WORK_DIR/final-check.txt" <<FINAL_CHECK
You are doing a final quality check on a revised prompt/skill.
Compare the original and the revision. For each change:
- Is it an improvement? (yes/no/mixed)
- Did the revision introduce new problems?
- Rate overall: [worse / same / better / much better]

Be brief. Flag only real issues, not style preferences.

=== ORIGINAL ===
$CONTENT

=== REVISED ===
$(cat "$WORK_DIR/revision.txt")
FINAL_CHECK

  gemini -p "$(cat "$WORK_DIR/final-check.txt")" > "$WORK_DIR/final-verdict.txt" 2>/dev/null

  echo "  Gemini final check complete."
  echo ""
  echo "=== FINAL VERDICT (Gemini) ==="
  cat "$WORK_DIR/final-verdict.txt"
  echo ""
fi

# --- Extract and save revised content ---
# Save the full revision output (includes changes + revised text + concerns)
cp "$WORK_DIR/revision.txt" "$OUTPUT_FILE"

echo "=== Done ==="
echo "Revision saved to: $OUTPUT_FILE"
echo "Intermediate files in: $WORK_DIR (auto-cleaned on exit)"
echo ""
echo "Next steps:"
echo "  1. Review the revision and remaining concerns"
echo "  2. Test the revised prompt with a concrete example"
echo "  3. If needed, run again: ./cross-critique.sh $OUTPUT_FILE"
