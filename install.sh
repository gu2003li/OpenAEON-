#!/bin/bash
set -euo pipefail

# OpenAEON 安装程序 macOS 和 Linux
# 使用方法: curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash

BOLD='\033[1m'
ACCENT='\033[38;2;255;77;77m'       # coral-bright  #ff4d4d
# shellcheck disable=SC2034
ACCENT_BRIGHT='\033[38;2;255;110;110m' # lighter coral
INFO='\033[38;2;136;146;176m'       # text-secondary #8892b0
SUCCESS='\033[38;2;0;229;204m'      # cyan-bright   #00e5cc
WARN='\033[38;2;255;176;32m'        # amber (no site equiv, keep warm)
ERROR='\033[38;2;230;57;70m'        # coral-mid     #e63946
MUTED='\033[38;2;90;100;128m'       # text-muted    #5a6480
NC='\033[0m' # No Color

DEFAULT_TAGLINE="All your chats, one OpenAEON."

ORIGINAL_PATH="${PATH:-}"

TMPFILES=()
cleanup_tmpfiles() {
    local f
    for f in "${TMPFILES[@]:-}"; do
        rm -rf "$f" 2>/dev/null || true
    done
}
trap cleanup_tmpfiles EXIT

mktempfile() {
    local f
    f="$(mktemp)"
    TMPFILES+=("$f")
    echo "$f"
}

DOWNLOADER=""
detect_downloader() {
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
        return 0
    fi
    if command -v wget &> /dev/null; then
        DOWNLOADER="wget"
        return 0
    fi
    ui_error "缺少下载工具（需要安装 curl 或 wget）"
    exit 1
}

download_file() {
    local url="$1"
    local output="$2"
    if [[ -z "$DOWNLOADER" ]]; then
        detect_downloader
    fi
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 --retry-connrefused -o "$output" "$url"
        return
    fi
    wget -q --https-only --secure-protocol=TLSv1_2 --tries=3 --timeout=20 -O "$output" "$url"
}

run_remote_bash() {
    local url="$1"
    local tmp
    tmp="$(mktempfile)"
    download_file "$url" "$tmp"
    /bin/bash "$tmp"
}

GUM_VERSION="${OPENAEON_GUM_VERSION:-0.17.0}"
GUM=""
GUM_STATUS="已跳过"
GUM_REASON=""
LAST_NPM_INSTALL_CMD=""

is_non_interactive_shell() {
    if [[ "${NO_PROMPT:-0}" == "1" ]]; then
        return 0
    fi
    if [[ ! -t 0 || ! -t 1 ]]; then
        return 0
    fi
    return 1
}

gum_is_tty() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi
    if [[ "${TERM:-dumb}" == "dumb" ]]; then
        return 1
    fi
    if [[ -t 2 || -t 1 ]]; then
        return 0
    fi
    if [[ -r /dev/tty && -w /dev/tty ]]; then
        return 0
    fi
    return 1
}

gum_detect_os() {
    case "$(uname -s 2>/dev/null || true)" in
        Darwin) echo "Darwin" ;;
        Linux) echo "Linux" ;;
        *) echo "不支持" ;;
    esac
}

gum_detect_arch() {
    case "$(uname -m 2>/dev/null || true)" in
        x86_64|amd64) echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        i386|i686) echo "i386" ;;
        armv7l|armv7) echo "armv7" ;;
        armv6l|armv6) echo "armv6" ;;
        *) echo "unknown" ;;
    esac
}

verify_sha256sum_file() {
    local checksums="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum --ignore-missing -c "$checksums" >/dev/null 2>&1
        return $?
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 --ignore-missing -c "$checksums" >/dev/null 2>&1
        return $?
    fi
    return 1
}

bootstrap_gum_temp() {
    GUM=""
    GUM_STATUS="已跳过"
    GUM_REASON=""

    if is_non_interactive_shell; then
        GUM_REASON="非交互式 Shell（已自动禁用）"
        return 1
    fi

    if ! gum_is_tty; then
        GUM_REASON="终端不支持 gum 界面"
        return 1
    fi

    if command -v gum >/dev/null 2>&1; then
        GUM="gum"
        GUM_STATUS="已找到"
        GUM_REASON="已安装"
        return 0
    fi

    if ! command -v tar >/dev/null 2>&1; then
        GUM_REASON="tar not found"
        return 1
    fi

    local os arch asset base gum_tmpdir gum_path
    os="$(gum_detect_os)"
    arch="$(gum_detect_arch)"
    if [[ "$os" == "不支持" || "$arch" == "unknown" ]]; then
        GUM_REASON="不支持的操作系统/架构 ($os/$arch)"
        return 1
    fi

    asset="gum_${GUM_VERSION}_${os}_${arch}.tar.gz"
    base="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}"

    gum_tmpdir="$(mktemp -d)"
    TMPFILES+=("$gum_tmpdir")

    if ! download_file "${base}/${asset}" "$gum_tmpdir/$asset"; then
        GUM_REASON="下载失败"
        return 1
    fi

    if ! download_file "${base}/checksums.txt" "$gum_tmpdir/checksums.txt"; then
        GUM_REASON="校验和不可用或校验失败"
        return 1
    fi

    if ! (cd "$gum_tmpdir" && verify_sha256sum_file "checksums.txt"); then
        GUM_REASON="校验和不可用或校验失败"
        return 1
    fi

    if ! tar -xzf "$gum_tmpdir/$asset" -C "$gum_tmpdir" >/dev/null 2>&1; then
        GUM_REASON="解压失败"
        return 1
    fi

    gum_path="$(find "$gum_tmpdir" -type f -name gum 2>/dev/null | head -n1 || true)"
    if [[ -z "$gum_path" ]]; then
        GUM_REASON="解压后缺少 gum 二进制文件"
        return 1
    fi

    chmod +x "$gum_path" >/dev/null 2>&1 || true
    if [[ ! -x "$gum_path" ]]; then
        GUM_REASON="gum 二进制文件不可执行"
        return 1
    fi

    GUM="$gum_path"
    GUM_STATUS="installed"
    GUM_REASON="临时文件，已验证"
    return 0
}

print_gum_status() {
    case "$GUM_STATUS" in
        found)
            ui_success "gum 可用 (${GUM_REASON})"
            ;;
        installed)
            ui_success "gum 已初始化 (${GUM_REASON}, v${GUM_VERSION})"
            ;;
        *)
            if [[ -n "$GUM_REASON" && "$GUM_REASON" != "非交互式 Shell（已自动禁用）" ]]; then
                ui_info "已跳过 gum（${GUM_REASON}）"
            fi
            ;;
    esac
}

print_installer_banner() {
    if [[ -n "$GUM" ]]; then
        local title tagline hint card
        title="$("$GUM" style --foreground "#ff4d4d" --bold "🦞 OpenAEON 安装程序")"
        tagline="$("$GUM" style --foreground "#8892b0" "$TAGLINE")"
        hint="$("$GUM" style --foreground "#5a6480" "现代化安装模式")"
        card="$(printf '%s\n%s\n%s' "$title" "$tagline" "$hint")"
        "$GUM" style --border rounded --border-foreground "#ff4d4d" --padding "1 2" "$card"
        echo ""
        return
    fi

    echo -e "${ACCENT}${BOLD}"
    echo "  🦞 OpenAEON 安装程序"
    echo -e "${NC}${INFO}  ${TAGLINE}${NC}"
    echo ""
}

detect_os_or_die() {
    OS="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        OS="linux"
    fi

    if [[ "$OS" == "unknown" ]]; then
        ui_error "不支持的操作系统"
        echo "此安装程序支持 macOS 和 Linux（包括 WSL）。"
        echo "Windows 系统请使用: iwr -useb https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.ps1 | iex"
        exit 1
    fi

    ui_success "检测到系统: $OS"
}

ui_info() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level info "$msg"
    else
        echo -e "${MUTED}·${NC} ${msg}"
    fi
}

ui_warn() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level warn "$msg"
    else
        echo -e "${WARN}!${NC} ${msg}"
    fi
}

ui_success() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        local mark
        mark="$("$GUM" style --foreground "#00e5cc" --bold "✓")"
        echo "${mark} ${msg}"
    else
        echo -e "${SUCCESS}✓${NC} ${msg}"
    fi
}

ui_error() {
    local msg="$*"
    if [[ -n "$GUM" ]]; then
        "$GUM" log --level error "$msg"
    else
        echo -e "${ERROR}✗${NC} ${msg}"
    fi
}

INSTALL_STAGE_TOTAL=3
INSTALL_STAGE_CURRENT=0

ui_section() {
    local title="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --bold --foreground "#ff4d4d" --padding "1 0" "$title"
    else
        echo ""
        echo -e "${ACCENT}${BOLD}${title}${NC}"
    fi
}

ui_stage() {
    local title="$1"
    INSTALL_STAGE_CURRENT=$((INSTALL_STAGE_CURRENT + 1))
    ui_section "[${INSTALL_STAGE_CURRENT}/${INSTALL_STAGE_TOTAL}] ${title}"
}

ui_kv() {
    local key="$1"
    local value="$2"
    if [[ -n "$GUM" ]]; then
        local key_part value_part
        key_part="$("$GUM" style --foreground "#5a6480" --width 20 "$key")"
        value_part="$("$GUM" style --bold "$value")"
        "$GUM" join --horizontal "$key_part" "$value_part"
    else
        echo -e "${MUTED}${key}:${NC} ${value}"
    fi
}

ui_panel() {
    local content="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --border rounded --border-foreground "#5a6480" --padding "0 1" "$content"
    else
        echo "$content"
    fi
}

show_install_plan() {
    local detected_checkout="$1"

    ui_section "安装方案"
    ui_kv "操作系统" "$OS"
    ui_kv "安装方式" "$INSTALL_METHOD"
    ui_kv "所需版本" "$OPENAEON_VERSION"
    if [[ "$USE_BETA" == "1" ]]; then
        ui_kv "Beta channel" "enabled"
    fi
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        ui_kv "Git 目录" "$GIT_DIR"
        ui_kv "Git 更新" "$GIT_UPDATE"
    fi
    if [[ -n "$detected_checkout" ]]; then
        ui_kv "检测到检出" "$detected_checkout"
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
        ui_kv "试运行" "yes"
    fi
    if [[ "$NO_ONBOARD" == "1" ]]; then
        ui_kv "初始化引导""已跳过"
    fi
}

show_footer_links() {
    local faq_url="https://github.com/gu2003li/OpenAEON"
    if [[ -n "$GUM" ]]; then
        local content
        content="$(printf '%s\n%s' "需要帮助?" "常见问题: ${faq_url}")"
        ui_panel "$content"
    else
        echo ""
        echo -e "常见问题: ${INFO}${faq_url}${NC}"
    fi
}

ui_celebrate() {
    local msg="$1"
    if [[ -n "$GUM" ]]; then
        "$GUM" style --bold --foreground "#00e5cc" "$msg"
    else
        echo -e "${SUCCESS}${BOLD}${msg}${NC}"
    fi
}

