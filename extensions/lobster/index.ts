import type {
  AnyAgentTool,
  OpenAEONPluginApi,
  OpenAEONPluginToolFactory,
} from "../../src/plugins/types.js";
import { createLobsterTool } from "./src/lobster-tool.js";

export default function register(api: OpenAEONPluginApi) {
  api.registerTool(
    ((ctx) => {
      if (ctx.sandboxed) {
        return null;
      }
      return createLobsterTool(api) as AnyAgentTool;
    }) as OpenAEONPluginToolFactory,
    { optional: true },
  );
}
