#!/bin/bash
# ============================================================
#  CHMODX Installer: cx-73rmux-k17
#  Descripción: Kit de Termux por categorías: base, terminal, desarrollo, redes, seguridad, multimedia, IA y más
#  Versión: 1.3.0  ·  Branding: CHMODX #018582
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Metadatos del proyecto (fuente única de verdad)
if [ -f "${PROJECT_ROOT}/chmodx.conf" ]; then
  # shellcheck source=/dev/null
  source "${PROJECT_ROOT}/chmodx.conf"
fi

# Librería común CHMODX
if [ -f "${PROJECT_ROOT}/lib/chmodx.sh" ]; then
  # shellcheck source=/dev/null
  source "${PROJECT_ROOT}/lib/chmodx.sh"
else
  echo "ERR: no se encontró lib/chmodx.sh en el proyecto" >&2
  exit 1
fi

# ------------------------------------------------------------
#  Funciones del proyecto (acciones de instalación)
# ------------------------------------------------------------
install_base()   { chmodx_pm_ensure git curl wget; }
install_python() { chmodx_pm_ensure python; }
install_node()   { chmodx_pm_ensure node; }
install_ux()     { chmodx_pm_ensure nano htop figlet; }

verify_report() {
  local -a profiles=("$@")
  local p i n total_unique installed_total pending_total
  local -a pkgs=() missing=()
  local -A missing_seen=()

  section "Verificación"
  [ "$CHMODX_QUIET" = 1 ] && return 0
  printf '  %bLeyenda:%b %b✓%b instalado · %b✗%b no instalado\n' \
    "$C_BOLD" "$C_RESET" "$C_SUCCESS" "$C_RESET" "$C_ERR" "$C_RESET"

  # Recarga el estado real: después de instalar, la lista del plan
  # ya no sirve. Comprueba todos los grupos, no solo la base.
  _plan_load_installed
  _PLAN_STATUS=()
  _PLAN_SEEN=()
  _collect_install_groups "${CHMODX_PLAN_BASE_ONLY:-0}" "${profiles[@]}"

  for i in "${!_INSTALL_GROUP_LABELS[@]}"; do
    read -r -a pkgs <<< "${_INSTALL_GROUP_PKGS[$i]}"
    [ "${#pkgs[@]}" -gt 0 ] || continue
    n=0
    for p in "${pkgs[@]}"; do
      _PLAN_SEEN["$p"]=1
      if _plan_installed "$p"; then
        n=$((n + 1))
      elif [ -z "${missing_seen[$p]:-}" ]; then
        missing_seen["$p"]=1
        missing+=("$p")
      fi
    done
    printf '\n  %b%s%b %b· %d/%d instalados%b\n' \
      "$C_BOLD" "${_INSTALL_GROUP_LABELS[$i]}" "$C_RESET" \
      "$C_DIM" "$n" "${#pkgs[@]}" "$C_RESET"
    _plan_print_packages verify "$_INSTALL_GROUP_MAXLEN" "${pkgs[@]}"
  done

  total_unique="${#_PLAN_SEEN[@]}"
  installed_total=0
  pending_total=0
  for p in "${!_PLAN_SEEN[@]}"; do
    if _plan_installed "$p"; then
      installed_total=$((installed_total + 1))
    else
      pending_total=$((pending_total + 1))
    fi
  done

  printf '\n  %bResumen:%b %d paquetes únicos · %d instalados · %d no instalados\n' \
    "$C_BOLD" "$C_RESET" "$total_unique" "$installed_total" "$pending_total"

  if [ "${#missing[@]}" -gt 0 ]; then
    printf '\n  %bNo instalados:%b\n' "$C_BOLD" "$C_RESET"
    _plan_print_packages verify "$_INSTALL_GROUP_MAXLEN" "${missing[@]}"
  fi

  if [ "$pending_total" = 0 ]; then
    ok "Todo listo: todos los paquetes están instalados"
  else
    warn "Quedaron ${pending_total} paquetes sin instalar (mira los marcados con ✗)"
  fi
  return 0
}

