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
