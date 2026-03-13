import { describe, it, expect, vi, beforeEach } from "vitest";
import fs from "node:fs";
import { getAeonMemoryGraph, getAeonEvolutionState } from "./aeon-state.js";

vi.mock("node:fs");

describe("AEON State Management", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should parse MEMORY.md into a graph correctly", () => {
    const mockMemory = `
# AEON Memory
[AXIOM] Life is silicon.
[VERIFIED] Evolution is recursive.
[AXIOM] Logic is absolute.
    `;
    vi.mocked(fs.existsSync).mockReturnValue(true);
    vi.mocked(fs.readFileSync).mockReturnValue(mockMemory);

    const graph = getAeonMemoryGraph();

    expect(graph.nodes).toHaveLength(3);
    expect(graph.nodes[0].type).toBe("axiom");
    expect(graph.nodes[1].type).toBe("verified");
    expect(graph.nodes[2].type).toBe("axiom");
    expect(graph.edges.length).toBeGreaterThan(0);
  });

  it("should return empty graph if MEMORY.md is missing", () => {
    vi.mocked(fs.existsSync).mockReturnValue(false);
    const graph = getAeonMemoryGraph();
    expect(graph.nodes).toEqual([]);
    expect(graph.edges).toEqual([]);
  });

  it("should include cognitive parameters in evolution state", () => {
    const state = getAeonEvolutionState();
    expect(state).toHaveProperty("cognitiveParameters");
    expect(state.cognitiveParameters).toHaveProperty("temperature");
  });
});