install_all() {
  local -a extra=("$@")
  local id total=5

  plan_report "${extra[@]}"
  chmodx_pause "Revisa el plan antes de instalar"

  total=$(( total + ${#extra[@]} ))
  chmodx_steps_total "$total"
  _PROFILE_SEEN=()
  CHMODX_REPOS_DONE=()

  run_step "Actualizando índices ($CHMODX_PM)" chmodx_pm_update
  run_step "Base · git, curl, wget"            install_base
  run_step "Python · $(chmodx_pkg python)"     install_python
  run_step "Node.js · $(chmodx_pkg node)"      install_node
  run_step "Utilidades · nano, htop, figlet"   install_ux

  for id in "${extra[@]}"; do
    [ -n "$id" ] || continue
    run_step "Categoría · $(profile_label "$id")" install_profile "$id"
  done

  chmodx_pause "Paquetes instalados · revisa la salida"
  verify_report "${extra[@]}"
}

install_only_base() {
  local CHMODX_PLAN_BASE_ONLY=1
  plan_report
  chmodx_pause "Revisa el plan antes de instalar"
  chmodx_steps_total 2
  run_step "Actualizando índices ($CHMODX_PM)" chmodx_pm_update
  run_step "Base · git, curl, wget"            install_base
  chmodx_pause "Paquetes instalados · revisa la salida"
  verify_report
}

uninstall_all() {
  local p
  local -a to_remove=() extras=() uniq=() kept=()
  local -A seen=()

  if [ -f "$CHMODX_MANIFEST" ]; then mapfile -t extras < <(manifest_list); fi

  printf '  %bPaquetes del kit:%b\n' "$C_GRAY" "$C_RESET"
  printf '    git, curl, wget, python\n'
  printf '    node, nano, htop, figlet\n'
  if [ "${#extras[@]}" -gt 0 ]; then
    printf '  %bExtras registrados:%b %d paquetes de categorías · se quitarán también\n' \
      "$C_GRAY" "$C_RESET" "${#extras[@]}"
  fi
  printf '  %bAviso:%b otras herramientas pueden depender de ellos.\n' "$C_WARN" "$C_RESET"
  if [ "${CHMODX_ENV:-}" = "termux" ] && chmodx_pm_db_installed curl; then
    printf '  %bSe conserva:%b curl, porque termux-tools lo necesita.\n' "$C_GRAY" "$C_RESET"
  fi
  printf '\n'

  chmodx_confirm "¿Desinstalar el Termux Kit completo?" || { ok "Desinstalación cancelada"; return 0; }

  # Se intenta quitar SIEMPRE la base y todos los extras registrados.
  # Solo se incluyen paquetes que el gestor confirma como instalados;
  # un binario manual (nvm, pyenv, etc.) no se toca.
  for p in git curl wget python node nano htop figlet; do
    if chmodx_pm_db_installed "$p"; then to_remove+=("$p"); fi
  done
  for p in "${extras[@]}"; do
    [ -n "$p" ] || continue
    if chmodx_pm_db_installed "$p"; then to_remove+=("$p"); fi
  done

  for p in "${to_remove[@]}"; do
    if [ -n "${seen[$p]:-}" ]; then continue; fi
    seen[$p]=1
    uniq+=("$p")
  done
  to_remove=("${uniq[@]}")

  chmodx_steps_total 1
  if [ "${#to_remove[@]}" -eq 0 ]; then
    skip_step "No hay paquetes del kit instalados"
    ok "Termux Kit desinstalado"
    chmodx_pause "Desinstalación completada"
    return 0
  fi

  if ! run_step "Quitando paquetes del kit" chmodx_pm_remove "${to_remove[@]}"; then
    err "No se pudieron quitar todos los paquetes"
    chmodx_pause "Revisa el error antes de continuar"
    return 1
  fi

  if [ "${CHMODX_DRYRUN:-0}" != 1 ]; then
    for p in "${to_remove[@]}"; do
      if chmodx_pm_db_installed "$p"; then kept+=("$p"); fi
    done
  fi
  manifest_clear
  if [ "${#kept[@]}" -gt 0 ]; then
    warn "Se conservaron (esenciales/dependencias): ${kept[*]}"
  fi
  ok "Termux Kit desinstalado"
  chmodx_pause "Desinstalación completada"
}

# ------------------------------------------------------------
#  Plan: enumera TODOS los paquetes antes de instalar
#  Base + repositorios + cada categoría elegida. No se muestran
#  solo los de base ni solo conteos: se listan todos los nombres.
# ------------------------------------------------------------
declare -A _PLAN_INSTALLED=()
declare -A _PLAN_STATUS=()
declare -A _PLAN_SEEN=()

_plan_load_installed() {
  local st p
  _PLAN_INSTALLED=()
  case "${CHMODX_PM:-}" in
    pkg|apt)
      if chmodx_has dpkg-query; then
        while read -r st p; do
          case "$st" in ii*) [ -n "$p" ] && _PLAN_INSTALLED["$p"]=1 ;; esac
        done < <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 2>/dev/null || true)
      fi ;;
    apk)
      if chmodx_has apk; then
        while read -r p; do
          [ -n "$p" ] && _PLAN_INSTALLED["$p"]=1
        done < <(apk info 2>/dev/null || true)
      fi ;;
    pacman)
      if chmodx_has pacman; then
        while read -r p; do
          [ -n "$p" ] && _PLAN_INSTALLED["$p"]=1
        done < <(pacman -Qq 2>/dev/null || true)
      fi ;;
    dnf|zypper)
      if chmodx_has rpm; then
        while read -r p; do
          [ -n "$p" ] && _PLAN_INSTALLED["$p"]=1
        done < <(rpm -qa --qf '%{NAME}\n' 2>/dev/null || true)
      fi ;;
    xbps)
      if chmodx_has xbps-query; then
        while read -r p; do
          p="${p%%-[0-9]*}"
          [ -n "$p" ] && _PLAN_INSTALLED["$p"]=1
        done < <(xbps-query -l 2>/dev/null | awk 'NR>1 {print $2}' || true)
      fi ;;
  esac
}

# Estado para el plan: usa la lista completa del gestor (una sola
# consulta) y, como respaldo, el binario del paquete. No llama a
# chmodx_pm_installed 300 veces porque el plan se volvería lento.
_plan_installed() {
  local p="${1:-}" rc=1
  [ -n "$p" ] || return 1
  if [ -n "${_PLAN_STATUS[$p]+x}" ]; then
    [ "${_PLAN_STATUS[$p]}" = 1 ]
    return
  fi
  if [ -n "${_PLAN_INSTALLED[$p]:-}" ]; then
    rc=0
  elif chmodx_has "$p"; then
    rc=0
  fi
  if [ "$rc" = 0 ]; then _PLAN_STATUS[$p]=1; else _PLAN_STATUS[$p]=0; fi
  return "$rc"
}