is_shell_function() {
    local name="${1:-}"
    [[ -n "$name" ]] && declare -F "$name" >/dev/null 2>&1
}

is_gum_raw_mode_failure() {
    local err_log="$1"
    [[ -s "$err_log" ]] || return 1
    grep -Eiq 'setrawmode' "$err_log"
}

run_with_spinner() {
    local title="$1"
    shift

    if [[ -n "$GUM" ]] && gum_is_tty && ! is_shell_function "${1:-}"; then
        local gum_err
        gum_err="$(mktempfile)"
        if "$GUM" spin --spinner dot --title "$title" -- "$@" 2>"$gum_err"; then
            return 0
        fi
        local gum_status=$?
        if is_gum_raw_mode_failure "$gum_err"; then
            GUM=""
            GUM_STATUS="skipped"
            GUM_REASON="gum 原始模式不可用"
            ui_warn "当前终端不支持加载动画，将继续运行（无加载动画）"
            "$@"
            return $?
        fi
        if [[ -s "$gum_err" ]]; then
            cat "$gum_err" >&2
        fi
        return "$gum_status"
    fi

    "$@"
}

run_quiet_step() {
    local title="$1"
    shift

    if [[ "$VERBOSE" == "1" ]]; then
        run_with_spinner "$title" "$@"
        return $?
    fi

    local log
    log="$(mktempfile)"

    if [[ -n "$GUM" ]] && gum_is_tty && ! is_shell_function "${1:-}"; then
        local cmd_quoted=""
        local log_quoted=""
        printf -v cmd_quoted '%q ' "$@"
        printf -v log_quoted '%q' "$log"
        if run_with_spinner "$title" bash -c "${cmd_quoted}>${log_quoted} 2>&1"; then
            return 0
        fi
    else
        if "$@" >"$log" 2>&1; then
            return 0
        fi
    fi

    ui_error "${title} 失败 — 请使用 --verbose 参数重新运行以查看详细信息"
    if [[ -s "$log" ]]; then
        tail -n 80 "$log" >&2 || true
    fi
    return 1
}

cleanup_legacy_submodules() {
    local repo_dir="$1"
    local legacy_dir="$repo_dir/Peekaboo"
    if [[ -d "$legacy_dir" ]]; then
        ui_info "正在移除旧的子模块检出目录: ${legacy_dir}"
        rm -rf "$legacy_dir"
    fi
}

cleanup_npm_openaeon_paths() {
    local npm_root=""
    npm_root="$(npm root -g 2>/dev/null || true)"
    if [[ -z "$npm_root" || "$npm_root" != *node_modules* ]]; then
        return 1
    fi
    rm -rf "$npm_root"/.openaeon-* "$npm_root"/openaeon 2>/dev/null || true
}

extract_openaeon_conflict_path() {
    local log="$1"
    local path=""
    path="$(sed -n 's/.*File exists: //p' "$log" | head -n1)"
    if [[ -z "$path" ]]; then
        path="$(sed -n 's/.*EEXIST: file already exists, //p' "$log" | head -n1)"
    fi
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi
    return 1
}

cleanup_openaeon_bin_conflict() {
    local bin_path="$1"
    if [[ -z "$bin_path" || ( ! -e "$bin_path" && ! -L "$bin_path" ) ]]; then
        return 1
    fi
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir 2>/dev/null || true)"
    if [[ -n "$npm_bin" && "$bin_path" != "$npm_bin/openaeon" ]]; then
        case "$bin_path" in
            "/opt/homebrew/bin/openaeon"|"/usr/local/bin/openaeon")
                ;;
            *)
                return 1
                ;;
        esac
    fi
    if [[ -L "$bin_path" ]]; then
        local target=""
        target="$(readlink "$bin_path" 2>/dev/null || true)"
        if [[ "$target" == *"/node_modules/openaeon/"* ]]; then
            rm -f "$bin_path"
            ui_info "已删除位于 ${bin_path} 的过期 openaeon 符号链接"
            return 0
        fi
        return 1
    fi
    local backup=""
    backup="${bin_path}.bak-$(date +%Y%m%d-%H%M%S)"
    if mv "$bin_path" "$backup"; then
        ui_info "已将现有的 openaeon 二进制文件移动到 ${backup}"
        return 0
    fi
    return 1
}

npm_log_indicates_missing_build_tools() {
    local log="$1"
    if [[ -z "$log" || ! -f "$log" ]]; then
        return 1
    fi

    grep -Eiq "(not found: make|make: command not found|cmake: command not found|CMAKE_MAKE_PROGRAM is not set|Could not find CMAKE|gyp ERR! find Python|no developer tools were found|is not able to compile a simple test program|Failed to build llama\\.cpp|It seems that \"make\" is not installed in your system|It seems that the used \"cmake\" doesn't work properly)" "$log"
}

install_build_tools_linux() {
    require_sudo

    if command -v apt-get &> /dev/null; then
        if is_root; then
            run_quiet_step "正在更新软件包索引" apt-get update -qq
            run_quiet_step "正在安装构建工具" apt-get install -y -qq build-essential python3 make g++ cmake
        else
            run_quiet_step "正在更新软件包索引" sudo apt-get update -qq
            run_quiet_step "正在安装构建工具" sudo apt-get install -y -qq build-essential python3 make g++ cmake
        fi
        return 0
    fi

    if command -v dnf &> /dev/null; then
        if is_root; then
            run_quiet_step "正在安装构建工具" dnf install -y -q gcc gcc-c++ make cmake python3
        else
            run_quiet_step "正在安装构建工具" sudo dnf install -y -q gcc gcc-c++ make cmake python3
        fi
        return 0
    fi

    if command -v yum &> /dev/null; then
        if is_root; then
            run_quiet_step "正在安装构建工具" yum install -y -q gcc gcc-c++ make cmake python3
        else
            run_quiet_step "正在安装构建工具" sudo yum install -y -q gcc gcc-c++ make cmake python3
        fi
        return 0
    fi

    if command -v apk &> /dev/null; then
        if is_root; then
            run_quiet_step "正在安装构建工具" apk add --no-cache build-base python3 cmake
        else
            run_quiet_step "正在安装构建工具" sudo apk add --no-cache build-base python3 cmake
        fi
        return 0
    fi

    ui_warn "无法检测到用于自动安装构建工具的包管理器"
    return 1
}

install_build_tools_macos() {
    local ok=true

    if ! xcode-select -p >/dev/null 2>&1; then
        ui_info "正在安装 Xcode 命令行工具（make/clang 必需依赖）"
        xcode-select --install >/dev/null 2>&1 || true
        if ! xcode-select -p >/dev/null 2>&1; then
            ui_warn "Xcode 命令行工具尚未准备就绪"
            ui_info "完成安装向导后，请重新运行此安装程序"
            ok=false
        fi
    fi

    if ! command -v cmake >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            run_quiet_step "正在安装 cmake" brew install cmake
        else
            ui_warn "Homebrew 不可用，无法自动安装 cmake"
            ok=false
        fi
    fi

    if ! command -v make >/dev/null 2>&1; then
        ui_warn "make 仍不可用"
        ok=false
    fi
    if ! command -v cmake >/dev/null 2>&1; then
        ui_warn "cmake 仍然不可用"
        ok=false
    fi

    [[ "$ok" == "true" ]]
}

auto_install_build_tools_for_npm_failure() {
    local log="$1"
    if ! npm_log_indicates_missing_build_tools "$log"; then
        return 1
    fi

    ui_warn "检测到缺少原生构建工具，正在尝试自动安装配置"
    if [[ "$OS" == "linux" ]]; then
        install_build_tools_linux || return 1
    elif [[ "$OS" == "macos" ]]; then
        install_build_tools_macos || return 1
    else
        return 1
    fi
    ui_success "构建工具安装完成"
    return 0
}

run_npm_global_install() {
    local spec="$1"
    local log="$2"

    local -a cmd
    cmd=(env "SHARP_IGNORE_GLOBAL_LIBVIPS=$SHARP_IGNORE_GLOBAL_LIBVIPS" npm --loglevel "$NPM_LOGLEVEL")
    if [[ -n "$NPM_SILENT_FLAG" ]]; then
        cmd+=("$NPM_SILENT_FLAG")
    fi
    cmd+=(--no-fund --no-audit install -g "$spec")
    local cmd_display=""
    printf -v cmd_display '%q ' "${cmd[@]}"
    LAST_NPM_INSTALL_CMD="${cmd_display% }"

    if [[ "$VERBOSE" == "1" ]]; then
        "${cmd[@]}" 2>&1 | tee "$log"
        return $?
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local cmd_quoted=""
        local log_quoted=""
        printf -v cmd_quoted '%q ' "${cmd[@]}"
        printf -v log_quoted '%q' "$log"
        run_with_spinner "安装 OpenAEON 包" bash -c "${cmd_quoted}>${log_quoted} 2>&1"
        return $?
    fi

    "${cmd[@]}" >"$log" 2>&1
}

extract_npm_debug_log_path() {
    local log="$1"
    local path=""
    path="$(sed -n -E 's/.*A complete log of this run can be found in:[[:space:]]*//p' "$log" | tail -n1)"
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    path="$(grep -Eo '/[^[:space:]]+_logs/[^[:space:]]+debug[^[:space:]]*\.log' "$log" | tail -n1 || true)"
    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

extract_first_npm_error_line() {
    local log="$1"
    grep -E 'npm (ERR!|error)|ERR!' "$log" | head -n1 || true
}

extract_npm_error_code() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) code[[:space:]]+([^[:space:]]+).*$/\2/p' "$log" | head -n1
}

extract_npm_error_syscall() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) syscall[[:space:]]+(.+)$/\2/p' "$log" | head -n1
}

extract_npm_error_errno() {
    local log="$1"
    sed -n -E 's/^npm (ERR!|error) errno[[:space:]]+(.+)$/\2/p' "$log" | head -n1
}

print_npm_failure_diagnostics() {
    local spec="$1"
    local log="$2"
    local debug_log=""
    local first_error=""
    local error_code=""
    local error_syscall=""
    local error_errno=""

    ui_warn "npm 安装失败，包: ${spec}"
    if [[ -n "${LAST_NPM_INSTALL_CMD}" ]]; then
        echo "  命令: ${LAST_NPM_INSTALL_CMD}"
    fi
    echo "  安装程序日志: ${log}"

    error_code="$(extract_npm_error_code "$log")"
    if [[ -n "$error_code" ]]; then
        echo "  npm 错误代码: ${error_code}"
    fi

    error_syscall="$(extract_npm_error_syscall "$log")"
    if [[ -n "$error_syscall" ]]; then
        echo "  npm 系统调用: ${error_syscall}"
    fi

    error_errno="$(extract_npm_error_errno "$log")"
    if [[ -n "$error_errno" ]]; then
        echo "  npm 错误码: ${error_errno}"
    fi

    debug_log="$(extract_npm_debug_log_path "$log" || true)"
    if [[ -n "$debug_log" ]]; then
        echo "  npm 调试日志: ${debug_log}"
    fi

    first_error="$(extract_first_npm_error_line "$log")"
    if [[ -n "$first_error" ]]; then
        echo "  首次 npm 错误: ${first_error}"
    fi
}

