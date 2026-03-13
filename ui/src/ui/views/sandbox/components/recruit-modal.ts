import { html, nothing } from "lit";
import { AVATAR_CHARACTERS, renderAgentFigure } from "./figure.ts";

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
        <div class="sandbox-recruit-tabs">
          <div class="sandbox-recruit-tab sandbox-recruit-tab--active">Recruiting</div>
          <div class="sandbox-recruit-tab">Customizations</div>
        </div>
        <div class="sandbox-recruit-grid">
          ${AVATAR_CHARACTERS.map(
            (char) => html`
              <div class="recruit-card" data-id="${char.id}" @click=${() => onSelect(char.id)}>
                <div class="recruit-card__preview">
                  ${renderAgentFigure({ key: "preview", role: "worker", outputTokens: 100 } as any, char.id)}
                </div>
                <div class="recruit-card__name">${char.name}</div>
                <div class="recruit-card__role">${char.role}</div>
                <button class="recruit-card__btn">Recruit</button>
              </div>
            `,
          )}
        </div>
      </div>
    </div>
  `;
}