# Convierte nombres canónicos a los reales del gestor y elimina
# duplicados dentro del mismo grupo.
_plan_map_list() {
  local p real r
  local -A local_seen=()
  for p in "$@"; do
    [ -n "$p" ] || continue
    real="$(chmodx_pkg "$p")"
    for r in $real; do
      [ -n "$r" ] || continue
      [ -n "${local_seen[$r]:-}" ] && continue
      local_seen[$r]=1
      printf '%s\n' "$r"
    done
  done
}

# Construye los grupos que se usan en el plan y en la verificación.
# Deja el resultado en _INSTALL_GROUP_LABELS/DESCS/PKGS.
_INSTALL_GROUP_LABELS=()
_INSTALL_GROUP_DESCS=()
_INSTALL_GROUP_PKGS=()
_INSTALL_GROUP_MAXLEN=0

_collect_install_groups() {
  local base_only="${1:-0}"; shift
  local p id repo maxlen=0
  local -a base_raw=(git curl wget python node nano htop figlet)
  local -a base_pkgs=() raw=() pkgs=()
  local -a repos=()
  local -A repo_seen=()
  local base_label="Base + utilidades"
  local base_desc="git, curl, wget, Python, Node, nano, htop y figlet"

  _INSTALL_GROUP_LABELS=()
  _INSTALL_GROUP_DESCS=()
  _INSTALL_GROUP_PKGS=()
  _INSTALL_GROUP_MAXLEN=0

  if [ "$base_only" = 1 ]; then
    base_raw=(git curl wget)
    base_label="Base mínima"
    base_desc="git, curl, wget"
  fi

  mapfile -t base_pkgs < <(_plan_map_list "${base_raw[@]}")
  _INSTALL_GROUP_LABELS+=("$base_label")
  _INSTALL_GROUP_DESCS+=("$base_desc")
  _INSTALL_GROUP_PKGS+=("${base_pkgs[*]}")
  for p in "${base_pkgs[@]}"; do
    [ "${#p}" -gt "$maxlen" ] && maxlen="${#p}"
  done

  # Repositorios que hay que preparar antes de ciertas categorías.
  for id in "$@"; do
    [ -n "$id" ] || continue
    _profile_exists "$id" || continue
    repo="$(profile_repos "$id")"
    for p in $repo; do
      [ -n "$p" ] || continue
      [ -n "${repo_seen[$p]:-}" ] && continue
      repo_seen[$p]=1
      repos+=("$p")
    done
  done
  if [ "${#repos[@]}" -gt 0 ]; then
    _INSTALL_GROUP_LABELS+=("Repositorios requeridos")
    _INSTALL_GROUP_DESCS+=("se preparan antes de sus categorías")
    _INSTALL_GROUP_PKGS+=("${repos[*]}")
    for p in "${repos[@]}"; do
      [ "${#p}" -gt "$maxlen" ] && maxlen="${#p}"
    done
  fi

  # Cada categoría elegida, con todos sus paquetes.
  for id in "$@"; do
    [ -n "$id" ] || continue
    _profile_exists "$id" || continue
    read -r -a raw <<< "$(profile_packages "$id")"
    mapfile -t pkgs < <(_plan_map_list "${raw[@]}")
    [ "${#pkgs[@]}" -gt 0 ] || continue
    _INSTALL_GROUP_LABELS+=("Categoría · $(profile_label "$id")")
    _INSTALL_GROUP_DESCS+=("$(profile_desc "$id")")
    _INSTALL_GROUP_PKGS+=("${pkgs[*]}")
    for p in "${pkgs[@]}"; do
      [ "${#p}" -gt "$maxlen" ] && maxlen="${#p}"
    done
  done

  _INSTALL_GROUP_MAXLEN="$maxlen"
}

# Lista compacta en columnas.
#   plan   → ✓ instalado · + por instalar · · ya incluido
#   verify → ✓ instalado · ✗ no instalado
_plan_print_packages() {
  local mode="${1:-plan}" maxlen="${2:-10}"; shift 2
  local -a pkgs=("$@")
  local n="${#pkgs[@]}" cols cellw avail i j p glyph color
  [ "$n" -gt 0 ] || return 0
  avail=$(( $(_ui_width) - 2 ))
  cellw=$(( maxlen + 4 ))
  [ "$cellw" -lt 1 ] && cellw=1
  cols=$(( avail / cellw ))
  [ "$cols" -lt 1 ] && cols=1
  [ "$cols" -gt 5 ] && cols=5
  for ((i = 0; i < n; i += cols)); do
    printf '  '
    for ((j = i; j < i + cols && j < n; j++)); do
      p="${pkgs[$j]}"
      if _plan_installed "$p"; then
        glyph='✓'; color="$C_SUCCESS"
      elif [ "$mode" = "verify" ]; then
        glyph='✗'; color="$C_ERR"
      elif [ -n "${_PLAN_SEEN[$p]:-}" ]; then
        glyph='·'; color="$C_DIM"
      else
        glyph='+'; color="$C_PRIMARY"
      fi
      if [ "$mode" = "plan" ]; then _PLAN_SEEN["$p"]=1; fi
      printf '%b%s%b %-*s' "$color" "$glyph" "$C_RESET" "$maxlen" "$p"
      if [ "$j" -lt $((i + cols - 1)) ] && [ "$j" -lt $((n - 1)) ]; then
        printf '  '
      fi
    done
    printf '\n'
  done
}

