import { html, nothing } from "lit";
import { AVATAR_CHARACTERS, renderAgentFigure } from "./figure.ts";
import type { GatewaySessionRow } from "../../../types.ts";

const previewRow: GatewaySessionRow = {
  key: "preview",
  kind: "direct",
  role: "worker",
  updatedAt: null,
  outputTokens: 100,
};

export function renderAgentRecruitmentModal(
  isOpen: boolean,
  onClose: () => void,
  onSelect: (avatarId: string) => void,
) {
  if (!isOpen) return nothing;

  return html`
    <div class="sandbox-recruit-modal" @click=${onClose}>
      <div class="sandbox-recruit-content" @click=${(e: Event) => e.stopPropagation()}>
        <div class="sandbox-recruit-header">
          <div class="sandbox-recruit-title">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
              <circle cx="9" cy="7" r="4"></circle>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
            Recruit Agent
          </div>
          <button class="sandbox-recruit-close" @click=${onClose}>&times;</button>
        </div>
        <div class="sandbox-recruit-tabs" role="tablist" aria-label="Recruit options">
          <button type="button" class="sandbox-recruit-tab sandbox-recruit-tab--active" role="tab" aria-selected="true">Recruiting</button>
          <button type="button" class="sandbox-recruit-tab" role="tab" aria-selected="false">Customizations</button>
        </div>
        <div class="sandbox-recruit-grid">
          ${AVATAR_CHARACTERS.map(
            (char) => html`
              <button
                type="button"
                class="recruit-card"
                data-id="${char.id}"
                aria-label="Recruit ${char.name}"
                @click=${() => onSelect(char.id)}
              >
                <div class="recruit-card__preview">
                  ${renderAgentFigure(previewRow, char.id)}
                </div>
                <div class="recruit-card__name">${char.name}</div>
                <div class="recruit-card__role">${char.role}</div>
                <span class="recruit-card__btn">Recruit</span>
              </button>
            `,
          )}
        </div>
      </div>
    </div>
  `;
}
