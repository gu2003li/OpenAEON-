import { describe, expect, it } from "vitest";
import { resolveIrcInboundTarget } from "./monitor.js";

describe("irc monitor inbound target", () => {
  it("keeps channel target for group messages", () => {
    expect(
      resolveIrcInboundTarget({
        target: "#openaeon",
        senderNick: "alice",
      }),
    ).toEqual({
      isGroup: true,
      target: "#openaeon",
      rawTarget: "#openaeon",
    });
  });

  it("maps DM target to sender nick and preserves raw target", () => {
    expect(
      resolveIrcInboundTarget({
        target: "openaeon-bot",
        senderNick: "alice",
      }),
    ).toEqual({
      isGroup: false,
      target: "alice",
      rawTarget: "openaeon-bot",
    });
  });

  it("falls back to raw target when sender nick is empty", () => {
    expect(
      resolveIrcInboundTarget({
        target: "openaeon-bot",
        senderNick: " ",
      }),
    ).toEqual({
      isGroup: false,
      target: "openaeon-bot",
      rawTarget: "openaeon-bot",
    });
  });
});
