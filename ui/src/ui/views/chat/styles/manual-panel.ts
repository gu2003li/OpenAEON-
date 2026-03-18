import { css } from "lit";

export const chatManualPanelStyles = css`
  .chat-manual-overlay {
    position: absolute;
    inset: 0;
    z-index: 30;
    background: rgba(2, 6, 23, 0.56);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 28px;
  }

  .chat-manual-panel {
    width: min(980px, 100%);
    max-height: min(86vh, 900px);
    overflow: auto;
    border-radius: 18px;
    border: 1px solid rgba(56, 189, 248, 0.34);
    background:
      radial-gradient(120% 110% at 85% 0%, rgba(45, 212, 191, 0.12), transparent 64%),
      radial-gradient(120% 110% at 0% 100%, rgba(129, 140, 248, 0.16), transparent 64%),
      rgba(5, 13, 31, 0.92);
    box-shadow:
      inset 0 0 0 1px rgba(125, 211, 252, 0.1),
      0 28px 70px rgba(2, 6, 23, 0.65);
  }

  .chat-manual__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    padding: 22px 24px 16px;
    border-bottom: 1px solid rgba(56, 189, 248, 0.2);
  }

  .chat-manual__header h3 {
    margin: 0;
    font-size: 22px;
    letter-spacing: 0.06em;
    color: #60a5fa;
  }

  .chat-manual__header p {
    margin: 6px 0 0;
    color: #b6c7de;
    font-size: 13px;
  }

  .chat-manual__close {
    border: 1px solid rgba(148, 163, 184, 0.35);
    background: rgba(15, 23, 42, 0.6);
    color: #dbeafe;
    border-radius: 10px;
    width: 34px;
    height: 34px;
    cursor: pointer;
  }

  .chat-manual__mode-switch {
    display: flex;
    gap: 8px;
    padding: 14px 24px 8px;
  }

  .chat-manual__mode-switch button {
    border: 1px solid rgba(56, 189, 248, 0.22);
    background: rgba(15, 23, 42, 0.5);
    color: #cbd5e1;
    border-radius: 10px;
    padding: 7px 12px;
    cursor: pointer;
  }

  .chat-manual__mode-switch button.active {
    border-color: rgba(45, 212, 191, 0.55);
    color: #9ff6e6;
    background: rgba(45, 212, 191, 0.14);
  }

  .chat-manual__tabs {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 8px 24px 16px;
    border-bottom: 1px solid rgba(56, 189, 248, 0.16);
  }

  .chat-manual__tab {
    border: 1px solid rgba(100, 116, 139, 0.4);
    border-radius: 999px;
    padding: 6px 12px;
    font-size: 12px;
    color: #bfdbfe;
    background: rgba(15, 23, 42, 0.55);
    cursor: pointer;
  }

  .chat-manual__tab.active {
    border-color: rgba(125, 211, 252, 0.62);
    background: rgba(56, 189, 248, 0.16);
    color: #e0f2fe;
  }

  .chat-manual__body {
    padding: 18px 24px 24px;
    display: grid;
    gap: 20px;
  }

  .chat-manual__snapshot {
    border: 1px solid rgba(56, 189, 248, 0.2);
    border-radius: 12px;
    padding: 14px;
    background: rgba(8, 19, 42, 0.6);
  }

  .chat-manual__snapshot-title {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.14em;
    color: #7dd3fc;
    margin-bottom: 10px;
  }

  .chat-manual__snapshot-grid {
    display: grid;
    gap: 10px;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .chat-manual__snapshot-item {
    display: grid;
    gap: 3px;
    border-radius: 10px;
    border: 1px solid rgba(100, 116, 139, 0.3);
    background: rgba(15, 23, 42, 0.48);
    padding: 9px 10px;
  }

  .chat-manual__snapshot-item span {
    font-size: 11px;
    color: #94a3b8;
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }

  .chat-manual__snapshot-item strong {
    font-size: 13px;
    color: #e2e8f0;
    font-family: var(--fractal-font-mono, "JetBrains Mono", monospace);
  }

  .chat-manual__why {
    margin: 10px 0 0;
    font-size: 12px;
    color: #9fb4cf;
  }

  .chat-manual__section h4 {
    margin: 0 0 10px;
    font-size: 14px;
    color: #dbeafe;
    letter-spacing: 0.04em;
  }

  .chat-manual__cards {
    display: grid;
    gap: 10px;
  }

  .chat-manual__card {
    border: 1px solid rgba(100, 116, 139, 0.32);
    border-radius: 12px;
    background: rgba(15, 23, 42, 0.45);
    padding: 12px;
  }

  .chat-manual__card-title {
    font-family: var(--fractal-font-mono, "JetBrains Mono", monospace);
    font-size: 13px;
    color: #67e8f9;
    margin-bottom: 6px;
  }

  .chat-manual__card p {
    margin: 0 0 10px;
    font-size: 12px;
    line-height: 1.5;
    color: #c8daee;
  }

  .chat-manual__card button,
  .chat-manual__steps button {
    border: 1px solid rgba(45, 212, 191, 0.35);
    background: rgba(45, 212, 191, 0.12);
    color: #a7f3d0;
    border-radius: 8px;
    padding: 6px 10px;
    cursor: pointer;
    font-size: 12px;
  }

  .chat-manual__steps {
    margin: 0;
    padding-left: 18px;
    display: grid;
    gap: 14px;
  }

  .chat-manual__steps li h4 {
    margin: 0 0 6px;
    color: #e2e8f0;
    font-size: 14px;
  }

  .chat-manual__steps li p {
    margin: 0 0 8px;
    color: #b8cbe0;
    font-size: 12px;
    line-height: 1.5;
  }

  .chat-manual__row {
    display: flex;
    gap: 8px;
  }

  @media (max-width: 900px) {
    .chat-manual-overlay {
      padding: 12px;
    }

    .chat-manual__snapshot-grid {
      grid-template-columns: 1fr;
    }
  }
`;