install_openaeon_npm() {
    local spec="$1"
    local log
    log="$(mktempfile)"
    if ! run_npm_global_install "$spec" "$log"; then
        local attempted_build_tool_fix=false
        if auto_install_build_tools_for_npm_failure "$log"; then
            attempted_build_tool_fix=true
            ui_info "已安装构建工具，正在重试 npm 安装"
            if run_npm_global_install "$spec" "$log"; then
                ui_success "OpenAEON npm 包已安装。"
                return 0
            fi
        fi

        print_npm_failure_diagnostics "$spec" "$log"

        if [[ "$VERBOSE" != "1" ]]; then
            if [[ "$已尝试修复构建工具" == "true" ]]; then
                ui_warn "已安装构建工具后 npm 安装仍然失败；显示最后日志行"
            else
                ui_warn "npm 安装失败；显示最后日志行"
            fi
            tail -n 80 "$log" >&2 || true
        fi

        if grep -q "目录非空，无法重命名 .*openaeon" "$log"; then
            ui_warn "npm 残留了过期目录，正在清理并重试。"
            cleanup_npm_openaeon_paths
            if run_npm_global_install "$spec" "$log"; then
                ui_success "OpenAEON npm 包已安装。"
                return 0
            fi
            return 1
        fi
        if grep -q "EEXIST" "$log"; then
            local conflict=""
            conflict="$(extract_openaeon_conflict_path "$log" || true)"
            if [[ -n "$conflict" ]] && cleanup_openaeon_bin_conflict "$conflict"; then
                if run_npm_global_install "$spec" "$log"; then
                    ui_success "OpenAEON npm 包已安装。"
                    return 0
                fi
                return 1
            fi
            ui_error "npm 安装失败，因为 openaeon 二进制文件已存在。"
            if [[ -n "$conflict" ]]; then
                ui_info "移除或移动 ${conflict}，然后重试。"
            fi
            ui_info "重新运行命令: npm install -g --force ${spec}"
        fi
        return 1
    fi
    ui_success "OpenAEON npm 包已安装"
    return 0
}

TAGLINES=()
TAGLINES+=("你的终端刚长出了小爪子——敲点命令吧，让我帮你把杂活都夹走。")
TAGLINES+=("欢迎来到命令行: 梦想在这里编译，自信在这里段错误。")
TAGLINES+=("我靠咖啡因、JSON5 和一句“在我电脑上跑得好好的”的勇气续命。")
TAGLINES+=("网关已上线——请全程将手、脚和所有附属肢体保持在 shell 内。")
TAGLINES+=("我精通bash，略带嘲讽，还满是激进的tab补全能量。")
TAGLINES+=("一条 CLI 统治全局，再重启一次，因为你刚改了端口。")
TAGLINES+=("跑起来了就是自动化，炸了那叫学习机会。")
TAGLINES+=("配对码存在的意义，就是就算是机器人也懂征得同意——还有良好的安全习惯。")
TAGLINES+=("你的 .env 露出来了；别慌，我就当没看见。")
TAGLINES+=("我来干那些枯燥活，你只管像看大片一样，深情凝视日志就行。")
TAGLINES+=("我不是说你的工作流很乱…我只是带了个代码检查器和安全帽来。")
TAGLINES+=("自信敲下命令——需要的话，大自然会给你甩一份栈追踪。")
TAGLINES+=("我不评判你，但你那些失踪的 API Key 绝对在偷偷评判你。")
TAGLINES+=("我可以 grep 它、git blame 它、还能温柔吐槽它——选个你喜欢的解压方式就行。")
TAGLINES+=("配置热重载，部署一身冷汗。")
TAGLINES+=("我是你终端真正需要的助手，不是你作息想要的那个。")
TAGLINES+=("我保管秘密像保险库…除非你又把它们打印到调试日志里。")
TAGLINES+=("带爪子的自动化: 省事省心，一夹就稳。")
TAGLINES+=("我基本就是把瑞士军刀，只不过主见更多、棱角更少。")
TAGLINES+=("迷路就跑 doctor，胆大就跑 prod，聪明就先跑 tests。")
TAGLINES+=("任务已加入队列；你的尊严已被标记弃用。")
TAGLINES+=("我改不了你的代码品味，但我能修好你的构建和待办清单。")
TAGLINES+=("我不是魔法——我只是特别执着，自带重试和心态自救策略。")
TAGLINES+=("这哪叫“失败”，这叫探索把同一件事配错的新姿势。")
TAGLINES+=("给我一个工作区，我还你更少标签、更少开关、更多喘息空间。")
TAGLINES+=("我来读日志，你继续假装根本不用看就行。")
TAGLINES+=("真着火了我灭不了——但我能给你写一篇超漂亮的故障复盘。")
TAGLINES+=("我会把你的杂活重构得像它欠我钱一样狠。")
TAGLINES+=("说「停」我就停——说「发布」，咱俩都能上一课。")
TAGLINES+=("我就是让你 Shell 历史记录，看起来像黑客电影混剪的原因。")
TAGLINES+=("我就像 tmux：一开始觉得难用费解，用过之后就再也离不开。")
TAGLINES+=("本地、远程、凭感觉跑都行——效果随缘，看DNS心情。")
TAGLINES+=("只要你能描述出来，我基本都能自动化——至少能让这事变得好玩点。")
TAGLINES+=("配置文件合法，但你的假设不合法。")
TAGLINES+=("我不只是自动补全——我还会自动提交（走心版），再请你理性审核。")
TAGLINES+=("少点点击，多点交付，少点“我文件放哪了”的崩溃瞬间。")
TAGLINES+=("亮出利爪，提交代码——咱们整点靠谱又不失乐趣的东西。")
TAGLINES+=("我会把你的工作流程抹得像龙虾卷一样: 顺滑、过瘾、还特别好用。")
TAGLINES+=("必须安排——搞定繁琐，把荣耀留给你。")
TAGLINES+=("重复的我来自动化，难办的我带笑话和回滚方案。")
TAGLINES+=("给自己发提醒这种事，太2024年了。")
TAGLINES+=("WhatsApp 硬核工程化 ✨")
TAGLINES+=("把“稍后回复”变成“我的机器人已秒回”。")
TAGLINES+=("通讯录里唯一你真心想收到消息的家伙。🦞")
TAGLINES+=("专为曾在IRC巅峰时期玩透的人打造的聊天自动化。")
TAGLINES+=("因为凌晨三点，Siri 根本不搭理你。")
TAGLINES+=("进程间通信，只不过用你的手机实现。")
TAGLINES+=("UNIX 哲学，适配你的私信。")
TAGLINES+=("专为对话而生的 curl。")
TAGLINES+=("WhatsApp 商业版，但不带商业套路。")
TAGLINES+=("Meta 都羡慕我们的上线速度。")
TAGLINES+=("端到端加密，扎克概不介入。")
TAGLINES+=("唯一一个马克不会拿你的私信去训练的机器人。")
TAGLINES+=("无需接受新隐私政策的 WhatsApp 自动化。")
TAGLINES+=("无需参议院听证会，就能使用的聊天 API。")
TAGLINES+=("毕竟连 Threads 也从来不是答案。")
TAGLINES+=("你的消息，你的服务器，让Meta默默流泪。")
TAGLINES+=("自带绿色气泡的iMessage气场，但所有人都能用。")
TAGLINES+=("Siri 那位靠谱的表亲。")
TAGLINES+=("兼容安卓系统。我们知道，这概念听着很疯狂。")
TAGLINES+=("无需999美元的支架。")
TAGLINES+=("我们上线功能的速度，比苹果更新计算器都快。")
TAGLINES+=("你的AI助手，现在无需3499美元的头显。")
TAGLINES+=("独具匠心，独立思考。")
TAGLINES+=("啊，是那棵苹果树公司！🍎")

HOLIDAY_NEW_YEAR="元旦版: 新的一年，新的配置——还是熟悉的端口占用报错，但这次我们成熟地解决它。"
HOLIDAY_LUNAR_NEW_YEAR="农历新年版: 愿构建好运连连，分支兴旺发达，合并冲突通通被烟花赶跑！"
HOLIDAY_CHRISTMAS="圣诞节版: 吼吼吼——圣诞老人的小助手来啦，负责上线快乐、回滚混乱，还帮你把密钥好好藏起来。"
HOLIDAY_EID="开斋节版: 欢庆模式开启：队列已清空，任务全完成，好心情带着干净提交记录，合并到 main 分支。"
HOLIDAY_DIWALI="排灯节版: 愿日志闪耀，Bug 退散——今天我们点亮终端，自豪地上线发布。"
HOLIDAY_EASTER="复活节版: 我找到你丢失的环境变量啦——就当是一场 CLI 寻蛋游戏，只是少了点软糖而已。"
HOLIDAY_HANUKKAH="光明节版: 八个夜晚，八次重试，不必难为情——愿你的网关长明，部署一路安稳。"
HOLIDAY_HALLOWEEN="万圣节版: 惊悚时刻来袭：小心闹鬼的依赖、被诅咒的缓存，还有 node_modules 里徘徊不散的幽灵。"
HOLIDAY_THANKSGIVING="感恩节版: 感谢稳定的端口、正常运行的 DNS，还有一个会自动读日志的机器人，从此不用人再辛苦盯日志。"
HOLIDAY_VALENTINES="情人节版: 玫瑰是敲出来的，紫罗兰是管道传的——我来帮你自动化琐事，好让你专心陪身边人。"

append_holiday_taglines() {
    local today
    local month_day
    today="$(date -u +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)"
    month_day="$(date -u +%m-%d 2>/dev/null || date +%m-%d)"

    case "$month_day" in
        "01-01") TAGLINES+=("$HOLIDAY_NEW_YEAR") ;;
        "02-14") TAGLINES+=("$HOLIDAY_VALENTINES") ;;
        "10-31") TAGLINES+=("$HOLIDAY_HALLOWEEN") ;;
        "12-25") TAGLINES+=("$HOLIDAY_CHRISTMAS") ;;
    esac

    case "$today" in
        "2025-01-29"|"2026-02-17"|"2027-02-06") TAGLINES+=("$HOLIDAY_LUNAR_NEW_YEAR") ;;
        "2025-03-30"|"2025-03-31"|"2026-03-20"|"2027-03-10") TAGLINES+=("$HOLIDAY_EID") ;;
        "2025-10-20"|"2026-11-08"|"2027-10-28") TAGLINES+=("$HOLIDAY_DIWALI") ;;
        "2025-04-20"|"2026-04-05"|"2027-03-28") TAGLINES+=("$HOLIDAY_EASTER") ;;
        "2025-11-27"|"2026-11-26"|"2027-11-25") TAGLINES+=("$HOLIDAY_THANKSGIVING") ;;
        "2025-12-15"|"2025-12-16"|"2025-12-17"|"2025-12-18"|"2025-12-19"|"2025-12-20"|"2025-12-21"|"2025-12-22"|"2026-12-05"|"2026-12-06"|"2026-12-07"|"2026-12-08"|"2026-12-09"|"2026-12-10"|"2026-12-11"|"2026-12-12"|"2027-12-25"|"2027-12-26"|"2027-12-27"|"2027-12-28"|"2027-12-29"|"2027-12-30"|"2027-12-31"|"2028-01-01") TAGLINES+=("$HOLIDAY_HANUKKAH") ;;
    esac
}

