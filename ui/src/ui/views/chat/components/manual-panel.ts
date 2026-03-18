import { html, nothing } from "lit";
import { t } from "../../../../i18n/index.ts";
import type {
  ChatManualMode,
  ChatManualSection,
  ChatManualState,
  ManualRuntimeSnapshot,
} from "../../../types.ts";
import type { ChatProps } from "../../chat.ts";

type RenderManualParams = {
  manualState: ChatManualState;
  manualRuntime: ManualRuntimeSnapshot;
  props: ChatProps;
};

function renderSnapshot(runtime: ManualRuntimeSnapshot) {
  return html`
    <div class="chat-manual__snapshot">
      <div class="chat-manual__snapshot-title">${t("chat.manualSnapshotTitle") || "Runtime Snapshot"}</div>
      <div class="chat-manual__snapshot-grid">
        <div class="chat-manual__snapshot-item">
          <span>${t("chat.sidebarDelivery") || "delivery"}</span>
          <strong>${runtime.delivery.state}</strong>
        </div>
        <div class="chat-manual__snapshot-item">
          <span>${t("chat.sidebarPersisted") || "persisted"}</span>
          <strong>${runtime.delivery.persistedAt ? new Date(runtime.delivery.persistedAt).toLocaleTimeString() : "pending"}</strong>
        </div>
        <div class="chat-manual__snapshot-item">
          <span>${t("chat.manualSnapshotEternal") || "eternal"}</span>
          <strong>${runtime.eternalMode.enabled ? "on" : "off"} · ${runtime.eternalMode.source}</strong>
        </div>
        <div class="chat-manual__snapshot-item">
          <span>${t("chat.manualSnapshotFractal") || "fractal"}</span>
          <strong>d${runtime.fractalState.depthLevel} · ${runtime.fractalState.formulaPhase}</strong>
        </div>
      </div>
      <p class="chat-manual__why">
        ${
          t("chat.manualWhy") ||
          "Visual state is driven by real telemetry: chaos, epiphany, delivery, and fractal phase."
        }
      </p>
    </div>
  `;
}

function sectionButton(
  state: ChatManualState,
  section: ChatManualSection,
  props: ChatProps,
  label: string,
) {
  return html`
    <button
      type="button"
      class="chat-manual__tab ${state.activeSection === section ? "active" : ""}"
      @click=${() => props.onManualSectionChange?.(section)}
    >
      ${label}
    </button>
  `;
}

function renderQuickReference(params: RenderManualParams) {
  const { props, manualState, manualRuntime } = params;
  if (manualState.activeSection === "commands") {
    return html`
      <div class="chat-manual__section">
        <h4>${t("chat.manualSectionCommands") || "Command Recipes"}</h4>
        <div class="chat-manual__cards">
          <article class="chat-manual__card">
            <div class="chat-manual__card-title">/aeon audit [Range]</div>
            <p>${t("chat.manualCmdAudit")}</p>
            <button type="button" @click=${() => props.onDraftChange?.("/aeon audit [0..128]")}>
              ${t("chat.manualActionInsert") || "Insert Draft"}
            </button>
          </article>
          <article class="chat-manual__card">
            <div class="chat-manual__card-title">DISTILL</div>
            <p>${t("chat.manualCmdDistill")}</p>
            <button type="button" @click=${() => props.onDraftChange?.("DISTILL")}>
              ${t("chat.manualActionInsert") || "Insert Draft"}
            </button>
          </article>
          <article class="chat-manual__card">
            <div class="chat-manual__card-title">REFINE</div>
            <p>${t("chat.manualCmdRefine")}</p>
            <button type="button" @click=${() => props.onDraftChange?.("REFINE")}>
              ${t("chat.manualActionInsert") || "Insert Draft"}
            </button>
          </article>
        </div>
      </div>
    `;
  }

  if (manualState.activeSection === "status") {
    return html`
      <div class="chat-manual__section">
        <h4>${t("chat.manualTabStatus") || "Status"}</h4>
        <p>${t("chat.manualResonance")}</p>
        <p>
          ${
            (t("chat.manualGuidePersistBody") || "Track delivery state until persisted.") +
            ` ${manualRuntime.delivery.state}`
          }
        </p>
      </div>
    `;
  }

  if (manualState.activeSection === "workflow") {
    return html`
      <div class="chat-manual__section">
        <h4>${t("chat.manualTabWorkflow") || "Workflow"}</h4>
        <div class="chat-manual__cards">
          <article class="chat-manual__card">
            <p>${t("chat.manualGuideStartBody")}</p>
            <button type="button" @click=${() => props.onNewSession?.()}>
              ${t("chat.manualActionNewSession") || "New Session"}
            </button>
          </article>
          <article class="chat-manual__card">
            <p>${t("chat.manualGuideUploadBody")}</p>
            <button type="button" @click=${() => props.onDraftChange?.(t("chat.manualGuideUploadDraft") || "请基于上传文件完成任务并给出最终落盘结果路径。")}>
              ${t("chat.manualActionInsert") || "Insert Draft"}
            </button>
          </article>
        </div>
      </div>
    `;
  }

  if (manualState.activeSection === "shortcuts") {
    return html`
      <div class="chat-manual__section">
        <h4>${t("chat.manualSectionShortcuts") || "Input Shortcuts"}</h4>
        <p>${t("chat.quickCommandTip")}</p>
      </div>
    `;
  }

  if (manualState.activeSection === "recovery") {
    return html`
      <div class="chat-manual__section">
        <h4>${t("chat.manualTabRecovery") || "Recovery"}</h4>
        <p>${t("chat.manualGuideTraceBody")}</p>
        <div class="chat-manual__row">
          <button type="button" @click=${() => props.onOpenAeon?.()}>${t("tabs.aeon")}</button>
          <button type="button" @click=${() => props.onOpenSandbox?.()}>${t("tabs.sandbox")}</button>
        </div>
      </div>
    `;
  }

  return html`
    <div class="chat-manual__section"><p>${t("chat.manualSubtitle")}</p></div>
  `;
}