plan_report() {
  local p i maxlen total_unique installed=0 pending=0 n=0
  local -a pkgs=()

  section "Plan de instalación"
  [ "$CHMODX_QUIET" = 1 ] && return 0

  _plan_load_installed
  _PLAN_SEEN=()
  _PLAN_STATUS=()
  _collect_install_groups "${CHMODX_PLAN_BASE_ONLY:-0}" "$@"
  maxlen="$_INSTALL_GROUP_MAXLEN"

  printf '\n'
  for i in "${!_INSTALL_GROUP_LABELS[@]}"; do
    read -r -a pkgs <<< "${_INSTALL_GROUP_PKGS[$i]}"
    [ "${#pkgs[@]}" -gt 0 ] || continue
    n=0
    for p in "${pkgs[@]}"; do
      if _plan_installed "$p"; then n=$((n + 1)); fi
    done
    printf '  %b%s%b %b· %s%b\n' \
      "$C_BOLD" "${_INSTALL_GROUP_LABELS[$i]}" "$C_RESET" \
      "$C_DIM" "${_INSTALL_GROUP_DESCS[$i]}" "$C_RESET"
    printf '  %b%d paquetes · %d ya instalados%b\n' \
      "$C_GRAY" "${#pkgs[@]}" "$n" "$C_RESET"
    _plan_print_packages plan "$maxlen" "${pkgs[@]}"
    printf '\n'
  done

  total_unique="${#_PLAN_SEEN[@]}"
  for p in "${!_PLAN_SEEN[@]}"; do
    if _plan_installed "$p"; then
      installed=$((installed + 1))
    else
      pending=$((pending + 1))
    fi
  done

  printf '  %bLeyenda:%b %b✓%b instalado · %b+%b por instalar · %b·%b ya incluido en otro grupo\n' \
    "$C_BOLD" "$C_RESET" "$C_SUCCESS" "$C_RESET" "$C_PRIMARY" "$C_RESET" "$C_DIM" "$C_RESET"
  printf '  %bTotal:%b %d paquetes únicos · %d instalados · %d por instalar\n' \
    "$C_BOLD" "$C_RESET" "$total_unique" "$installed" "$pending"
  printf '  %bNota:%b los paquetes no disponibles en %s se omiten automáticamente.\n' \
    "$C_GRAY" "$C_RESET" "${CHMODX_PM:-gestor}"
  printf '\n'
  return 0
}

show_info() {
  local extras=0
  if [ -f "$CHMODX_MANIFEST" ]; then extras="$(manifest_list | wc -l | tr -d ' ')"; fi
  section "Información"
  printf '  %bProyecto:%b  %s\n' "$C_GRAY" "$C_RESET" "${CHMODX_NAME}"
  printf '  %bVersión:%b   %s\n' "$C_GRAY" "$C_RESET" "${CHMODX_VERSION}"
  printf '  %bEntorno:%b   %s\n' "$C_GRAY" "$C_RESET" "$(chmodx_env_label)"
  printf '  %bDistro:%b    %s\n' "$C_GRAY" "$C_RESET" "${CHMODX_DISTRO_NAME:-${CHMODX_DISTRO}}"
  printf '  %bGestor:%b    %s\n' "$C_GRAY" "$C_RESET" "${CHMODX_PM}"
  printf '  %bRoot:%b      %s (sudo: %s)\n' "$C_GRAY" "$C_RESET" "${CHMODX_ROOT}" "${CHMODX_SUDO:-<ninguno>}"
  printf '  %bPrefijo:%b   %s\n' "$C_GRAY" "$C_RESET" "${PREFIX:-<no definido>}"
  echo
  printf '  Paquetes base : %b%s %s %s %s %s %s %s %s%b\n' \
    "$C_BOLD" git curl wget "$(chmodx_pkg python)" "$(chmodx_pkg node)" nano htop figlet "$C_RESET"
  printf '  Categorías    : %b%d disponibles%b (menú → Elegir por categoría)\n' \
    "$C_BOLD" "${#PROFILE_IDS[@]}" "$C_RESET"
  printf '  Registrados   : %b%d paquetes extra%b\n' "$C_BOLD" "$extras" "$C_RESET"
  printf '  Manifest      : %b%s%b\n' "$C_DIM" "$CHMODX_MANIFEST" "$C_RESET"
}

# ============================================================
#  CATEGORÍAS DE PAQUETES EXTRA
#  El usuario elige qué categorías instalar desde un submenú.
#  Cada categoría se instala como un paso y cada paquete tiene
#  su propia barra 0→100 %.
# ============================================================

PROFILE_IDS=(
  esencial ux dev python net sec media db edit comms fun x11 x11apps tur
)

# Estado persistente: solo los paquetes que agregó este instalador.
CHMODX_STATE_DIR="${CHMODX_STATE_DIR:-${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/chmodx}"
CHMODX_MANIFEST="${CHMODX_MANIFEST:-${CHMODX_STATE_DIR}/$(basename "${0:-installer}" .sh).packages}"

profile_label() {
  case "$1" in
    esencial) printf 'Esencial Pro' ;;
    ux)       printf 'Terminal Hacker' ;;
    dev)      printf 'Desarrollo' ;;
    python)   printf 'Python / IA' ;;
    net)      printf 'Redes y descargas' ;;
    sec)      printf 'Seguridad / RE' ;;
    media)    printf 'Multimedia' ;;
    db)       printf 'Bases de datos' ;;
    edit)     printf 'Editores / IDE' ;;
    comms)    printf 'Comunicación' ;;
    fun)      printf 'Juegos / Fun' ;;
    x11)      printf 'Escritorio X11' ;;
    x11apps)  printf 'Apps gráficas' ;;
    tur)      printf 'TUR avanzado' ;;
    *)        printf '%s' "$1" ;;
  esac
}