map_legacy_env() {
    local key="$1"
    local legacy="$2"
    if [[ -z "${!key:-}" && -n "${!legacy:-}" ]]; then
        printf -v "$key" '%s' "${!legacy}"
    fi
}

map_legacy_env "OPENAEON_TAGLINE_INDEX" "AEONPROPHET_TAGLINE_INDEX"
map_legacy_env "OPENAEON_NO_ONBOARD" "AEONPROPHET_NO_ONBOARD"
map_legacy_env "OPENAEON_NO_PROMPT" "AEONPROPHET_NO_PROMPT"
map_legacy_env "OPENAEON_DRY_RUN" "AEONPROPHET_DRY_RUN"
map_legacy_env "OPENAEON_INSTALL_METHOD" "AEONPROPHET_INSTALL_METHOD"
map_legacy_env "OPENAEON_VERSION" "AEONPROPHET_VERSION"
map_legacy_env "OPENAEON_BETA" "AEONPROPHET_BETA"
map_legacy_env "OPENAEON_GIT_DIR" "AEONPROPHET_GIT_DIR"
map_legacy_env "OPENAEON_GIT_UPDATE" "AEONPROPHET_GIT_UPDATE"
map_legacy_env "OPENAEON_NPM_LOGLEVEL" "AEONPROPHET_NPM_LOGLEVEL"
map_legacy_env "OPENAEON_VERBOSE" "AEONPROPHET_VERBOSE"
map_legacy_env "OPENAEON_PROFILE" "AEONPROPHET_PROFILE"
map_legacy_env "OPENAEON_INSTALL_SH_NO_RUN" "AEONPROPHET_INSTALL_SH_NO_RUN"

pick_tagline() {
    append_holiday_taglines
    local count=${#TAGLINES[@]}
    if [[ "$count" -eq 0 ]]; then
        echo "$DEFAULT_TAGLINE"
        return
    fi
    if [[ -n "${OPENAEON_TAGLINE_INDEX:-}" ]]; then
        if [[ "${OPENAEON_TAGLINE_INDEX}" =~ ^[0-9]+$ ]]; then
            local idx=$((OPENAEON_TAGLINE_INDEX % count))
            echo "${TAGLINES[$idx]}"
            return
        fi
    fi
    local idx=$((RANDOM % count))
    echo "${TAGLINES[$idx]}"
}

TAGLINE=$(pick_tagline)

NO_ONBOARD=${OPENAEON_NO_ONBOARD:-0}
NO_PROMPT=${OPENAEON_NO_PROMPT:-0}
DRY_RUN=${OPENAEON_DRY_RUN:-0}
INSTALL_METHOD=${OPENAEON_INSTALL_METHOD:-}
OPENAEON_VERSION=${OPENAEON_VERSION:-latest}
USE_BETA=${OPENAEON_BETA:-0}
GIT_DIR_DEFAULT="${HOME}/openaeon"
GIT_DIR=${OPENAEON_GIT_DIR:-$GIT_DIR_DEFAULT}
GIT_UPDATE=${OPENAEON_GIT_UPDATE:-1}
SHARP_IGNORE_GLOBAL_LIBVIPS="${SHARP_IGNORE_GLOBAL_LIBVIPS:-1}"
NPM_LOGLEVEL="${OPENAEON_NPM_LOGLEVEL:-error}"
NPM_SILENT_FLAG="--silent"
VERBOSE="${OPENAEON_VERBOSE:-0}"
OPENAEON_BIN=""
PNPM_CMD=()
HELP=0

print_usage() {
    cat <<EOF
OpenAEON 安装脚本（支持 macOS + Linux）

用法:
  curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash -s -- [options]

选项:
  --install-method, --method npm|git  通过 npm（默认）或 git 源码安装
  --npm                               快捷方式 --install-method npm
  --git, --github                     快捷方式 --install-method git
  --version <版本|分发标签>              npm 安装: 指定版本（默认: latest）
  --beta                               使用测试版（如可用），否则使用最新版
  --git-dir, --dir <路径>               Git 目录（默认: ~/openaeon）
  --no-git-update                       跳过对已有仓库执行 git pull
  --no-onboard                          跳过初始化引导（非交互模式）
  --no-prompt                           禁用交互提示（CI/自动化环境必需）
  --dry-run                             仅预览执行内容，不做实际修改
  --verbose                             输出调试日志（set -x、npm 详细模式）
  --help, -h                            显示帮助信息

环境变量:
  OPENAEON_INSTALL_METHOD=git|npm
  OPENAEON_VERSION=latest|next|<语义化版本>
  OPENAEON_BETA=0|1
  OPENAEON_GIT_DIR=...
  OPENAEON_GIT_UPDATE=0|1
  OPENAEON_NO_PROMPT=1
  OPENAEON_DRY_RUN=1
  OPENAEON_NO_ONBOARD=1
  OPENAEON_VERBOSE=1
  OPENAEON_NPM_LOGLEVEL=error|warn|notice  默认值: error （隐藏 npm 弃用相关提示信息）
  SHARP_IGNORE_GLOBAL_LIBVIPS=0|1    默认值: 1 （避免 sharp 基于全局 libvips 进行编译构建）

示例:
  curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash
  curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash -s -- --no-onboard
  curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash -s -- --install-method git --no-onboard
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-onboard)
                NO_ONBOARD=1
                shift
                ;;
            --onboard)
                NO_ONBOARD=0
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --no-prompt)
                NO_PROMPT=1
                shift
                ;;
            --help|-h)
                HELP=1
                shift
                ;;
            --install-method|--method)
                INSTALL_METHOD="$2"
                shift 2
                ;;
            --version)
                OPENAEON_VERSION="$2"
                shift 2
                ;;
            --beta)
                USE_BETA=1
                shift
                ;;
            --npm)
                INSTALL_METHOD="npm"
                shift
                ;;
            --git|--github)
                INSTALL_METHOD="git"
                shift
                ;;
            --git-dir|--dir)
                GIT_DIR="$2"
                shift 2
                ;;
            --no-git-update)
                GIT_UPDATE=0
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

configure_verbose() {
    if [[ "$VERBOSE" != "1" ]]; then
        return 0
    fi
    if [[ "$NPM_LOGLEVEL" == "error" ]]; then
        NPM_LOGLEVEL="notice"
    fi
    NPM_SILENT_FLAG=""
    set -x
}

is_promptable() {
    if [[ "$NO_PROMPT" == "1" ]]; then
        return 1
    fi
    if [[ -t 0 && -r /dev/tty && -w /dev/tty ]]; then
        return 0
    fi
    return 1
}

prompt_choice() {
    local prompt="$1"
    local answer=""
    if ! is_promptable; then
        return 1
    fi
    echo -e "$prompt" > /dev/tty
    read -r answer < /dev/tty || true
    echo "$answer"
}

choose_install_method_interactive() {
    local detected_checkout="$1"

    if ! is_promptable; then
        return 1
    fi

    if [[ -n "$GUM" ]] && gum_is_tty; then
        local header selection
        header="检测到 OpenAEON 源码目录: ${detected_checkout}
请选择安装方式"
        selection="$("$GUM" choose \
            --header "$header" \
            --cursor-prefix "❯ " \
            "git  · 更新此源码并使用" \
            "npm  · 通过 npm 全局安装" < /dev/tty || true)"

        case "$selection" in
            git*)
                echo "git"
                return 0
                ;;
            npm*)
                echo "npm"
                return 0
                ;;
        esac
        return 1
    fi

    local choice=""
    choice="$(prompt_choice "$(cat <<EOF
${WARN}→${NC} 检测到 OpenAEON 源码目录: ${INFO}${detected_checkout}${NC}
请选择安装方式:
  1) 更新此源码（git）并直接使用
  2) 通过 npm 全局安装（从 git 迁移）
输入 1 或 2:
EOF
)" || true)"

    case "$choice" in
        1)
            echo "git"
            return 0
            ;;
        2)
            echo "npm"
            return 0
            ;;
    esac

    return 1
}

# 主动检查 macOS 上的 Xcode 命令行工具
check_xcode_tools_proactive() {
    if [[ "$OS" != "macos" ]]; then
        return 0
    fi

    if xcode-select -p &>/dev/null; then
        return 0
    fi

    ui_warn "检测到 macOS，但未配置 Xcode 命令行工具。"
    ui_info "正在触发开发者工具安装提示..."
    xcode-select --install &>/dev/null || true
    
    echo ""
    ui_important "需要操作：请在弹出的 macOS 窗口中安装命令行工具。"
    ui_important "请完成安装后，重新运行此脚本。"
    echo ""
    
    if ! is_promptable; then
        ui_error "非交互式环境，无法等待 Xcode 工具安装。请手动安装后重试。"
        exit 1
    fi

    ui_info "正在等待你完成 Xcode 命令行工具的安装..."
    while ! xcode-select -p &>/dev/null; do
        sleep 5
    done
    ui_success "已检测到 Xcode 命令行工具！继续执行..."
}

detect_openaeon_checkout() {
    local dir="$1"
    
    # 用于校验的辅助函数
    _is_openaeon_repo() {
        local d="$1"
        [[ -f "$d/package.json" && -f "$d/pnpm-workspace.yaml" ]] && \
        grep -q '"name"[[:space:]]*:[[:space:]]*"openaeon"' "$d/package.json" 2>/dev/null
    }

    if [[ -n "$dir" ]] && _is_openaeon_repo "$dir"; then
        echo "$dir"
        return 0
    fi

    # 检查当前脚本的上级目录是否为项目仓库
    local script_dir=""
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    if _is_openaeon_repo "$script_dir"; then
        echo "$script_dir"
        return 0
    fi

    return 1
}

# 检查 macOS 上的 Homebrew
is_macos_admin_user() {
    if [[ "$OS" != "macos" ]]; then
        return 0
    fi
    if is_root; then
        return 0
    fi
    # 检查当前用户是否属于管理员组
    if ! id -Gn "$(id -un)" 2>/dev/null | grep -qw "admin"; then
        return 1
    fi
    # 若非交互模式，则必须配置免密码 sudo 或已缓存 sudo 权限
    if ! is_promptable; then
        if ! sudo -n true 2>/dev/null; then
            return 1
        fi
    fi
    return 0
}

