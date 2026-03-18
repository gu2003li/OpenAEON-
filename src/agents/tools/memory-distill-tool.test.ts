import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";
import { afterEach, describe, expect, it } from "vitest";
import { distillMemory } from "./memory-distill-tool.js";

const createdDirs: string[] = [];

async function makeWorkspace(): Promise<string> {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "openaeon-distill-"));
  createdDirs.push(dir);
  return dir;
}

describe("distillMemory", () => {
  afterEach(async () => {
    await Promise.all(
      createdDirs.splice(0).map((dir) => fs.rm(dir, { recursive: true, force: true })),
    );
  });

  it("keeps MEMORY.md content and appends a checkpoint instead of resetting", async () => {
    const workspace = await makeWorkspace();
    const memoryPath = path.join(workspace, "MEMORY.md");
    const logicPath = path.join(workspace, "LOGIC_GATES.md");
    const originalMemory = [
      "# MEMORY",
      "[AXIOM] Keep user outcomes durable.",
      "[VERIFIED] Nightly batch completed.",
      "Other notes.",
      "",
    ].join("\n");
    await fs.writeFile(memoryPath, originalMemory, "utf-8");
    await fs.writeFile(logicPath, "", "utf-8");

    const result = await distillMemory({ workspaceDir: workspace });
    const afterMemory = await fs.readFile(memoryPath, "utf-8");

    expect(result.status).toBe("success");
    expect(afterMemory).toContain("[AXIOM] Keep user outcomes durable.");
    expect(afterMemory).toContain("DISTILLATION_CHECKPOINT");
  });
});
