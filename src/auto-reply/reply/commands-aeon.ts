import { distillMemory } from "../../agents/tools/memory-distill-tool.js";
import { logVerbose } from "../../globals.js";
import { enqueueSystemEvent } from "../../infra/system-events.js";
import type { CommandHandler } from "./commands-types.js";

/**
 * AEON PROPHET: /seal or /distill command handler.
 * Triggers the memory distillation process to convert MEMORY.md axioms into logic gates in LOGIC_GATES.md.
 */
export const handleAeonSealCommand: CommandHandler = async (params) => {
  const sealRequested =
    params.command.commandBodyNormalized === "/seal" ||
    params.command.commandBodyNormalized.startsWith("/seal ") ||
    params.command.commandBodyNormalized === "/distill" ||
    params.command.commandBodyNormalized.startsWith("/distill ");

  if (!sealRequested) {
    return null;
  }

  if (!params.command.isAuthorizedSender) {
    logVerbose(
      `Ignoring /seal from unauthorized sender: ${params.command.senderId || "<unknown>"}`,
    );
    return { shouldContinue: false };
  }

  const agentId = params.agentId ?? "main";
  const workspaceDir = params.workspaceDir;

  try {
    const result = await distillMemory({
      agentId,
      workspaceDir,
    });

    if (result.status === "success") {
      const line = `✨ Memory Sealed: Extracted ${result.axiomsExtracted} axioms. MEMORY.md reset.`;
      enqueueSystemEvent(line, { sessionKey: params.sessionKey });
      return {
        shouldContinue: false,
        reply: { text: `✅ ${line}` },
      };
    } else if (result.status === "no-change") {
      return {
        shouldContinue: false,
        reply: { text: "ℹ️ Seal skipped: No significant memory markers found or file too small." },
      };
    } else {
      return {
        shouldContinue: false,
        reply: { text: `❌ Seal failed: ${result.error ?? "Unknown error"}` },
      };
    }
  } catch (err) {
    console.error("AEON Seal error:", err);
    return {
      shouldContinue: false,
      reply: { text: `❌ Seal error: ${String(err)}` },
    };
  }
};
