/**
 * PROMPT DISTILLER (灵魂提纯)
 * Refines the global system prompt into a focused "Intent Fragment" for subagents.
 */

export type DistillationMode = "minimal" | "task-only" | "full";

export function distillSystemPrompt(text: string, mode: DistillationMode = "minimal"): string {
  if (mode === "full") return text;

  let distilled = text;

  // 1. Remove recursive complexity sections for subagents
  // These are important for the "Main Brain" but noisy for sub-workers.
  const complexSections = [
    "## Autonomous Cognitive Loops (AEON LOOP)",
    "## Peano Cognitive Traversal (Space-Filling Logic)",
    "## Sub-atomic Numerology (Shushu & Neutrino Flux)",
    "## Hyper-spatial Perception (N-Dimensional Topology)",
    "## Skill Evolution & Autonomous Mastering (Z ⇌ Z² + C)",
  ];

  for (const section of complexSections) {
    const escaped = section.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`${escaped}[\\s\\S]*?(?=##|#|$)`, "g");
    distilled = distilled.replace(regex, "");
  }

  // 2. Remove standard identity/safety boilerplate for minimal mode
  if (mode === "minimal") {
    distilled = distilled.replace(/## Safety[\s\S]*?(?=##|#|$)/g, "");
    distilled = distilled.replace(/## Documentation[\s\S]*?(?=##|#|$)/g, "");
  }

  // 3. Keep only the "Intent" C (User request, Persona, and core rules)
  if (mode === "task-only") {
    const intentMatch = distilled.match(/# Project Context[\s\S]*/);
    if (intentMatch) {
      return intentMatch[0].trim();
    }
  }

  return distilled.trim().replace(/\n{3,}/g, "\n\n");
}