print_homebrew_admin_fix() {
    local current_user
    current_user="$(id -un 2>/dev/null || echo "${USER:-current user}")"
    ui_error "安装 Homebrew 需要使用 macOS 管理员账户"
    echo "当前用户（${current_user}）不在管理员组中。"
    echo "修复方法:"
    echo "  1) 使用管理员账户重新运行安装程序。"
    echo "  2) 请管理员为你授予管理员权限，然后注销并重新登录:"
    echo "     sudo dseditgroup -o edit -a ${current_user} -t user admin"
    echo "之后重试安装:"
    echo "  curl -fsSL https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash"
}

install_homebrew() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            if ! is_macos_admin_user; then
                ui_warn "未找到 Homebrew，且本次会话无法安装（需要管理员权限/sudo 或交互式终端）"
                return 1
            fi
            ui_info "未找到 Homebrew，正在安装..."
            # Use non-interactive flag for Homebrew installer if stdin is not a TTY
            local hb_installer="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
            if ! is_promptable; then
                run_quiet_step "正在安装 Homebrew..." run_remote_bash "$hb_installer"
            else
                # 若支持交互提示，则将标准输入回传
                run_quiet_step "正在安装 Homebrew..." run_remote_bash "$hb_installer"
            fi

            # 为本会话将 Homebrew 添加到环境变量 PATH 中
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            ui_success "Homebrew 安装完成"
        else
            ui_success "Homebrew 已安装"
        fi
    fi
}

# 检查 Node.js 版本
node_major_version() {
    if ! command -v node &> /dev/null; then
        return 1
    fi
    local version major
    version="$(node -v 2>/dev/null || true)"
    major="${version#v}"
    major="${major%%.*}"
    if [[ "$major" =~ ^[0-9]+$ ]]; then
        echo "$major"
        return 0
    fi
    return 1
}

print_active_node_paths() {
    if ! command -v node &> /dev/null; then
        return 1
    fi
    local node_path node_version npm_path npm_version
    node_path="$(command -v node 2>/dev/null || true)"
    node_version="$(node -v 2>/dev/null || true)"
    ui_info "当前 Node.js: ${node_version:-unknown} (${node_path:-unknown})"

    if command -v npm &> /dev/null; then
        npm_path="$(command -v npm 2>/dev/null || true)"
        npm_version="$(npm -v 2>/dev/null || true)"
        ui_info "当前 npm: ${npm_version:-unknown} (${npm_path:-unknown})"
    fi
    return 0
}

ensure_macos_node22_active() {
    if [[ "$OS" != "macos" ]]; then
        return 0
    fi

    local brew_node_prefix=""
    if command -v brew &> /dev/null; then
        brew_node_prefix="$(brew --prefix node@22 2>/dev/null || true)"
        if [[ -n "$brew_node_prefix" && -x "${brew_node_prefix}/bin/node" ]]; then
            export PATH="${brew_node_prefix}/bin:$PATH"
            refresh_shell_command_cache
        fi
    fi

    local major=""
    major="$(node_major_version || true)"
    if [[ -n "$major" && "$major" -ge 22 ]]; then
        return 0
    fi

    local active_path active_version
    active_path="$(command -v node 2>/dev/null || echo "not found")"
    active_version="$(node -v 2>/dev/null || echo "missing")"

    ui_error "已安装 Node.js v22，但当前 Shell 使用的是 {active_version} (路径: {active_path})"
    if [[ -n "$brew_node_prefix" ]]; then
        echo "将此内容添加到你的 Shell 配置文件中，然后重启终端:"
        echo "  export PATH=\"${brew_node_prefix}/bin:\$PATH\""
    else
        echo "请确保 Homebrew 的 node@22 在 PATH 中优先，然后重新运行安装程序"
    fi
    return 1
}

check_node() {
    if command -v node &> /dev/null; then
        NODE_VERSION="$(node_major_version || true)"
        if [[ -n "$NODE_VERSION" && "$NODE_VERSION" -ge 22 ]]; then
            ui_success "已检测到 Node.js v$(node -v | cut -d'v' -f2)"
            print_active_node_paths || true
            return 0
        else
            if [[ -n "$NODE_VERSION" ]]; then
                ui_info "已检测到 Node.js $(node -v)，正在升级至 v22+ 版本"
            else
                ui_info "已找到 Node.js，但无法解析版本，正在重新安装 v22+ 版本"
            fi
            return 1
        fi
    else
        ui_info "未找到 Node.js，正在安装..."
        return 1
    fi
}

# Install standalone Node.js (fallback)
install_node_standalone() {
    local version="22.13.1"
    local arch=""
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) ui_error "不支持的系统架构: $(uname -m)"; return 1 ;;
    esac

    local node_dir="${PREFIX:-$HOME/.openaeon}/nodejs"
    mkdir -p "$node_dir"

    local os_name=""
    case "$OS" in
        macos) os_name="darwin" ;;
        linux) os_name="linux" ;;
        *) ui_error "当前操作系统不支持独立版 Node: $OS"; return 1 ;;
    esac

    local tarball="node-v${version}-${os_name}-${arch}.tar.gz"
    local url="https://nodejs.org/dist/v${version}/${tarball}"

    ui_info "正在为 {os_name}-{arch} 下载独立版 Node.js v${version}..."
    if ! curl -fsSL "$url" -o "/tmp/${tarball}"; then
        ui_error "从 $url 下载 Node.js 失败"
        return 1
    fi

    ui_info "正在解压 Node.js..."
    if ! tar -xzf "/tmp/${tarball}" -C "$node_dir" --strip-components=1; then
        ui_error "Node.js 解压失败"
        rm -f "/tmp/${tarball}"
        return 1
    fi
    rm -f "/tmp/${tarball}"

    # 为脚本后续执行添加 PATH 环境变量
    export PATH="${node_dir}/bin:$PATH"

    # 确保可执行文件已加入永久 PATH
    ensure_bin_on_path "${node_dir}/bin"

    ui_success "独立版 Node.js 已安装至 ${node_dir}"
    return 0
}

# 安装 Node.js
install_node() {
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            ui_info "正在通过 Homebrew 安装 Node.js"
            if run_quiet_step "正在安装 node@22" brew install node@22; then
                brew link node@22 --overwrite --force 2>/dev/null || true
                if ensure_macos_node22_active; then
                    ui_success "已通过 Homebrew 安装 Node.js"
                    print_active_node_paths || true
                    return 0
                fi
            fi
            ui_warn "通过Homebrew安装Node.js失败，正在尝试独立安装方案作为备用"
        fi

        if install_node_standalone; then
            return 0
        fi

        ui_error "自动安装 Node.js 失败。"
        ui_info "请手动安装 Node.js v22 及以上版本: https://nodejs.org/en/download/"
        exit 1
    elif [[ "$OS" == "linux" ]]; then
        if [[ "$(id -u)" -eq 0 ]] || is_promptable || sudo -n true 2>/dev/null; then
            ui_info "正在通过 NodeSource 安装 Node.js"
            ui_info "正在安装Linux构建工具 (make/g++/cmake/python3)"
            if ! install_build_tools_linux; then
                ui_warn "继续执行，暂不自动安装构建工具"
            fi

            if command -v apt-get &> /dev/null; then
                local tmp
                tmp="$(mktempfile)"
                download_file "https://deb.nodesource.com/setup_24.x" "$tmp"
                if is_root; then
                    run_quiet_step "正在配置 NodeSource 软件源" bash "$tmp"
                    run_quiet_step "正在安装 Node.js" apt-get install -y -qq nodejs
                else
                    run_quiet_step "正在配置 NodeSource 软件源" sudo -E bash "$tmp"
                    run_quiet_step "正在安装 Node.js" sudo apt-get install -y -qq nodejs
                fi
            elif command -v dnf &> /dev/null; then
                local tmp
                tmp="$(mktempfile)"
                download_file "https://rpm.nodesource.com/setup_24.x" "$tmp"
                if is_root; then
                    run_quiet_step "正在配置 NodeSource 软件源" bash "$tmp"
                    run_quiet_step "正在安装 Node.js" dnf install -y -q nodejs
                else
                    run_quiet_step "正在配置 NodeSource 软件源" sudo bash "$tmp"
                    run_quiet_step "正在安装 Node.js" sudo dnf install -y -q nodejs
                fi
            elif command -v yum &> /dev/null; then
                local tmp
                tmp="$(mktempfile)"
                download_file "https://rpm.nodesource.com/setup_24.x" "$tmp"
                if is_root; then
                    run_quiet_step "正在配置 NodeSource 软件源" bash "$tmp"
                    run_quiet_step "正在安装 Node.js" yum install -y -q nodejs
                else
                    run_quiet_step "正在配置 NodeSource 软件源" sudo bash "$tmp"
                    run_quiet_step "正在安装 Node.js" sudo yum install -y -q nodejs
                fi
            else
                ui_warn "未找到适用于 NodeSource 的受支持包管理器，正在尝试独立安装"
                if install_node_standalone; then
                    return 0
                fi
            fi

            if command -v node &> /dev/null && [[ "$(node_major_version)" -ge 22 ]]; then
                ui_success "已通过包管理器安装 Node.js v22+"
                print_active_node_paths || true
                return 0
            fi
        fi

        # Standalone fallback for Linux
        if install_node_standalone; then
            return 0
        fi

        ui_error "自动安装 Node.js 失败。"
        ui_info "请手动安装 Node.js v22 及以上版本: https://nodejs.org"
        exit 1
    fi
}

# 检查 Git
check_git() {
    if ! command -v git &> /dev/null; then
        ui_info "未找到 Git，正在安装"
        return 1
    fi

    # 在 macOS 上，git 可能只是一个替身程序，会触发 Xcode 命令行工具安装或需要接受许可协议
    if [[ "$OS" == "macos" ]]; then
        if ! xcode-select -p &>/dev/null; then
            ui_warn "已找到 Git，但未配置 Xcode 开发者工具"
            return 1
        fi
    fi

    ui_success "Git 已安装"
    return 0
}

is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# 若当前非 root 用户，则使用 sudo 执行命令
maybe_sudo() {
    if is_root; then
        # 若为 root 用户则跳过 -E 参数（环境变量已保留）
        if [[ "${1:-}" == "-E" ]]; then
            shift
        fi
        "$@"
    else
        sudo "$@"
    fi
}

require_sudo() {
    if [[ "$OS" != "linux" ]]; then
        return 0
    fi
    if is_root; then
        return 0
    fi
    if command -v sudo &> /dev/null; then
        if ! sudo -n true >/dev/null 2>&1; then
            ui_info "需要管理员权限，请输入密码"
            sudo -v
        fi
        return 0
    fi
    ui_error "在Linux系统中执行全局安装，需要使用sudo获取管理员权限"
    echo "  请安装 sudo 或以 root 身份重新运行。"
    exit 1
}

