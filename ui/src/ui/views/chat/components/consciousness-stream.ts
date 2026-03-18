import { html, nothing } from "lit";
import { repeat } from "lit/directives/repeat.js";
import { t } from "../../../../i18n/index.ts";
import type { CognitiveLogEntry } from "../../../types.ts";

export interface ConsciousnessStreamProps {
  log?: CognitiveLogEntry[];
  active?: boolean;
  docked?: boolean;
  muteWhenSidebarOpen?: boolean;
  sidebarOpen?: boolean;
}

export function renderConsciousnessStream(props: ConsciousnessStreamProps) {
  if (!props.active || !props.log || props.log.length === 0) {
    return nothing;
  }
  if (props.muteWhenSidebarOpen && props.sidebarOpen) {
    return nothing;
  }

  const sortedLog = [...props.log].sort((a, b) => b.timestamp - a.timestamp);
  const deliberate = sortedLog.filter((entry) => entry.type === "deliberation");
  const deliberateVisible = deliberate.slice(0, 12);
  const deliberateCollapsed = deliberate.slice(12);
  const nonDeliberate = sortedLog.filter((entry) => entry.type !== "deliberation");
  const renderEntries = (entries: CognitiveLogEntry[]) =>
    repeat(
      entries,
      (entry) => entry.timestamp + entry.type,
      (entry) => html`
        <div class="consciousness-entry ${entry.type}">
          <div class="consciousness-entry-meta">
            <span class="consciousness-type">${entry.type.toUpperCase()}</span>
            <span class="consciousness-time">${new Date(entry.timestamp).toLocaleTimeString([], { hour12: false, hour: "2-digit", minute: "2-digit", second: "2-digit" })}</span>
          </div>
          <div class="consciousness-content">${entry.content}</div>
          ${entry.metadata?.focus ? html`<div class="consciousness-focus">FOCUS: ${entry.metadata.focus}</div>` : nothing}
          ${
            entry.metadata && typeof entry.metadata.eventId === "string"
              ? html`<div class="consciousness-focus">EVENT: ${entry.metadata.eventId}</div>`
              : nothing
          }
          ${entry.metadata?.pivot ? html`<div class="consciousness-pivot">PIVOT: ${entry.metadata.pivot}</div>` : nothing}
        </div>
      `,
    );

  return html`
    <section class="consciousness-stream aeon-glass aeon-entry-anim ${props.docked ? "docked" : ""}">
      <div class="consciousness-stream-header">
        <div class="aeon-shushu-pulse" style="width: 8px; height: 8px; background: var(--aeon-cyan);"></div>
        <span class="mono">${t("chat.consciousnessStream") || "CONSCIOUSNESS_STREAM"}</span>
      </div>
      <div class="consciousness-stream-body">
        ${renderEntries(nonDeliberate)}
        ${renderEntries(deliberateVisible)}
        ${
          deliberateCollapsed.length > 0
            ? html`
                <details class="consciousness-collapsed">
                  <summary>${deliberateCollapsed.length} deliberation events folded</summary>
                  <div class="consciousness-collapsed__body">${renderEntries(deliberateCollapsed)}</div>
                </details>
              `
            : nothing
        }
      </div>
    </section>
  `;
}