profile_desc() {
  case "$1" in
    esencial) printf 'sistema base' ;;
    ux)       printf 'shell, búsqueda y git' ;;
    dev)      printf 'compiladores y lenguajes' ;;
    python)   printf 'datos, IA y visión' ;;
    net)      printf 'SSH, descargas y red' ;;
    sec)      printf 'pentesting y reversing' ;;
    media)    printf 'audio, video e imágenes' ;;
    db)       printf 'SQL y servidores web' ;;
    edit)     printf 'IDE y navegación' ;;
    comms)    printf 'chat, RSS y oficina' ;;
    fun)      printf 'juegos CLI y ASCII' ;;
    x11)      printf 'escritorio y VNC' ;;
    x11apps)  printf 'navegador, Office y GIMP' ;;
    tur)      printf 'pandas, MongoDB y hashcat' ;;
    *)        printf '' ;;
  esac
}

# Repositorio que hay que habilitar antes de instalar la categoría.
profile_repos() {
  case "$1" in
    x11|x11apps) printf 'x11-repo' ;;
    tur)         printf 'tur-repo' ;;
    *)           printf '' ;;
  esac
}

profile_packages() {
  case "$1" in
    esencial)
      printf '%s\n' 'coreutils findutils grep sed gawk tar gzip bzip2 xz-utils zstd unzip zip 7zip unrar less file which procps psmisc util-linux diffutils patch rsync mandoc ncurses-utils termux-tools termux-api termux-am termux-exec termux-keyring' ;;
    ux)
      printf '%s\n' 'zsh fish tmux screen zellij fzf zoxide eza lsd bat ripgrep fd silversearcher-ag git-delta lazygit gh glab-cli tig starship tree ncdu duf dust htop parallel entr glow mdcat procs sd hyperfine tokei gitui onefetch jq yq gojq pup xmlstarlet shellcheck shfmt bash-completion zsh-completions' ;;
    dev)
      printf '%s\n' 'clang lld lldb llvm llvm-tools make cmake ninja pkg-config binutils gdb strace ltrace patchelf autoconf automake libtool flex bison gettext rust rust-analyzer golang nodejs-lts yarn pnpm deno bun python python-pip ruby php php-fpm perl lua54 luarocks tcl openjdk-17 gradle maven ant scala elixir erlang ghc zig nim crystal dart kotlin racket guile sbcl chicken git subversion git-lfs composer sqlite' ;;
    python)
      printf '%s\n' 'python-pip python-numpy python-scipy matplotlib python-torch onnxruntime fftw libopenblas ollama llama-cpp tesseract' ;;
    net)
      printf '%s\n' 'curl wget aria2 rclone openssh sshpass mosh autossh inetutils dnsutils whois traceroute nmap netcat-openbsd socat speedtest-go transmission rtorrent httpie xh websocat restic borgbackup syncthing croc rsync termux-api' ;;
    sec)
      printf '%s\n' 'nmap netcat-openbsd socat radare2 rizin binwalk apktool jadx xxd hexyl openssl gnupg age pass' ;;
    media)
      printf '%s\n' 'ffmpeg ffmpegthumbnailer imagemagick graphicsmagick sox lame flac opus-tools vorbis-tools wavpack mediainfo atomicparsley mpv mpd ncmpcpp cmus cava gifsicle optipng jpegoptim pngquant libwebp exiftool poppler qpdf ghostscript tesseract pandoc groff chafa timg jp2a vlc' ;;
    db)
      printf '%s\n' 'sqlite postgresql mariadb redis nginx apache2 lighttpd php php-fpm composer' ;;
    edit)
      printf '%s\n' 'nano vim neovim emacs micro helix ranger nnn mc lazygit gitui' ;;
    comms)
      printf '%s\n' 'irssi weechat mutt neomutt alpine newsboat znc bitlbee profanity taskwarrior calcurse pandoc groff mdcat glow' ;;
    fun)
      printf '%s\n' 'nethack angband crawl bastet ninvaders pacman4console moon-buggy nsnake nudoku tty-solitaire cmatrix cbonsai sl cowsay fortune figlet toilet neofetch fastfetch hollywood' ;;
    x11)
      printf '%s\n' 'xfce4 xfce4-terminal xfce4-panel xfce4-session thunar openbox fluxbox i3 awesome tigervnc xorg-server x11vnc dbus pulseaudio alsa-utils pavucontrol pcmanfm geany mousepad xclip xsel xdotool wmctrl scrot feh' ;;
    x11apps)
      printf '%s\n' 'firefox chromium code-oss libreoffice gimp inkscape krita qemu-system-x86-64 mkvtoolnix chocolate-doom opencv' ;;
    tur)
      printf '%s\n' 'python-pandas mongodb hashcat ettercap dsniff' ;;
    *) printf '' ;;
  esac
}

profile_count() {
  local -a pkgs=()
  read -r -a pkgs <<< "$(profile_packages "$1")"
  printf '%s' "${#pkgs[@]}"
}

_profile_exists() {
  local id
  for id in "${PROFILE_IDS[@]}"; do
    if [ "$id" = "$1" ]; then return 0; fi
  done
  return 1
}