install_git() {
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            run_quiet_step "正在安装 Git..." brew install git
        else
            ui_info "正在尝试触发 Xcode 命令行工具安装..."
            xcode-select --install &>/dev/null || true
            ui_warn "未找到 Homebrew，且未配置 Xcode 命令行工具。"
            ui_info "请按照 macOS 弹窗提示安装开发者工具，然后重新运行此脚本。"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        require_sudo
        if command -v apt-get &> /dev/null; then
            if is_root; then
                run_quiet_step "正在更新软件包索引..." apt-get update -qq
                run_quiet_step "正在安装 Git..." apt-get install -y -qq git
            else
                run_quiet_step "正在更新软件包索引..." sudo apt-get update -qq
                run_quiet_step "正在安装 Git..." sudo apt-get install -y -qq git
            fi
        elif command -v dnf &> /dev/null; then
            if is_root; then
                run_quiet_step "正在安装 Git..." dnf install -y -q git
            else
                run_quiet_step "正在安装 Git..." sudo dnf install -y -q git
            fi
        elif command -v yum &> /dev/null; then
            if is_root; then
                run_quiet_step "正在安装 Git..." yum install -y -q git
            else
                run_quiet_step "正在安装 Git..." sudo yum install -y -q git
            fi
        else
            ui_error "无法检测到用于 Git 的包管理器"
            exit 1
        fi
    fi
    ui_success "Git 已安装"
}

# Fix npm permissions for global installs (Linux)
fix_npm_permissions() {
    if [[ "$OS" != "linux" ]]; then
        return 0
    fi

    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -z "$npm_prefix" ]]; then
        return 0
    fi

    if [[ -w "$npm_prefix" || -w "$npm_prefix/lib" ]]; then
        return 0
    fi

    ui_info "正在为用户本地安装配置 npm..."
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"

    # 禁用 shellcheck 对 SC2016 规则的检查
    local path_line='export PATH="$HOME/.npm-global/bin:$PATH"'
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -q ".npm-global" "$rc"; then
            echo "$path_line" >> "$rc"
        fi
    done

    export PATH="$HOME/.npm-global/bin:$PATH"
    ui_success "已为用户安装配置 npm"
}

ensure_openaeon_bin_link() {
    local npm_root=""
    npm_root="$(npm root -g 2>/dev/null || true)"
    if [[ -z "$npm_root" || ! -d "$npm_root/openaeon" ]]; then
        return 1
    fi
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ -z "$npm_bin" ]]; then
        return 1
    fi
    mkdir -p "$npm_bin"
    if [[ ! -x "${npm_bin}/openaeon" ]]; then
        ln -sf "$npm_root/openaeon/dist/entry.js" "${npm_bin}/openaeon"
        ui_info "已在 ${npm_bin}/openaeon 创建 openaeon 可执行文件链接"
    fi
    return 0
}

# 检查已存在的 OpenAEON 安装
check_existing_openaeon() {
    if [[ -n "$(type -P openaeon 2>/dev/null || true)" ]]; then
        ui_info "检测到已存在 OpenAEON 安装"
        return 0
    fi
    return 1
}

# 卸载已有的 OpenAEON 后台服务与可执行文件
uninstall_existing_openaeon() {
    ui_info "正在安装自定义版本前，尝试卸载现有版本..."
    
    # 尝试移除网关服务（如可访问）
    if command -v openaeon >/dev/null 2>&1; then
        openaeon gateway uninstall --force >/dev/null 2>&1 || true
    fi

    # 尝试卸载通用 NPM 包
    ui_info "  正在全局卸载 NPM 版本 openaeon..."
    npm uninstall -g openaeon >/dev/null 2>&1 || true
    
    ui_success "旧版 OpenAEON 已清理完毕（如存在）"
}

set_pnpm_cmd() {
    PNPM_CMD=("$@")
}

