#!/bin/bash
set -euo pipefail

# OpenAEON 卸载脚本 macOS and Linux
# 使用方法: curl -fsSL https://raw.githubusercontent.com/gu2003li/OpenAEON/main/uninstall.sh | bash

BOLD='\033[1m'
ACCENT='\033[38;2;255;77;77m'
SUCCESS='\033[38;2;0;229;204m'
WARN='\033[38;2;255;176;32m'
ERROR='\033[38;2;230;57;70m'
NC='\033[0m'

ui_info() { echo -e "${BOLD}·${NC} $*"; }
ui_success() { echo -e "${SUCCESS}✓${NC} $*"; }
ui_warn() { echo -e "${WARN}!${NC} $*"; }
ui_error() { echo -e "${ERROR}✗${NC} $*"; }

echo -e "${ACCENT}${BOLD}"
echo "  🦞 OpenAEON 卸载程序"
echo -e "${NC}"

# 1. Stop and Uninstall Gateway Service
if command -v openaeon &> /dev/null; then
    ui_info "正在停止并卸载 OpenAEON 网关服务..."
    openaeon gateway stop &>/dev/null || true
    openaeon gateway uninstall --force &>/dev/null || true
    ui_success "网关服务已移除。"
fi

# 2. Remove Global NPM Package
if command -v npm &> /dev/null; then
    ui_info "正在卸载全局 openaeon 包..."
    npm uninstall -g openaeon &>/dev/null || true
    ui_success "NPM 包已卸载。"
fi

# 3. Remove Local Binaries
BIN_FILE="$HOME/.local/bin/openaeon"
if [[ -L "$BIN_FILE" || -f "$BIN_FILE" ]]; then
    ui_info "正在删除本地执行文件 $BIN_FILE..."
    rm -f "$BIN_FILE"
    ui_success "执行文件已删除。"
fi

# 4. Remove Configuration (Optional/Confirm)
# By default, we keep the data to prevent accidental loss, but provide instructions.
CONFIG_FILE="$HOME/.openaeon.json"
DATA_DIR="$HOME/.openaeon"

echo ""
ui_warn "配置文件和会话数据未被自动删除。"
echo "如需彻底清除所有数据，请手动执行:"
echo -e "  ${BOLD}rm -f $CONFIG_FILE${NC}"
echo -e "  ${BOLD}rm -rf $DATA_DIR${NC}"
echo -e "  ${BOLD}rm -rf $HOME/.clawdbot $HOME/.moltbot $HOME/.moldbot${NC}"
echo ""

ui_success "OpenAEON 已成功卸载。清理完成！🎯"