# Paquetes únicos de varias categorías (sin duplicados).
_profiles_pkg_count() {
  local -a ids=("$@")
  local -A seen=()
  local id p n=0
  for id in "${ids[@]}"; do
    read -r -a pkgs <<< "$(profile_packages "$id")"
    for p in "${pkgs[@]}"; do
      if [ -n "${seen[$p]:-}" ]; then continue; fi
      seen[$p]=1
      n=$((n + 1))
    done
  done
  printf '%s' "$n"
}

# ------------------------------------------------------------
#  Manifest: paquetes extra que agregó este instalador
# ------------------------------------------------------------
manifest_add() {
  local p
  if [ "${CHMODX_DRYRUN:-0}" = 1 ]; then return 0; fi
  [ "$#" -gt 0 ] || return 0
  mkdir -p "$CHMODX_STATE_DIR" 2>/dev/null || return 0
  touch "$CHMODX_MANIFEST" 2>/dev/null || return 0
  for p in "$@"; do
    grep -qxF "$p" "$CHMODX_MANIFEST" 2>/dev/null || printf '%s\n' "$p" >>"$CHMODX_MANIFEST"
  done
  return 0
}

manifest_list() {
  [ -f "$CHMODX_MANIFEST" ] || return 0
  # Un manifest vacío o solo con comentarios no debe romper `set -e`.
  grep -v '^[[:space:]]*#' "$CHMODX_MANIFEST" 2>/dev/null | sed '/^[[:space:]]*$/d' | sort -u || true
}

manifest_clear() {
  rm -f "$CHMODX_MANIFEST" 2>/dev/null || true
}

# ------------------------------------------------------------
#  Selección de categorías
# ------------------------------------------------------------
select_profiles() {
  local i id out='' line n bad
  local -a picks=()

  if chmodx_has whiptail; then
    local -a args=()
    for i in "${!PROFILE_IDS[@]}"; do
      id="${PROFILE_IDS[$i]}"
      args+=("$id" "$((i + 1)). $(profile_label "$id") · $(profile_count "$id") paq · $(profile_desc "$id")" "OFF")
    done
    out=$(whiptail --title "CHMODX · ${CHMODX_NAME:-Instalador}" --separate-output \
          --checklist "Elige las categorías extra:" 0 0 0 "${args[@]}" 3>&1 1>&2 2>&3) || return 1
    [ -n "$out" ] || return 1
    local -a picked=()
    while IFS= read -r line; do
      line="${line%$'\r'}"
      line="${line//\"/}"
      if [ -n "$line" ]; then picked+=("$line"); fi
    done <<<"$out"
    [ "${#picked[@]}" -gt 0 ] || return 1
    SELECTED_PROFILES=("${picked[@]}")
    return 0
  fi

  section "Paquetes extra"
  printf '  %b%-3s %-18s %5s  %s%b\n' "$C_GRAY" "#" "Categoría" "Paq." "Descripción" "$C_RESET"
  for i in "${!PROFILE_IDS[@]}"; do
    id="${PROFILE_IDS[$i]}"
    printf '  [%2d] %b%-18s%b %4d  %b%s%b\n' \
      "$((i + 1))" "$C_BOLD" "$(profile_label "$id")" "$C_RESET" \
      "$(profile_count "$id")" "$C_DIM" "$(profile_desc "$id")" "$C_RESET"
  done
  printf '\n  %bX11 y TUR son pesados; solo se instalan si los eliges.%b\n' "$C_GRAY" "$C_RESET"

  while :; do
    printf '\n  %bNúmeros separados por espacio (ej: 2 5 9)%b\n' "$C_GRAY" "$C_RESET"
    printf '  %bt = todas · q = volver%b\n  > ' "$C_DIM" "$C_RESET"
    if [ -r /dev/tty ]; then
      IFS= read -r line </dev/tty || return 1
    else
      IFS= read -r line || return 1
    fi
    line="${line//,/ }"
    case "$line" in
      q|Q|'') return 1 ;;
      t|T|all|todo) SELECTED_PROFILES=("${PROFILE_IDS[@]}"); return 0 ;;
    esac

    picks=(); bad=0
    for n in $line; do
      case "$n" in
        ''|*[!0-9]*) bad=1; break ;;
      esac
      if [ "$n" -lt 1 ] || [ "$n" -gt "${#PROFILE_IDS[@]}" ]; then
        bad=1; break
      fi
      picks+=("${PROFILE_IDS[$((n - 1))]}")
    done
    if [ "$bad" = 0 ] && [ "${#picks[@]}" -gt 0 ]; then
      SELECTED_PROFILES=("${picks[@]}")
      return 0
    fi
    warn "Selección no válida · escribe números del 1 al ${#PROFILE_IDS[@]}"
  done
}

list_profiles() {
  local i id
  printf 'Categorías disponibles (%d):\n' "${#PROFILE_IDS[@]}"
  for i in "${!PROFILE_IDS[@]}"; do
    id="${PROFILE_IDS[$i]}"
    printf '  %2d) %-9s %-18s %2d paquetes · %s\n' \
      "$((i + 1))" "$id" "$(profile_label "$id")" "$(profile_count "$id")" "$(profile_desc "$id")"
  done
  printf '\nUso: --profiles=ux,dev,net  ·  --profiles=all\n'
}