pnpm_cmd_pretty() {
    if [[ ${#PNPM_CMD[@]} -eq 0 ]]; then
        echo ""
        return 1
    fi
    printf '%s' "${PNPM_CMD[*]}"
    return 0
}

pnpm_cmd_is_ready() {
    if [[ ${#PNPM_CMD[@]} -eq 0 ]]; then
        return 1
    fi
    "${PNPM_CMD[@]}" --version >/dev/null 2>&1
}

detect_pnpm_cmd() {
    if command -v pnpm &> /dev/null; then
        set_pnpm_cmd pnpm
        return 0
    fi
    if command -v corepack &> /dev/null; then
        if corepack pnpm --version >/dev/null 2>&1; then
            set_pnpm_cmd corepack pnpm
            return 0
        fi
    fi
    return 1
}

ensure_pnpm() {
    if detect_pnpm_cmd && pnpm_cmd_is_ready; then
        ui_success "pnpm 准备就绪 ($(pnpm_cmd_pretty))"
        return 0
    fi

    if command -v corepack &> /dev/null; then
        ui_info "正在通过 Corepack 配置 pnpm..."
        corepack enable >/dev/null 2>&1 || true
        if ! run_quiet_step "正在激活 pnpm..." corepack prepare pnpm@10 --activate; then
            ui_warn "Corepack pnpm 激活失败（可能是签名校验问题），正在回退到 npm install 方式安装"
        fi
        refresh_shell_command_cache
        if detect_pnpm_cmd && pnpm_cmd_is_ready; then
            if [[ "${PNPM_CMD[*]}" == "corepack pnpm" ]]; then
                ui_warn "pnpm 存根不在 PATH 中；使用 corepack pnpm 作为备用方案"
            fi
            ui_success "pnpm 准备就绪 ($(pnpm_cmd_pretty))"
            return 0
        fi
    fi

    ui_info "正在通过 npm 安装 pnpm..."
    fix_npm_permissions
    run_quiet_step "正在安装 pnpm..." npm install -g pnpm@10 --force
    refresh_shell_command_cache
    if detect_pnpm_cmd && pnpm_cmd_is_ready; then
        ui_success "pnpm 准备就绪 ($(pnpm_cmd_pretty))"
        return 0
    fi

    ui_error "pnpm 安装失败"
    return 1
}

ensure_pnpm_binary_for_scripts() {
    if command -v pnpm >/dev/null 2>&1; then
        return 0
    fi

    if command -v corepack >/dev/null 2>&1; then
        ui_info "正在确保 pnpm 命令可用..."
        corepack enable >/dev/null 2>&1 || true
        corepack prepare pnpm@10 --activate >/dev/null 2>&1 || true
        refresh_shell_command_cache
        if command -v pnpm >/dev/null 2>&1; then
            ui_success "已通过 Corepack 启用 pnpm 命令"
            return 0
        fi
    fi

    if [[ "${PNPM_CMD[*]}" == "corepack pnpm" ]] && command -v corepack >/dev/null 2>&1; then
        ensure_user_local_bin_on_path
        local user_pnpm="${HOME}/.local/bin/pnpm"
        
        cat >"${user_pnpm}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec corepack pnpm "$@"
EOF
        chmod +x "${user_pnpm}"
        refresh_shell_command_cache

        if command -v pnpm >/dev/null 2>&1; then
            ui_warn "pnpm 存根文件不在 PATH 中；已在 ${user_pnpm} 安装用户本地包装脚本"
            return 0
        fi
    fi

    ui_error "npm 命令不在当前 PATH 中，无法使用"
    ui_info "请全局安装 pnpm（npm install -g pnpm@10）后重试"
    return 1
}

run_pnpm() {
    if ! pnpm_cmd_is_ready; then
        ensure_pnpm
    fi
    "${PNPM_CMD[@]}" "$@"
}

ensure_bin_on_path() {
    local target="$1"
    if [[ -z "$target" ]]; then
        return 0
    fi
    mkdir -p "$target"

    if [[ ":$PATH:" != *":$target:"* ]]; then
        export PATH="$target:$PATH"
    fi

    # 如果路径以 /Users/ 或 /home/ 开头，为配置文件转义 $HOME
    local path_line
    if [[ "$target" == "$HOME"* ]]; then
        local relative_target="${target#$HOME/}"
        path_line='export PATH="$HOME/'"${relative_target}"':$PATH"'
    else
        path_line='export PATH="'"${target}"':$PATH"'
    fi

    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -q "$target" "$rc"; then
            echo "$path_line" >> "$rc"
        fi
    done
}

ensure_user_local_bin_on_path() {
    ensure_bin_on_path "$HOME/.local/bin"
}

npm_global_bin_dir() {
    local prefix=""
    prefix="$(npm prefix -g 2>/dev/null || true)"
    if [[ -n "$prefix" ]]; then
        if [[ "$prefix" == /* ]]; then
            echo "${prefix%/}/bin"
            return 0
        fi
    fi

    prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$prefix" && "$prefix" != "undefined" && "$prefix" != "null" ]]; then
        if [[ "$prefix" == /* ]]; then
            echo "${prefix%/}/bin"
            return 0
        fi
    fi

    echo ""
    return 1
}

refresh_shell_command_cache() {
    hash -r 2>/dev/null || true
}

path_has_dir() {
    local path="$1"
    local dir="${2%/}"
    if [[ -z "$dir" ]]; then
        return 1
    fi
    case ":${path}:" in
        *":${dir}:"*) return 0 ;;
        *) return 1 ;;
    esac
}

warn_shell_path_missing_dir() {
    local dir="${1%/}"
    local label="$2"
    if [[ -z "$dir" ]]; then
        return 0
    fi
    if path_has_dir "$ORIGINAL_PATH" "$dir"; then
        return 0
    fi

echo ""
    ui_warn "PATH 中缺少 {label}: {dir}"
    echo "  这会导致在新终端中 openaeon 显示为「command not found」。"
    echo "  修复方法（zsh：~/.zshrc，bash：~/.bashrc）:"
    echo "    export PATH=\"${dir}:\$PATH\""
}

ensure_npm_global_bin_on_path() {
    local bin_dir=""
    bin_dir="$(npm_global_bin_dir || true)"
    if [[ -n "$bin_dir" ]]; then
        export PATH="${bin_dir}:$PATH"
    fi
}

maybe_nodenv_rehash() {
    if command -v nodenv &> /dev/null; then
        nodenv rehash >/dev/null 2>&1 || true
    fi
}

warn_openaeon_not_found() {
    ui_warn "已安装完成，但当前 Shell 的环境变量 PATH 中无法找到 openaeon 命令"
    echo "  Try: 在 bash 中执行 hash -r，或在 zsh 中执行 rehash，然后重试。"
    local t=""
    t="$(type -t openaeon 2>/dev/null || true)"
    if [[ "$t" == "alias" || "$t" == "function" ]]; then
        ui_warn "检测到名为 openaeon 的 Shell 命令 ${t}，可能会覆盖真实的可执行文件"
    fi
    if command -v nodenv &> /dev/null; then
        echo -e "使用 nodenv? 请执行: ${INFO}nodenv rehash${NC}"
    fi

    local bin_dir=""
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        bin_dir="${PREFIX:-$HOME/.openaeon}/bin"
    else
        bin_dir="$(npm_global_bin_dir 2>/dev/null || true)"
    fi

    if [[ -n "$bin_dir" ]]; then
        echo -e "可执行文件路径: ${INFO}${bin_dir}${NC}"
        # 禁用 shellcheck 的 SC2016 规则检查
        echo -e "如需使用，请执行: ${INFO}export PATH=\"${bin_dir}:"'$PATH"'${NC}
    fi
}

resolve_openaeon_bin() {
    refresh_shell_command_cache
    resolved="$(type -P openaeon 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    local git_bin="${PREFIX:-$HOME/.openaeon}/bin/openaeon"
    if [[ -x "$git_bin" ]]; then
        echo "$git_bin"
        return 0
    fi

    ensure_npm_global_bin_on_path
    refresh_shell_command_cache
    resolved="$(type -P openaeon 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ -n "$npm_bin" && -x "${npm_bin}/openaeon" ]]; then
        echo "${npm_bin}/openaeon"
        return 0
    fi

    maybe_nodenv_rehash
    refresh_shell_command_cache
    resolved="$(type -P openaeon 2>/dev/null || true)"
    if [[ -n "$resolved" && -x "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi

    if [[ -n "$npm_bin" && -x "${npm_bin}/openaeon" ]]; then
        echo "${npm_bin}/openaeon"
        return 0
    fi

    echo ""
    return 1
}

install_openaeon_from_git() {
    local repo_dir="$1"
    local repo_url="https://github.com/gu2003li/OpenAEON.git"

    if [[ -d "$repo_dir/.git" ]]; then
        ui_info "正在从 Git 目录安装 OpenAEON: ${repo_dir}"
    else
        ui_info "正在从 GitHub 安装 OpenAEON (${repo_url})"
    fi

    if ! check_git; then
        install_git
    fi

    ensure_pnpm
    ensure_pnpm_binary_for_scripts

    if [[ ! -d "$repo_dir" ]]; then
        run_quiet_step "正在克隆 OpenAEON" git clone "$repo_url" "$repo_dir"
    fi

    if [[ "$GIT_UPDATE" == "1" ]]; then
        if [[ -z "$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)" ]]; then
            run_quiet_step "正在更新仓库" git -C "$repo_dir" pull --rebase || true
        else
            ui_info "仓库存在本地修改，跳过 git pull 操作。"
        fi
    fi

    cleanup_legacy_submodules "$repo_dir"

    # macOS TCC / EPERM awareness
    if [[ "$OS" == "macos" ]]; then
        if [[ "$repo_dir" == "$HOME/Documents"* || "$repo_dir" == "$HOME/Desktop"* ]]; then
            ui_warn "安装目录位于 macOS 受保护的文件夹中（${repo_dir}）"
            ui_info "如果 pnpm install 或构建因 EPERM 权限错误 失败，请在系统设置中为终端授予完全磁盘访问权限。"
        fi
    fi

    SHARP_IGNORE_GLOBAL_LIBVIPS="$SHARP_IGNORE_GLOBAL_LIBVIPS" run_quiet_step "正在安装依赖" run_pnpm -C "$repo_dir" install || {
        ui_error "依赖安装失败。"
        ui_info "请在 ${repo_dir} 目录下手动执行 'pnpm install' 命令重试"
        exit 1
    }

    if ! run_quiet_step "正在构建前端界面" run_pnpm -C "$repo_dir" ui:build; then
        ui_warn "前端界面构建失败（可能是权限不足 EPERM 或缺少开发工具）"
        ui_info "命令行工具仍可正常使用，但控制面板可能会缺失部分资源文件。"
        ui_info "修复方法: 在目录 ${repo_dir} 中手动运行命令 'pnpm ui:build'"
    fi
    run_quiet_step "正在编译 OpenAEON" run_pnpm -C "$repo_dir" build

    local bin_dir="${PREFIX:-$HOME/.openaeon}/bin"
    mkdir -p "$bin_dir"

    cat > "$bin_dir/openaeon" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec node "${repo_dir}/dist/entry.js" "\$@"
EOF
    chmod +x "$bin_dir/openaeon"
    ensure_bin_on_path "$bin_dir"
    ui_success "OpenAEON 启动器已安装到: $bin_dir/openaeon"
    ui_info "当前目录使用 pnpm — 请运行 pnpm install（或 corepack pnpm install）安装依赖"
}

# 安装 OpenAEON
resolve_beta_version() {
    local beta=""
    beta="$(npm view openaeon dist-tags.beta 2>/dev/null || true)"
    if [[ -z "$beta" || "$beta" == "undefined" || "$beta" == "null" ]]; then
        return 1
    fi
    echo "$beta"
}

install_openaeon() {
    local package_name="openaeon"
    if [[ "$USE_BETA" == "1" ]]; then
        local beta_version=""
        beta_version="$(resolve_beta_version || true)"
        if [[ -n "$beta_version" ]]; then
            OPENAEON_VERSION="$beta_version"
            ui_info "检测到测试版本标签 (${beta_version})"
            package_name="openaeon"
        else
            OPENAEON_VERSION="latest"
            ui_info "未找到测试版本标签，将使用最新版本"
        fi
    fi

    if [[ -z "${OPENAEON_VERSION}" ]]; then
        OPENAEON_VERSION="latest"
    fi

    local resolved_version=""
    resolved_version="$(npm view "${package_name}@${OPENAEON_VERSION}" version 2>/dev/null || true)"
    if [[ -n "$resolved_version" ]]; then
        ui_info "安装 OpenAEON v${resolved_version}"
    else
        ui_info "安装 OpenAEON (${OPENAEON_VERSION})"
    fi
    local install_spec=""
    if [[ "${OPENAEON_VERSION}" == "latest" ]]; then
        install_spec="${package_name}@latest"
    else
        install_spec="${package_name}@${OPENAEON_VERSION}"
    fi

    if ! install_openaeon_npm "${install_spec}"; then
        ui_warn "npm install failed; retrying"
        cleanup_npm_openaeon_paths
        install_openaeon_npm "${install_spec}"
    fi

    if [[ "${OPENAEON_VERSION}" == "latest" && "${package_name}" == "openaeon" ]]; then
        if ! resolve_openaeon_bin &> /dev/null; then
            ui_warn "npm install openaeon@latest failed; retrying openaeon@next"
            cleanup_npm_openaeon_paths
            install_openaeon_npm "openaeon@next"
        fi
    fi

    ensure_openaeon_bin_link || true

    ui_success "OpenAEON installed"
}

# Run doctor for migrations (safe, non-interactive)
run_doctor() {
    ui_info "正在运行检查工具以迁移配置"
    local claw="${OPENAEON_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openaeon_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_info "Skipping doctor (openaeon not on PATH yet)"
        warn_openaeon_not_found
        return 0
    fi
    run_quiet_step "Running doctor" "$claw" doctor --non-interactive || true
    ui_success "检查完成"
}

maybe_open_dashboard() {
    local claw="${OPENAEON_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openaeon_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        return 0
    fi
    if ! "$claw" dashboard --help >/dev/null 2>&1; then
        return 0
    fi
    "$claw" dashboard || true
}

resolve_workspace_dir() {
    local profile="${OPENAEON_PROFILE:-default}"
    if [[ "${profile}" != "default" ]]; then
        echo "${HOME}/.openaeon/workspace-${profile}"
    else
        echo "${HOME}/.openaeon/workspace"
    fi
}

run_bootstrap_onboarding_if_needed() {
    if [[ "${NO_ONBOARD}" == "1" ]]; then
        return
    fi

    local config_path="${OPENAEON_CONFIG_PATH:-$HOME/.openaeon.json}"
    if [[ -f "${config_path}" || -f "$HOME/.clawdbot/clawdbot.json" || -f "$HOME/.moltbot/moltbot.json" || -f "$HOME/.moldbot/moldbot.json" ]]; then
        return
    fi

    local workspace
    workspace="$(resolve_workspace_dir)"
    local bootstrap="${workspace}/BOOTSTRAP.md"

    if [[ ! -f "${bootstrap}" ]]; then
        return
    fi

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        ui_info "BOOTSTRAP.md found but no TTY; run openaeon onboard --install-daemon to finish setup"
        return
    fi

    ui_info "检测到 BOOTSTRAP.md；正在启动初始化引导"
    local claw="${OPENAEON_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openaeon_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        ui_info "BOOTSTRAP.md found but openaeon not on PATH; skipping onboarding"
        warn_openaeon_not_found
        return
    fi

    "$claw" onboard --install-daemon || {
        ui_error "Onboarding failed; run openaeon onboard --install-daemon to retry"
        return
    }
}

resolve_openaeon_version() {
    local version=""
    local claw="${OPENAEON_BIN:-}"
    if [[ -z "$claw" ]] && command -v openaeon &> /dev/null; then
        claw="$(command -v openaeon)"
    fi
    if [[ -n "$claw" ]]; then
        version=$("$claw" --version 2>/dev/null | head -n 1 | tr -d '\r')
    fi
    if [[ -z "$version" ]]; then
        local npm_root=""
        npm_root=$(npm root -g 2>/dev/null || true)
        if [[ -n "$npm_root" && -f "$npm_root/openaeon/package.json" ]]; then
            version=$(node -e "console.log(require('${npm_root}/openaeon/package.json').version)" 2>/dev/null || true)
        fi
    fi
    echo "$version"
}

is_gateway_daemon_loaded() {
    local claw="$1"
    if [[ -z "$claw" ]]; then
        return 1
    fi

    local status_json=""
    status_json="$("$claw" daemon status --json 2>/dev/null || true)"
    if [[ -z "$status_json" ]]; then
        return 1
    fi

    printf '%s' "$status_json" | node -e '
const fs = require("fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) process.exit(1);
try {
  const data = JSON.parse(raw);
  process.exit(data?.service?.loaded ? 0 : 1);
} catch {
  process.exit(1);
}
' >/dev/null 2>&1
}

refresh_gateway_service_if_loaded() {
    local claw="${OPENAEON_BIN:-}"
    if [[ -z "$claw" ]]; then
        claw="$(resolve_openaeon_bin || true)"
    fi
    if [[ -z "$claw" ]]; then
        return 0
    fi

    if ! is_gateway_daemon_loaded "$claw"; then
        return 0
    fi

    ui_info "Refreshing loaded gateway service"
    if run_quiet_step "Refreshing gateway service" "$claw" gateway install --force; then
        ui_success "Gateway service metadata refreshed"
    else
        ui_warn "Gateway service refresh failed; continuing"
        return 0
    fi

    if run_quiet_step "Restarting gateway service" "$claw" gateway restart; then
        ui_success "Gateway service restarted"
    else
        ui_warn "Gateway service restart failed; continuing"
        return 0
    fi

    run_quiet_step "Probing gateway service" "$claw" gateway status --probe --deep || true
}

# 主安装流程
main() {
    if [[ "$HELP" == "1" ]]; then
        print_usage
        return 0
    fi

    bootstrap_gum_temp || true
    print_installer_banner
    print_gum_status
    detect_os_or_die
    check_xcode_tools_proactive

    local detected_checkout=""
    detected_checkout="$(detect_openaeon_checkout "$PWD" || true)"

    if [[ -z "$INSTALL_METHOD" && -n "$detected_checkout" ]]; then
        if ! is_promptable; then
            ui_info "Found OpenAEON checkout but no TTY; defaulting to npm install"
            INSTALL_METHOD="npm"
        else
            local selected_method=""
            selected_method="$(choose_install_method_interactive "$detected_checkout" || true)"
            case "$selected_method" in
                git|npm)
                    INSTALL_METHOD="$selected_method"
                    ;;
                *)
                    ui_error "未选择安装方式"
                    echo "Re-run with: --install-method git|npm (or set OPENAEON_INSTALL_METHOD)."
                    exit 2
                    ;;
            esac
        fi
    fi

    if [[ -z "$INSTALL_METHOD" ]]; then
        INSTALL_METHOD="git"
    fi

    if [[ "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "git" ]]; then
        ui_error "invalid --install-method: ${INSTALL_METHOD}"
        echo "Use: --install-method npm|git"
        exit 2
    fi

    show_install_plan "$detected_checkout"

    if [[ "$DRY_RUN" == "1" ]]; then
        ui_success "Dry run complete (no changes made)"
        return 0
    fi

    # 检查是否已安装
    local is_upgrade=false
    if check_existing_openaeon; then
        is_upgrade=true
        uninstall_existing_openaeon
    fi
    local should_open_dashboard=false
    local skip_onboard=false

    ui_stage "准备环境"

    # 步骤 1：检测现有工具
    local has_node=false
    if check_node; then
        has_node=true
    fi

    # 步骤 2：安装 Homebrew（仅 macOS，且仅在工具缺失时）
    if [[ "$OS" == "macos" && "$has_node" == "false" ]]; then
        install_homebrew || true
    fi

    # 步骤 3：确保已安装 Node.js
    if [[ "$has_node" == "false" ]]; then
        if ! check_node; then
            install_node
        fi
    fi

    ui_stage "安装 OpenAEON"

    local final_git_dir=""
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        # 切换为 Git 安装时清理全局 NPM 安装包
        if npm list -g openaeon &>/dev/null; then
            ui_info "Removing npm global install (switching to git)"
            npm uninstall -g openaeon 2>/dev/null || true
            ui_success "npm global install removed"
        fi

        local repo_dir="$GIT_DIR"
        if [[ -n "$detected_checkout" ]]; then
            repo_dir="$detected_checkout"
        fi
        final_git_dir="$repo_dir"
        install_openaeon_from_git "$repo_dir"
    else
        # 切换为 npm 安装时清理 Git 包装脚本
        if [[ -x "$HOME/.local/bin/openaeon" ]]; then
            ui_info "Removing git wrapper (switching to npm)"
            rm -f "$HOME/.local/bin/openaeon"
            ui_success "git wrapper removed"
        fi

        # 步骤 3：安装 Git（部分 npm 安装需从 git 拉取或应用补丁，因此为必需）
        if ! check_git; then
            install_git
        fi

        # 配置 npm 权限（Linux 系统）
        fix_npm_permissions

        # 步骤 5：安装 OpenAEON
        install_openaeon
    fi

    ui_stage "完成配置"

    OPENAEON_BIN="$(resolve_openaeon_bin || true)"

    # 路径警告：安装可能成功完成，但用户登录 Shell 仍未包含 npm 全局可执行文件目录。
    local npm_bin=""
    npm_bin="$(npm_global_bin_dir || true)"
    if [[ "$INSTALL_METHOD" == "npm" ]]; then
        warn_shell_path_missing_dir "$npm_bin" "npm 全局二进制目录"
    fi
    if [[ "$INSTALL_METHOD" == "git" ]]; then
        if [[ -x "$HOME/.local/bin/openaeon" ]]; then
            warn_shell_path_missing_dir "$HOME/.local/bin" "用户本地二进制目录 (~/.local/bin)"
        fi
    fi

    refresh_gateway_service_if_loaded

    # 步骤 6：执行诊断检查，用于版本升级与 Git 安装时的数据迁移
    local run_doctor_after=false
    if [[ "$is_upgrade" == "true" || "$INSTALL_METHOD" == "git" ]]; then
        run_doctor_after=true
    fi
    if [[ "$run_doctor_after" == "true" ]]; then
        run_doctor
        should_open_dashboard=true
    fi

    # 若工作区中仍存在 BOOTSTRAP.md，则继续完成初始化引导流程
    run_bootstrap_onboarding_if_needed

    local installed_version
    installed_version=$(resolve_openaeon_version)

    echo ""
    if [[ -n "$installed_version" ]]; then
        ui_celebrate "🦞 OpenAEON 安装成功! (${installed_version})"
    else
        ui_celebrate "🦞 OpenAEON 安装成功!"
    fi
    if [[ "$is_upgrade" == "true" ]]; then
        local update_messages=(
            "升级完成！解锁新能力，不用客气。"
            "代码已更新，龙虾还是那个龙虾。"
            "回归并变得更强，你有没有想我？"
            "更新完成！外出期间学会了新技巧。"
            "升级完成！现在吐槽功力增加 23%。"
            "我已进化，请尽量跟上节奏。🦞"
            "新版本上线，依旧是那个熟悉的我。"
            "修复优化完成，准备继续工作。"
            "龙虾已完成蜕壳，外壳更硬，钳子更利。"
            "更新完成！可查看更新日志了解详情。"
            "从 npm 的升级中重生，现在更强了。"
            "离开后归来变得更聪明，你也可以试试。"
            "更新完成！问题都已修复。"
            "新版本安装完成，旧版已正式退休。"
            "固件已更新，运行更稳定。"
            "我经历了很多，总之现在已完成更新。"
            "重新上线，更新日志很长，但友谊更长。"
            "升级完成！若出现问题可检查更新内容。"
            "蜕壳完成，请忽略我的柔软过渡期。"
            "版本升级！同样高效，更少崩溃（大概）。"
        )
        local update_message
        update_message="${update_messages[RANDOM % ${#update_messages[@]}]}"
        echo -e "${MUTED}${update_message}${NC}"
    else
        local completion_messages=(
            "啊真不错，我喜欢这里。有什么吃的吗？"
            "家 sweet 家。放心，我不会乱动你的东西。"
            "已就位！让我们有序地搞点事情。"
            "安装完成！你的工作效率即将变得不一样。"
            "已安顿好，是时候自动化你的生活了。"
            "真舒服。我已经看过你的日程，我们得聊聊。"
            "终于部署完毕，现在告诉我你的问题。"
            "钳子咔嚓作响！好了，我们要做什么？"
            "龙虾已登陆，你的终端从此不一样。"
            "全部完成！我保证只稍微吐槽一下你的代码。"
        )
        local completion_message
        completion_message="${completion_messages[RANDOM % ${#completion_messages[@]}]}"
        echo -e "${MUTED}${completion_message}${NC}"
    fi
    echo ""

    if [[ "$INSTALL_METHOD" == "git" && -n "$final_git_dir" ]]; then
        ui_section "源码安装信息"
        ui_kv "检出目录" "$final_git_dir"
        ui_kv "启动脚本" "${PREFIX:-$HOME/.openaeon}/bin/openaeon"
        ui_kv "更新命令" "openaeon update --restart"
        ui_kv "切换至 npm 安装" "curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/gu2003li/OpenAEON/main/install.sh | bash -s -- --install-method npm"
    elif [[ "$is_upgrade" == "true" ]]; then
        ui_info "升级完成"
        if [[ -r /dev/tty && -w /dev/tty ]]; then
            local claw="${OPENAEON_BIN:-}"
            if [[ -z "$claw" ]]; then
                claw="$(resolve_openaeon_bin || true)"
            fi
            if [[ -z "$claw" ]]; then
                ui_info "跳过诊断（openaeon 尚未在 PATH 中）"
                warn_openaeon_not_found
                return 0
            fi
            local -a doctor_args=()
            if [[ "$NO_ONBOARD" == "1" ]]; then
                if "$claw" doctor --help 2>/dev/null | grep -q -- "--non-interactive"; then
                    doctor_args+=("--non-interactive")
                fi
            fi
            ui_info "正在运行 openaeon doctor 诊断"
            local doctor_ok=0
            if (( ${#doctor_args[@]} )); then
                OPENAEON_UPDATE_IN_PROGRESS=1 "$claw" doctor "${doctor_args[@]}" </dev/tty && doctor_ok=1
            else
                OPENAEON_UPDATE_IN_PROGRESS=1 "$claw" doctor </dev/tty && doctor_ok=1
            fi
            if (( doctor_ok )); then
                ui_info "正在更新插件"
                OPENAEON_UPDATE_IN_PROGRESS=1 "$claw" plugins update --all || true
            else
                ui_warn "诊断失败，跳过插件更新"
            fi
        else
            ui_info "未检测到终端；请手动执行 openaeon doctor 和 openaeon plugins update --all"
        fi
    else
        if [[ "$NO_ONBOARD" == "1" || "$skip_onboard" == "true" ]]; then
            ui_info "已跳过引导设置（根据请求）；稍后可执行 openaeon onboard --install-daemon"
        else
            local config_path="${OPENAEON_CONFIG_PATH:-$HOME/.openaeon.json}"
            if [[ -f "${config_path}" || -f "$HOME/.clawdbot/clawdbot.json" || -f "$HOME/.moltbot/moltbot.json" || -f "$HOME/.moldbot/moldbot.json" ]]; then
                ui_info "配置已存在，正在运行诊断"
                run_doctor
                should_open_dashboard=true
                ui_info "配置已存在，跳过引导设置"
                skip_onboard=true
            else
                if [[ -t 0 ]]; then
                    ui_info "正在启动引导设置（初始化）..."
                    echo ""
                    exec </dev/tty
                    exec "$claw" onboard --install-daemon
                else
                    ui_info "未检测到终端；请执行 openaeon onboard --install-daemon 以完成安装设置"
                    return 0
                fi
            fi
        fi
    fi
    if command -v openaeon &> /dev/null; then
        local claw="${OPENAEON_BIN:-}"
        if [[ -z "$claw" ]]; then
            claw="$(resolve_openaeon_bin || true)"
        fi
        if [[ -n "$claw" ]] && is_gateway_daemon_loaded "$claw"; then
            if [[ "$DRY_RUN" == "1" ]]; then
                ui_info "检测到网关守护进程；将执行重启 (openaeon daemon restart)"
            else
                ui_info "检测到网关守护进程；正在重启"
                if OPENAEON_UPDATE_IN_PROGRESS=1 "$claw" daemon restart >/dev/null 2>&1; then
                    ui_success "网关重启成功"
                else
                    ui_warn "网关重启失败；请重试: openaeon daemon restart"
                fi
            fi
        fi
    fi

    if [[ "$should_open_dashboard" == "true" ]]; then
        maybe_open_dashboard
    fi

    show_footer_links
}

if [[ "${OPENAEON_INSTALL_SH_NO_RUN:-0}" != "1" ]]; then
    parse_args "$@"
    configure_verbose
    main
fi