function renderGuidedWalkthrough(params: RenderManualParams) {
  const { props, manualRuntime, manualState } = params;
  if (manualState.activeSection !== "overview" && manualState.activeSection !== "workflow") {
    return renderQuickReference(params);
  }

  return html`
    <ol class="chat-manual__steps">
      <li>
        <h4>${t("chat.manualGuideStartTitle") || "1. Start a complete session"}</h4>
        <p>${t("chat.manualGuideStartBody") || "Create a clean session and define your target output first."}</p>
        <button type="button" @click=${() => props.onNewSession?.()}>
          ${t("chat.manualActionNewSession") || "New Session"}
        </button>
      </li>
      <li>
        <h4>${t("chat.manualGuideUploadTitle") || "2. Attach context and send"}</h4>
        <p>${t("chat.manualGuideUploadBody") || "Use image/file upload and send a concrete execution request."}</p>
        <button type="button" @click=${() => props.onDraftChange?.(t("chat.manualGuideUploadDraft") || "请基于上传文件完成任务并给出最终落盘结果路径。")}>
          ${t("chat.manualActionInsert") || "Insert Draft"}
        </button>
      </li>
      <li>
        <h4>${t("chat.manualGuidePersistTitle") || "3. Confirm delivery persistence"}</h4>
        <p>
          ${
            (t("chat.manualGuidePersistBody") ||
              "Track execution delivery until persisted/acknowledged.") +
            ` (${manualRuntime.delivery.state})`
          }
        </p>
        <button type="button" @click=${() => props.onManualSectionChange?.("status")}>
          ${t("chat.manualActionExplainState") || "Explain Current State"}
        </button>
      </li>
      <li>
        <h4>${t("chat.manualGuideTraceTitle") || "4. Locate last-night artifacts"}</h4>
        <p>${t("chat.manualGuideTraceBody") || "Open AEON/Sandbox to trace final outputs and evolution logs."}</p>
        <div class="chat-manual__row">
          <button type="button" @click=${() => props.onOpenAeon?.()}>${t("tabs.aeon")}</button>
          <button type="button" @click=${() => props.onOpenSandbox?.()}>${t("tabs.sandbox")}</button>
        </div>
      </li>
    </ol>
  `;
}

export function renderChatManualPanel(params: RenderManualParams) {
  const { manualState, manualRuntime, props } = params;
  if (!manualState.visible) {
    return nothing;
  }

  return html`
    <div
      class="chat-manual-overlay"
      @click=${() => props.onManualToggle?.(false)}
      @keydown=${(event: KeyboardEvent) => {
        if (event.key === "Escape") {
          props.onManualToggle?.(false);
        }
      }}
    >
      <section
        class="chat-manual-panel"
        role="dialog"
        aria-modal="true"
        aria-label=${t("chat.manualTitle")}
        tabindex="0"
        @click=${(event: Event) => event.stopPropagation()}
      >
        <header class="chat-manual__header">
          <div>
            <h3>${t("chat.manualTitle")}</h3>
            <p>${t("chat.manualSubtitle")}</p>
          </div>
          <button type="button" class="chat-manual__close" @click=${() => props.onManualToggle?.(false)}>
            ×
          </button>
        </header>

        <div class="chat-manual__mode-switch">
          <button
            type="button"
            class=${manualState.mode === "quick" ? "active" : ""}
            @click=${() => props.onManualModeChange?.("quick" as ChatManualMode)}
          >
            ${t("chat.manualModeQuick") || "Quick Reference"}
          </button>
          <button
            type="button"
            class=${manualState.mode === "guided" ? "active" : ""}
            @click=${() => props.onManualModeChange?.("guided" as ChatManualMode)}
          >
            ${t("chat.manualModeGuided") || "Guided Walkthrough"}
          </button>
        </div>

        <div class="chat-manual__tabs">
          ${sectionButton(manualState, "overview", props, t("chat.manualTabOverview") || "Overview")}
          ${sectionButton(manualState, "commands", props, t("chat.manualTabCommands") || "Commands")}
          ${sectionButton(manualState, "workflow", props, t("chat.manualTabWorkflow") || "Workflow")}
          ${sectionButton(manualState, "status", props, t("chat.manualTabStatus") || "Status")}
          ${sectionButton(manualState, "shortcuts", props, t("chat.manualTabShortcuts") || "Shortcuts")}
          ${sectionButton(manualState, "recovery", props, t("chat.manualTabRecovery") || "Recovery")}
        </div>

        <div class="chat-manual__body">
          ${renderSnapshot(manualRuntime)}
          ${manualState.mode === "quick" ? renderQuickReference(params) : renderGuidedWalkthrough(params)}
        </div>
      </section>
    </div>
  `;
}