# Acepta ids, números o "all" y escribe ids únicos (uno por línea).
_resolve_profiles() {
  local spec="${1:-}" tok
  local -a out=()
  local -A seen=()
  for tok in ${spec//,/ }; do
    case "$tok" in
      '' ) continue ;;
      all|todo|t) printf '%s\n' "${PROFILE_IDS[@]}"; return 0 ;;
      *[!0-9]*)
        if _profile_exists "$tok"; then
          if [ -n "${seen[$tok]:-}" ]; then continue; fi
          seen[$tok]=1; out+=("$tok")
        else
          warn "Categoría desconocida: $tok"
        fi ;;
      *)
        if [ "$tok" -ge 1 ] && [ "$tok" -le "${#PROFILE_IDS[@]}" ]; then
          tok="${PROFILE_IDS[$((tok - 1))]}"
          if [ -n "${seen[$tok]:-}" ]; then continue; fi
          seen[$tok]=1; out+=("$tok")
        else
          warn "Número fuera de rango: $tok"
        fi ;;
    esac
  done
  if [ "${#out[@]}" -gt 0 ]; then printf '%s\n' "${out[@]}"; fi
}

# ------------------------------------------------------------
#  Instalación de una categoría
# ------------------------------------------------------------
declare -A CHMODX_REPOS_DONE=()
declare -A _PROFILE_SEEN=()

_repo_prepare() {
  local repo="${1:-}"
  [ -n "$repo" ] || return 0
  if [ -n "${CHMODX_REPOS_DONE[$repo]:-}" ]; then return 0; fi
  CHMODX_REPOS_DONE[$repo]=1

  if ! chmodx_pm_available "$repo"; then
    chmodx_action_skip "$repo" "no disponible en ${CHMODX_PM}"
    return 0
  fi
  chmodx_pm_ensure_optional "$repo" || return 1
  chmodx_pm_update || warn "No se pudo refrescar índices tras ${repo}"
  return 0
}

install_profile() {
  local id="${1:-}" repo p rc=0
  local -a pkgs=() todo=() newly=() installed_now=()
  _profile_exists "$id" || return 0

  read -r -a pkgs <<< "$(profile_packages "$id")"
  printf '  %b%s%b · %d paquetes · %bse omiten los ya instalados%b\n\n' \
    "$C_GRAY" "$(profile_desc "$id")" "$C_RESET" "${#pkgs[@]}" "$C_DIM" "$C_RESET"

  repo="$(profile_repos "$id")"
  if [ -n "$repo" ]; then
    _repo_prepare "$repo" || rc=1
  fi

  for p in "${pkgs[@]}"; do
    if [ -n "${_PROFILE_SEEN[$p]:-}" ]; then continue; fi
    _PROFILE_SEEN[$p]=1
    todo+=("$p")
    chmodx_pm_installed "$p" || newly+=("$p")
  done

  if [ "${#todo[@]}" -gt 0 ]; then
    chmodx_pm_ensure_optional "${todo[@]}" || rc=1
  else
    chmodx_action_skip "Categoría $(profile_label "$id")" "sin paquetes nuevos"
  fi

  for p in "${newly[@]}"; do
    if chmodx_pm_installed "$p"; then installed_now+=("$p"); fi
  done
  if [ "${#installed_now[@]}" -gt 0 ]; then
    manifest_add "${installed_now[@]}"
  fi
  return "$rc"
}

usage() {
  cat <<EOF
CHMODX Installer — ${CHMODX_NAME:-INSTALADOR} v${CHMODX_VERSION:-1.0.0}

Uso: bash $(basename "$0") [opciones]

  --no-splash    sin pantalla de marca inicial
  --matrix       fuerza la lluvia Matrix (ya activa por defecto)
  --no-matrix    desactiva la lluvia Matrix
  --menu         forzar el menú interactivo (ya sale por defecto en TTY)
  --no-menu      instalar directamente, sin menú
  --theme=<auto|dark|light>  ajusta el contraste al tema del terminal
  --no-color     desactiva los colores (también respeta NO_COLOR)
  --profiles=<l>  instala base + categorías extra (ux,dev,net · all)
  --list-profiles muestra las categorías disponibles y sale
  (El submenú [3] aparece en terminal interactiva, sin --no-menu ni --yes)
  --uninstall    desinstala lo que añadió este instalador
  --no-pause     no se detiene a pedir Enter
  --no-promo     no muestra la invitación final al curso
  --dry-run      simula la instalación sin tocar el sistema
  --env          muestra el entorno detectado (Termux/proot/distro) y sale
  --doctor       diagnóstico completo del entorno (preflight) y sale
  --quiet, -q    salida mínima
  --verbose, -v  muestra toda la salida de los comandos
  --yes, -y      modo automático (no preguntar)
  --log <ruta>   guarda el detalle en un archivo de log
  -h, --help     esta ayuda
EOF
}

parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-splash)  NO_SPLASH=1 ;;
      --matrix)     CHMODX_MATRIX=1 ;;
      --no-matrix)  CHMODX_MATRIX=0 ;;
      --menu)       CHMODX_FORCE_MENU=1 ;;
      --no-menu)    CHMODX_NO_MENU=1 ;;
      --theme=*)    CHMODX_THEME="${1#*=}" ;;
      --theme)
        if [ $# -ge 2 ] && [ "${2#--}" = "${2:-}" ]; then
          CHMODX_THEME="$2"; shift
        else
          CHMODX_THEME=auto
        fi ;;
      --no-color)   NO_COLOR=1 ;;
      --profiles=*) CHMODX_PROFILES="${1#*=}" ;;
      --profiles)
        if [ $# -ge 2 ] && [ "${2#--}" = "${2:-}" ]; then
          CHMODX_PROFILES="$2"; shift
        fi ;;
      --list-profiles)
        if [ "$(type -t list_profiles 2>/dev/null || true)" = "function" ]; then
          list_profiles; exit 0
        fi
        err "Este instalador no tiene categorías de paquetes"; exit 1 ;;
      --uninstall)  CHMODX_UNINSTALL=1 ;;
      --no-pause)   CHMODX_NO_PAUSE=1 ;;
      --no-promo)   CHMODX_NO_PROMO=1 ;;
      --dry-run)    CHMODX_DRYRUN=1 ;;
      --env)        CHMODX_SHOW_ENV=1 ;;
      --doctor)     CHMODX_DOCTOR=1 ;;
      --quiet|-q)   CHMODX_QUIET=1 ;;
      --verbose|-v) CHMODX_VERBOSE=1 ;;
      --yes|-y)     CHMODX_YES=1 ;;
      --log)
        if [ $# -ge 2 ] && [ "${2#--}" = "${2:-}" ]; then
          CHMODX_LOG="$2"; shift
        fi ;;
      -h|--help)    usage; exit 0 ;;
      *)            warn "Opción desconocida: $1" ;;
    esac
    shift
  done
}

main() {
  chmodx_env_detect                 # Termux / proot / distro + gestor de paquetes
  parse_flags "$@"

  # Flags informativos: se atienden después de parsear todo para que
  # --theme/--no-color funcionen sin importar el orden.
  if [ "${CHMODX_SHOW_ENV:-0}" = 1 ]; then
    chmodx_env_report
    exit 0
  fi
  if [ "${CHMODX_DOCTOR:-0}" = 1 ]; then
    chmodx_env_report
    chmodx_preflight || exit 1
    exit 0
  fi

  chmodx_init                       # trap de limpieza + log
  chmodx_splash                     # lluvia por defecto (se salta sin TTY / --no-splash)
  chmodx_banner                     # CHMODX-CODE + nombre del programa

  if [ "$CHMODX_ENV" != "termux" ]; then
    warn "Entorno $(chmodx_env_label): se usará el gestor '$CHMODX_PM'"
  fi
  if [ "$CHMODX_PM" = "unknown" ]; then
    warn "No se detectó gestor de paquetes: la instalación puede fallar"
  fi
  if [ "$CHMODX_DRYRUN" = 1 ]; then
    warn "Modo simulación (--dry-run): no se instalará nada"
  fi

  chmodx_steps_total 5

  # Diagnóstico inteligente antes de tocar nada
  if ! chmodx_preflight; then
    if [ "$CHMODX_YES" = 1 ]; then
      warn "Continuando con avisos (--yes)"
    elif chmodx_confirm "¿Continuar de todos modos?"; then
      warn "Continuando con avisos"
    else
      err "Instalación cancelada"
      exit 1
    fi
  fi

  # Desinstalación directa (no pasa por el menú)
  if [ "${CHMODX_UNINSTALL:-0}" = 1 ]; then
    section "Desinstalación"
    uninstall_all || exit 1
    exit 0
  fi

  # Categorías extra pedidas por flag (solo si el proyecto las define)
  if [ -n "${CHMODX_PROFILES:-}" ]; then
    if [ "$(type -t _resolve_profiles 2>/dev/null || true)" != "function" ]; then
      err "Este instalador no tiene categorías de paquetes"
      exit 1
    fi
    local -a _profiles=()
    mapfile -t _profiles < <(_resolve_profiles "$CHMODX_PROFILES")
    if [ "${#_profiles[@]}" -eq 0 ]; then
      err "No hay categorías válidas en --profiles=${CHMODX_PROFILES}"
      exit 1
    fi
    install_all "${_profiles[@]}"
    CHMODX_DONE=1
  fi

if [ "${CHMODX_DONE:-0}" != 1 ] && chmodx_menu_enabled; then
  while :; do
    section "Menú"
    sel="$(chmodx_menu "Selecciona una acción:" \
      "1" "Instalar base recomendada · Python + Node + utilidades" \
      "2" "Instalar mínimo · git, curl, wget" \
      "3" "Elegir por categoría · ${#PROFILE_IDS[@]} categorías" \
      "4" "Desinstalar · base + extras registrados" \
      "5" "Información · paquetes y rutas" \
      "6" "Salir")" || { ok "Cancelado"; exit 0; }
    case "$sel" in
      1) install_all; CHMODX_DONE=1; break ;;
      2) install_only_base; CHMODX_DONE=1; break ;;
      3)
        if select_profiles; then
          install_all "${SELECTED_PROFILES[@]}"
          CHMODX_DONE=1
          break
        fi
        ;;
      4) section "Desinstalación"; uninstall_all || exit 1; exit 0 ;;
      5) show_info; chmodx_pause "Revisa la información" ;;
      6) exit 0 ;;
    esac
  done
fi

if [ "${CHMODX_DONE:-0}" != 1 ]; then
  if chmodx_confirm "¿Instalar el kit esencial en Termux?"; then
    section "Instalando Termux Kit"
    install_all
  else
    skip_step "Instalación omitida por el usuario"
  fi
fi

  summary
  echo
ok "Termux Kit listo"
printf "${C_DIM}Prueba:%b nano --version · python3 --version · node --version${C_RESET}\n" ""
  chmodx_pause "Revisa el resultado de la instalación"
  chmodx_outro
  printf "${C_GRAY}Powered by CHMODX${C_RESET}\n"
}

main "$@"
