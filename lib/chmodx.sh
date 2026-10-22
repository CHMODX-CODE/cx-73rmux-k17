#!/bin/bash
# ============================================================
#  CHMODX Common Library · core
#  Versión: 1.3.0  ·  Powered by CHMODX
# ============================================================
#  lib/chmodx.sh se genera CONCATENANDO, en este orden:
#    lib-chmodx.tpl + ui.tpl + splash.tpl + banner.tpl + menu.tpl
#  (solo este archivo lleva shebang)
# ============================================================

# --- Colores (truecolor → 256 → 16 + tema claro/oscuro) ------
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_PRIMARY='\033[38;2;1;133;130m'
C_PRIMARY_256='\033[38;5;30m'
C_PRIMARY_TRUE="$C_PRIMARY"
C_PRIMARY_16='\033[36m'
C_SUCCESS='\033[38;5;35m'
C_WARN='\033[38;5;214m'
C_ERR='\033[38;5;203m'
C_INFO='\033[38;5;75m'
C_GRAY='\033[38;5;245m'
C_DARK='\033[38;5;238m'

# --- Estado global -------------------------------------------
CHMODX_QUIET=0
CHMODX_VERBOSE=0
CHMODX_YES=0
CHMODX_DRYRUN=0
CHMODX_TTY=0
[ -t 1 ] && CHMODX_TTY=1
CHMODX_LOG="${CHMODX_LOG:-}"
CHMODX_THEME="${CHMODX_THEME:-auto}"
CHMODX_BG=""
CHMODX_COLORS=""

# --- Logs ----------------------------------------------------
info() { if [ "$CHMODX_QUIET" != 1 ]; then printf "${C_INFO}[INFO]${C_RESET} %s\n" "$*"; fi; }
ok()   { if [ "$CHMODX_QUIET" != 1 ]; then printf "${C_SUCCESS}[ OK ]${C_RESET} %s\n" "$*"; fi; }
warn() { printf "${C_WARN}[WARN]${C_RESET} %s\n" "$*" >&2; }
err()  { printf "${C_ERR}[ERR ]${C_RESET} %s\n" "$*" >&2; }
skip() { if [ "$CHMODX_QUIET" != 1 ]; then printf "${C_DIM}[SKIP]${C_RESET} %s\n" "$*"; fi; }
die()  { err "$*"; exit 1; }

# --- Utilidades ----------------------------------------------
chmodx_has() { command -v "$1" >/dev/null 2>&1; }

# ============================================================
#  DETECCIÓN DE ENTORNO  (Termux · proot-distro · Linux)
# ============================================================
#  Rellena: CHMODX_ENV, CHMODX_DISTRO, CHMODX_DISTRO_NAME,
#           CHMODX_DISTRO_VERSION, CHMODX_PM, CHMODX_IN_PROOT,
#           CHMODX_ROOT, CHMODX_SUDO
#  Overrides manuales: CHMODX_FORCE_ENV / _DISTRO / _PM
# ============================================================
CHMODX_ENV="unknown"
CHMODX_DISTRO="unknown"
CHMODX_DISTRO_NAME=""
CHMODX_DISTRO_VERSION=""
CHMODX_PM=""
CHMODX_IN_PROOT=0
CHMODX_ROOT=0
CHMODX_SUDO=""
CHMODX_OS_RELEASE="${CHMODX_OS_RELEASE:-/etc/os-release}"

_os_release_field() {   # _os_release_field <CAMPO> [archivo]
  local want="$1" file="${2:-$CHMODX_OS_RELEASE}" k v
  [ -r "$file" ] || return 0
  while IFS='=' read -r k v; do
    case "$k" in
      "$want") v="${v%\"}"; v="${v#\"}"; printf '%s' "$v"; return 0 ;;
    esac
  done <"$file"
  return 0
}

_is_known_distro() {   # ¿el ID/ID_LIKE corresponde a una distro Linux conocida?
  case " $1 " in
    *alpine*|*arch*|*artix*|*manjaro*|*endeavouros*|*fedora*|*rhel*|*centos*|*rocky*|\
    *almalinux*|*opensuse*|*suse*|*void*|*debian*|*ubuntu*|*kali*|*parrot*|*mint*|\
    *raspbian*|*devuan*|*pop*) return 0 ;;
    *) return 1 ;;
  esac
}

chmodx_env_detect() {
  local termux_marker=0 id like

  [ -n "${TERMUX_VERSION:-}" ] && termux_marker=1
  [ -d "/data/data/com.termux" ] && termux_marker=1
  case "${PREFIX:-}" in */com.termux/files/usr) termux_marker=1 ;; esac

  id="$(_os_release_field ID)"
  like="$(_os_release_field ID_LIKE)"
  CHMODX_DISTRO_NAME="$(_os_release_field PRETTY_NAME)"
  CHMODX_DISTRO_VERSION="$(_os_release_field VERSION_ID)"
  CHMODX_DISTRO="${id:-unknown}"

  # proot-distro: variables de proot, o marca de Termux con una distro Linux real
  CHMODX_IN_PROOT=0
  if [ -n "${PROOT_TMP_DIR:-}" ] || [ -n "${PROOT_LOADER:-}" ] || [ -n "${PROOT_NO_SECCOMP:-}" ]; then
    CHMODX_IN_PROOT=1
  elif [ "$termux_marker" = 1 ] && _is_known_distro "$id $like"; then
    CHMODX_IN_PROOT=1
  fi

  # --- Gestor de paquetes ---
  if [ "$termux_marker" = 1 ] && [ "$CHMODX_IN_PROOT" != 1 ] && chmodx_has pkg; then
    CHMODX_ENV="termux"
    CHMODX_PM="pkg"
  else
    if [ "$CHMODX_IN_PROOT" = 1 ]; then CHMODX_ENV="proot"; else CHMODX_ENV="linux"; fi
    case " ${CHMODX_DISTRO} ${like} " in
      *alpine*)                                       CHMODX_PM="apk" ;;
      *arch*|*artix*|*manjaro*|*endeavouros*)         CHMODX_PM="pacman" ;;
      *fedora*|*rhel*|*centos*|*rocky*|*almalinux*)   CHMODX_PM="dnf" ;;
      *opensuse*|*suse*)                              CHMODX_PM="zypper" ;;
      *void*)                                         CHMODX_PM="xbps" ;;
      *debian*|*ubuntu*|*kali*|*parrot*|*mint*|*raspbian*|*devuan*|*pop*) CHMODX_PM="apt" ;;
    esac
    if [ -z "$CHMODX_PM" ]; then      # fallback por herramienta disponible
      local c
      for c in apt-get apt apk pacman dnf yum zypper xbps-install; do
        if chmodx_has "$c"; then CHMODX_PM="$c"; break; fi
      done
      case "$CHMODX_PM" in
        apt-get) CHMODX_PM="apt" ;;
        yum)     CHMODX_PM="dnf" ;;
        xbps-install) CHMODX_PM="xbps" ;;
      esac
    fi
    if [ -z "$CHMODX_PM" ] && chmodx_has pkg; then   # Termux sin marca (raro)
      CHMODX_ENV="termux"; CHMODX_PM="pkg"
    fi
    [ -z "$CHMODX_PM" ] && CHMODX_PM="unknown"
  fi

  # Overrides manuales (entornos raros / pruebas)
  [ -n "${CHMODX_FORCE_ENV:-}" ]    && CHMODX_ENV="$CHMODX_FORCE_ENV"
  [ -n "${CHMODX_FORCE_DISTRO:-}" ] && CHMODX_DISTRO="$CHMODX_FORCE_DISTRO"
  [ -n "${CHMODX_FORCE_PM:-}" ]     && CHMODX_PM="$CHMODX_FORCE_PM"

  CHMODX_ROOT=0
  [ "$(id -u 2>/dev/null || echo 1)" = "0" ] && CHMODX_ROOT=1
  CHMODX_SUDO=""
  if chmodx_has sudo; then CHMODX_SUDO="sudo"
  elif chmodx_has doas; then CHMODX_SUDO="doas"; fi
  return 0
}

chmodx_env_ensure() {   # detecta una sola vez, si hace falta
  case "$CHMODX_ENV" in
    termux|proot|linux) [ -n "$CHMODX_PM" ] && return 0 ;;
  esac
  chmodx_env_detect
}

chmodx_env_label() {
  chmodx_env_ensure
  case "$CHMODX_ENV" in
    termux) printf 'termux' ;;
    proot)  printf 'proot/%s' "$CHMODX_DISTRO" ;;
    linux)  printf 'linux/%s' "$CHMODX_DISTRO" ;;
    *)      printf 'desconocido' ;;
  esac
}


# ============================================================
#  TEMA / COLORES
#  Prioridad: truecolor → 256 → 16; fondo claro u oscuro.
#  Overrides: --theme=auto|dark|light · CHMODX_THEME · NO_COLOR
# ============================================================
chmodx_theme_bg() {
  case "${CHMODX_THEME:-auto}" in
    dark|light) printf '%s' "$CHMODX_THEME"; return 0 ;;
  esac
  local cfg="${COLORFGBG:-}" bg=""
  if [ -n "$cfg" ]; then
    bg="${cfg##*;}"
    case "$bg" in
      0|1|2|3|4|5|6|8)      printf 'dark';  return 0 ;;
      7|9|10|11|12|13|14|15) printf 'light'; return 0 ;;
    esac
  fi
  # Sin información del terminal, el caso más común.
  printf 'dark'
}

chmodx_theme_apply() {
  local theme="${CHMODX_THEME:-auto}" bg colors truecolor=0
  case "$theme" in
    auto|dark|light) ;;
    *)
      warn "Tema no válido: ${theme} · usa auto, dark o light"
      theme=auto
      CHMODX_THEME=auto
      ;;
  esac
  CHMODX_THEME="$theme"
  CHMODX_BG="$(chmodx_theme_bg)"

  colors="$(tput colors 2>/dev/null || echo 8)"
  case "$colors" in ''|*[!0-9]*) colors=8 ;; esac
  # En Termux mínimo puede faltar `tput`/terminfo; el nombre del TERM basta.
  case "${TERM:-}" in *256color*) if [ "$colors" -lt 256 ]; then colors=256; fi ;; esac

  case "${COLORTERM:-}" in truecolor|24bit) truecolor=1 ;; esac
  case "${TERM:-}" in *truecolor*|*24bit*|*direct*) truecolor=1 ;; esac
  if [ "$colors" -gt 256 ]; then truecolor=1; fi

  # NO_COLOR estándar: sin secuencias de color, pero la UI sigue funcionando.
  if [ -n "${NO_COLOR:-}" ]; then
    C_RESET=''; C_BOLD=''; C_DIM=''
    C_PRIMARY=''; C_PRIMARY_TRUE=''; C_PRIMARY_256=''; C_PRIMARY_16=''
    C_SUCCESS=''; C_WARN=''; C_ERR=''; C_INFO=''; C_GRAY=''; C_DARK=''
    CHMODX_COLORS=none
    return 0
  fi

  if [ "$truecolor" = 1 ]; then
    C_PRIMARY="$C_PRIMARY_TRUE"
    CHMODX_COLORS=truecolor
    # Un terminal truecolor soporta al menos la paleta de 256.
    if [ "$colors" -lt 256 ]; then colors=256; fi
  elif [ "$colors" -ge 256 ]; then
    C_PRIMARY="$C_PRIMARY_256"
    CHMODX_COLORS=256
  else
    C_PRIMARY="$C_PRIMARY_16"
    CHMODX_COLORS=16
  fi

  if [ "$colors" -ge 256 ]; then
    if [ "$CHMODX_BG" = light ]; then
      C_SUCCESS='\033[38;5;28m'
      C_WARN='\033[38;5;130m'
      C_ERR='\033[38;5;160m'
      C_INFO='\033[38;5;25m'
      C_GRAY='\033[38;5;240m'
      C_DARK='\033[38;5;250m'
    else
      C_SUCCESS='\033[38;5;35m'
      C_WARN='\033[38;5;214m'
      C_ERR='\033[38;5;203m'
      C_INFO='\033[38;5;75m'
      C_GRAY='\033[38;5;245m'
      C_DARK='\033[38;5;238m'
    fi
  else
    C_SUCCESS='\033[32m'
    C_WARN='\033[33m'
    C_ERR='\033[31m'
    C_INFO='\033[34m'
    if [ "$CHMODX_BG" = light ]; then
      C_PRIMARY='\033[34m'
      C_GRAY='\033[30m'
      C_DARK='\033[2m'
    else
      C_PRIMARY='\033[36m'
      C_GRAY='\033[37m'
      C_DARK='\033[2m'
    fi
  fi
  return 0
}

is_termux() { [ "$CHMODX_ENV" = "termux" ] || [ -n "${TERMUX_VERSION:-}" ]; }
is_proot()  { [ "$CHMODX_IN_PROOT" = 1 ]; }

chmodx_env_report() {   # para el flag --env / --doctor
  chmodx_env_detect
  chmodx_theme_apply
  local distro="${CHMODX_DISTRO_NAME:-$CHMODX_DISTRO}"
  [ -n "$CHMODX_DISTRO_VERSION" ] && distro="$distro $CHMODX_DISTRO_VERSION"
  printf 'Entorno    : %s\n'        "$(chmodx_env_label)"
  printf 'Distro     : %s\n'        "$distro"
  printf 'ID         : %s\n'        "$CHMODX_DISTRO"
  printf 'proot      : %s\n'        "$CHMODX_IN_PROOT"
  printf 'Gestor     : %s\n'        "$CHMODX_PM"
  printf 'root       : %s\n'        "$CHMODX_ROOT"
  printf 'sudo/doas  : %s\n'        "${CHMODX_SUDO:-<ninguno>}"
  local color_desc="${CHMODX_COLORS:-?}"
  case "$color_desc" in
    truecolor|none) ;;
    *) color_desc="${color_desc} colores" ;;
  esac
  if [ "$color_desc" = none ]; then color_desc="sin color"; fi
  printf 'tema       : %s (%s · %s)\n' \
    "${CHMODX_THEME:-auto}" "${CHMODX_BG:-dark}" "$color_desc"
  printf 'os-release : %s\n'        "$CHMODX_OS_RELEASE"
}

# ============================================================
#  CAPA DE PAQUETES (multi-gestor)
# ============================================================

chmodx_priv() {   # ejecuta con privilegios si hacen falta
  chmodx_env_ensure
  if [ "$CHMODX_ROOT" = 1 ] || [ "$CHMODX_ENV" = "termux" ]; then
    "$@"
  elif [ -n "$CHMODX_SUDO" ]; then
    "$CHMODX_SUDO" "$@"
  else
    err "Se necesitan permisos de root y no hay sudo/doas"
    return 1
  fi
}

chmodx_pm_update() {   # refresca índices con su propia barra
  chmodx_env_ensure
  if [ "$CHMODX_DRYRUN" = 1 ]; then info "[dry-run] actualizaría índices ($CHMODX_PM)"; return 0; fi
  case "$CHMODX_PM" in
    pkg)    chmodx_action "pkg update" env DEBIAN_FRONTEND=noninteractive pkg update -y ;;
    apt)    chmodx_action "apt-get update" chmodx_priv apt-get update -y ;;
    apk)    chmodx_action "apk update" chmodx_priv apk update ;;
    pacman) chmodx_action "pacman -Sy" chmodx_priv pacman -Sy --noconfirm ;;
    dnf)    chmodx_action "dnf makecache" chmodx_priv dnf -y makecache ;;
    zypper) chmodx_action "zypper refresh" chmodx_priv zypper --non-interactive refresh ;;
    xbps)   chmodx_action "xbps-install -S" chmodx_priv xbps-install -S ;;
    *)      err "Gestor de paquetes no soportado: ${CHMODX_PM}"; return 1 ;;
  esac
}

# Traduce un nombre canónico al paquete real de cada gestor
chmodx_pkg() {
  local n="$1"
  case "$n" in
    python)
      case "$CHMODX_PM" in apt|apk) printf 'python3' ;; *) printf 'python' ;; esac ;;
    pip)
      case "$CHMODX_PM" in apk) printf 'py3-pip' ;; apt) printf 'python3-pip' ;; *) printf 'python' ;; esac ;;
    node)
      case "$CHMODX_PM" in pkg) printf 'nodejs-lts' ;; *) printf 'nodejs' ;; esac ;;
    npm)
      case "$CHMODX_PM" in pkg) printf 'nodejs-lts' ;; *) printf 'npm' ;; esac ;;
    build-tools)
      case "$CHMODX_PM" in
        pkg)    printf 'binutils clang make' ;;
        apk)    printf 'build-base' ;;
        apt)    printf 'build-essential' ;;
        pacman) printf 'base-devel' ;;
        dnf)    printf 'make gcc gcc-c++' ;;
        *)      printf 'make gcc' ;;
      esac ;;
    tor) printf 'tor' ;;
    *)   printf '%s' "$n" ;;
  esac
}

# Binario(s) que debe exponer un paquete canónico ("" = no aplica)
chmodx_cmd_for() {
  case "$1" in
    python) printf 'python3 python' ;;
    pip)    printf 'pip3 pip' ;;
    node)   printf 'node' ;;
    npm)    printf 'npm' ;;
    *)      printf '%s' "$1" ;;
  esac
}

# ¿La base de datos del gestor dice "instalado de verdad"?
# OJO: "dpkg -s" devuelve 0 también para "deinstall ok config-files";
# hay que mirar el estado, no solo el código de salida.
_pm_db_installed_all() {   # recibe los nombres reales como argumentos
  local p
  case "$CHMODX_PM" in
    pkg|apt)
      chmodx_has dpkg || return 1
      for p in "$@"; do
        dpkg -s "$p" 2>/dev/null | grep -q '^Status:.* installed$' || return 1
      done
      return 0 ;;
    apk)
      chmodx_has apk || return 1
      for p in "$@"; do apk info -e "$p" >/dev/null 2>&1 || return 1; done
      return 0 ;;
    pacman)
      chmodx_has pacman || return 1
      pacman -Q "$@" >/dev/null 2>&1 ;;
    dnf|zypper)
      chmodx_has rpm || return 1
      rpm -q "$@" >/dev/null 2>&1 ;;
    xbps)
      chmodx_has xbps-query || return 1
      for p in "$@"; do xbps-query "$p" >/dev/null 2>&1 || return 1; done
      return 0 ;;
    *) return 1 ;;
  esac
}

chmodx_pm_installed() {   # ¿está instalado y utilizable el paquete canónico?
  chmodx_env_ensure
  local canon="${1:-}" real b
  [ -n "$canon" ] || return 1
  # 1) Si el binario existe, sirve (cubre nvm, binarios manuales, etc.)
  for b in $(chmodx_cmd_for "$canon"); do
    chmodx_has "$b" && return 0
  done
  # 2) Estado real del gestor (no "dpkg -s" a secas)
  real="$(chmodx_pkg "$canon")"
  # shellcheck disable=SC2086
  _pm_db_installed_all $real
}

# Primer nombre real que el gestor confirma como instalado.
_pm_first_db_installed() {
  local r
  for r in "$@"; do
    [ -n "$r" ] || continue
    if _pm_db_installed_all "$r"; then printf '%s\n' "$r"; return 0; fi
  done
  return 1
}

# Nombres reales que se pueden quitar para un paquete canónico.
# Se consulta la base del gestor: si "node" vino de nvm (o "python"
# de pyenv), no se intenta desinstalar un paquete del sistema que no
# existe. También cubre los alias nodejs/nodejs-lts y python3/python.
chmodx_pm_remove_names() {
  chmodx_env_ensure
  local canon="${1:-}" r
  [ -n "$canon" ] || return 1
  case "$canon" in
    node|npm)
      case "$CHMODX_PM" in
        pkg) _pm_first_db_installed nodejs-lts nodejs ;;
        *)   _pm_first_db_installed nodejs node ;;
      esac ;;
    python)
      case "$CHMODX_PM" in
        pkg|apt|apk) _pm_first_db_installed python3 python ;;
        *)           _pm_first_db_installed python python3 ;;
      esac ;;
    pip)
      case "$CHMODX_PM" in
        apt) _pm_first_db_installed python3-pip python-pip ;;
        apk) _pm_first_db_installed py3-pip ;;
        pkg) _pm_first_db_installed python3 python ;;
        *)   _pm_first_db_installed python-pip pip ;;
      esac ;;
    *)
      for r in $(chmodx_pkg "$canon"); do
        [ -n "$r" ] || continue
        _pm_db_installed_all "$r" && printf '%s\n' "$r"
      done
      return 0 ;;
  esac
}

# ¿El gestor (no solo un binario suelto) tiene instalado el canónico?
chmodx_pm_db_installed() {
  chmodx_env_ensure
  local canon="${1:-}"
  [ -n "$canon" ] || return 1
  [ -n "$(chmodx_pm_remove_names "$canon")" ]
}

# Paquetes que sostienen el sistema. En Termux "termux-tools" es
# esencial y depende de curl, coreutils, etc.; quitarlos rompe pkg.
chmodx_pm_is_protected() {
  local p="${1:-}"
  [ -n "$p" ] || return 1
  chmodx_env_ensure
  [ "$CHMODX_ENV" = "termux" ] || return 1
  case "$p" in
    termux-tools|termux-core|termux-exec|termux-keyring|termux-am|termux-am-socket|\
    apt|dpkg|bash|coreutils|curl|dash|diffutils|findutils|gawk|grep|gzip|less|\
    procps|psmisc|sed|tar|util-linux|xz-utils|dialog) return 0 ;;
  esac
  if chmodx_has apt-cache; then
    apt-cache depends termux-tools 2>/dev/null | grep -qF "Depends: $p" && return 0
  fi
  return 1
}

# ¿El gestor puede quitarlo sin dejar dependencias sin resolver?
chmodx_pm_can_remove() {
  local p="${1:-}" out
  [ -n "$p" ] || return 1
  chmodx_pm_is_protected "$p" && return 1
  case "${CHMODX_PM:-}" in
    pkg|apt)
      if chmodx_has apt-get; then
        if out="$(LC_ALL=C apt-get remove -s -y -o Dpkg::Use-Pty=0 "$p" 2>&1)"; then
          return 0
        fi
        # Solo se conserva si el solver confirma un problema real de
        # dependencias. Un fallo transitorio (lock, índice, etc.) no
        # debe dejar paquetes instalados sin intentarlo.
        case "$out" in
          *"Unsatisfied dependencies"*|*"unmet dependencies"*|*"Unable to satisfy dependencies"*|\
          *"Unmet dependencies"*|*"breaks dependency"*|*"would remove essential"*|*"essential"*|\
          *"pkgProblemResolver"*|*"but it is not going to be installed"*) return 1 ;;
        esac
        return 0
      fi ;;
  esac
  return 0
}

# Nombres reales que se pueden quitar sin romper el sistema.
chmodx_pm_removable_names() {
  chmodx_env_ensure
  local canon="${1:-}" r
  [ -n "$canon" ] || return 1
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    chmodx_pm_can_remove "$r" || continue
    printf '%s\n' "$r"
  done < <(chmodx_pm_remove_names "$canon")
}

_pm_install_raw() {   # instalación real, sin dibujar (interno)
  chmodx_env_ensure
  local pkgs=() p
  for p in "$@"; do
    # shellcheck disable=SC2207
    pkgs+=( $(chmodx_pkg "$p") )
  done
  [ "${#pkgs[@]}" -eq 0 ] && return 0
  if [ "$CHMODX_DRYRUN" = 1 ]; then
    info "[dry-run] $CHMODX_PM instalaría: ${pkgs[*]}"
    return 0
  fi
  case "$CHMODX_PM" in
    pkg)    DEBIAN_FRONTEND=noninteractive pkg install -y "${pkgs[@]}" ;;
    apt)    DEBIAN_FRONTEND=noninteractive chmodx_priv apt-get install -y \
              -o Dpkg::Use-Pty=0 \
              -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "${pkgs[@]}" ;;
    apk)    chmodx_priv apk add --no-cache "${pkgs[@]}" ;;
    pacman) chmodx_priv pacman -S --noconfirm --needed "${pkgs[@]}" ;;
    dnf)    chmodx_priv dnf install -y "${pkgs[@]}" ;;
    zypper) chmodx_priv zypper --non-interactive install "${pkgs[@]}" ;;
    xbps)   chmodx_priv xbps-install -y "${pkgs[@]}" ;;
    *)      err "Gestor de paquetes no soportado: ${CHMODX_PM}"; return 1 ;;
  esac
}

chmodx_pm_install() {   # API pública: una barra por paquete
  chmodx_env_ensure
  if [ "$CHMODX_DRYRUN" = 1 ] || [ "${_ACT_ACTIVE:-0}" = 1 ] \
     || [ "${CHMODX_QUIET:-0}" = 1 ] || [ "${CHMODX_TTY:-0}" != 1 ] || [ ! -t 1 ]; then
    _pm_install_raw "$@"
    return
  fi
  local p rc=0
  for p in "$@"; do
    chmodx_action "$p" _pm_install_raw "$p" || rc=1
  done
  return "$rc"
}

_pm_remove_raw() {   # desinstalación real, sin dibujar (interno)
  chmodx_env_ensure
  local pkgs=() p r
  local -A seen=()
  if [ "$CHMODX_DRYRUN" = 1 ]; then
    for p in "$@"; do
      for r in $(chmodx_pkg "$p"); do
        [ -n "$r" ] || continue
        [ -n "${seen[$r]:-}" ] && continue
        seen[$r]=1
        pkgs+=("$r")
      done
    done
    [ "${#pkgs[@]}" -eq 0 ] && return 0
    info "[dry-run] $CHMODX_PM quitaría: ${pkgs[*]}"
    return 0
  fi
  # Solo se pasan al gestor paquetes que su base de datos confirma
  # y que se pueden quitar sin romper dependencias del sistema.
  for p in "$@"; do
    while IFS= read -r r; do
      [ -n "$r" ] || continue
      [ -n "${seen[$r]:-}" ] && continue
      seen[$r]=1
      pkgs+=("$r")
    done < <(chmodx_pm_removable_names "$p")
  done
  [ "${#pkgs[@]}" -eq 0 ] && return 0
  case "$CHMODX_PM" in
    pkg)    chmodx_priv pkg uninstall -y "${pkgs[@]}" ;;
    apt)    chmodx_priv apt-get remove -y -o Dpkg::Use-Pty=0 "${pkgs[@]}" ;;
    apk)    chmodx_priv apk del "${pkgs[@]}" ;;
    pacman) chmodx_priv pacman -Rns --noconfirm "${pkgs[@]}" ;;
    dnf)    chmodx_priv dnf remove -y "${pkgs[@]}" ;;
    zypper) chmodx_priv zypper --non-interactive remove "${pkgs[@]}" ;;
    xbps)   chmodx_priv xbps-remove -y "${pkgs[@]}" ;;
    *)      err "Gestor de paquetes no soportado: ${CHMODX_PM}"; return 1 ;;
  esac
}

chmodx_pm_remove() {   # API pública: una barra por paquete que se quita
  chmodx_env_ensure
  if [ "$CHMODX_DRYRUN" = 1 ] || [ "${_ACT_ACTIVE:-0}" = 1 ] \
     || [ "${CHMODX_QUIET:-0}" = 1 ] || [ "${CHMODX_TTY:-0}" != 1 ] || [ ! -t 1 ]; then
    _pm_remove_raw "$@"
    return
  fi
  local p rc=0 names
  for p in "$@"; do
    if ! chmodx_pm_db_installed "$p"; then
      chmodx_action_skip "$p" "no instalado"
      continue
    fi
    names="$(chmodx_pm_removable_names "$p")"
    if [ -z "$names" ]; then
      chmodx_action_skip "$p" "protegido/dependencia del sistema"
      continue
    fi
    chmodx_action "quitando $p" _pm_remove_raw "$p" || rc=1
  done
  return "$rc"
}

# ============================================================
#  PRIVILEGIOS (sudo/doas)
#  Se piden UNA sola vez, antes de entrar al progreso, y solo
#  cuando el paso realmente va a instalar paquetes.
# ============================================================
CHMODX_SUDO_OK=0
CHMODX_SUDO_PID=''

chmodx_sudo_keepalive() {   # renueva la credencial para que no caduque a mitad
  [ "$CHMODX_SUDO" = "sudo" ] || return 0
  [ -n "${CHMODX_SUDO_PID:-}" ] && return 0
  ( while sleep 50; do "$CHMODX_SUDO" -n true 2>/dev/null || exit 0; done ) &
  CHMODX_SUDO_PID=$!
}

chmodx_sudo_acquire() {
  chmodx_env_ensure
  [ "$CHMODX_SUDO_OK" = 1 ] && return 0
  if [ "$CHMODX_ROOT" = 1 ] || [ "$CHMODX_ENV" = "termux" ]; then
    CHMODX_SUDO_OK=1
    return 0
  fi
  [ -n "$CHMODX_SUDO" ] || return 0
  [ "$CHMODX_PM" = "unknown" ] && return 0

  # ¿ya hay credencial válida (NOPASSWD o cacheada)? → no molestar
  if "$CHMODX_SUDO" -n true 2>/dev/null; then
    CHMODX_SUDO_OK=1
    chmodx_sudo_keepalive
    return 0
  fi

  if [ "$CHMODX_TTY" != 1 ]; then
    err "${CHMODX_SUDO} necesita contraseña y no hay terminal interactiva"
    err "Ejecuta el instalador en una terminal (o valida antes con: ${CHMODX_SUDO} -v)"
    return 1
  fi

  if [ "$CHMODX_QUIET" != 1 ]; then
    printf '\n %bPermisos%b\n' "$C_BOLD$C_PRIMARY" "$C_RESET"
    printf '  %b·%b Se usará %b%s%b y necesitará tu contraseña %buna sola vez%b\n' \
      "$C_PRIMARY" "$C_RESET" "$C_BOLD" "$CHMODX_SUDO" "$C_RESET" "$C_DIM" "$C_RESET"
    printf '  %b·%b No se volverá a pedir durante la operación\n\n' "$C_PRIMARY" "$C_RESET"
  fi

  if [ "$CHMODX_SUDO" = "sudo" ]; then
    if ! "$CHMODX_SUDO" -v; then
      echo
      err "No se pudo validar la contraseña de ${CHMODX_SUDO}"
      return 1
    fi
    chmodx_sudo_keepalive
  else
    "$CHMODX_SUDO" true || { err "No se pudo validar ${CHMODX_SUDO}"; return 1; }
  fi

  CHMODX_SUDO_OK=1
  [ "$CHMODX_QUIET" != 1 ] && printf '\n  %b✓%b Permisos listos\n' "$C_SUCCESS" "$C_RESET"
  return 0
}

# ¿Este paso va a tocar el gestor de paquetes? (para pedir sudo solo si hace falta)
_step_needs_privs() {
  chmodx_env_ensure
  [ "$CHMODX_ROOT" = 1 ] && return 1
  [ "$CHMODX_ENV" = "termux" ] && return 1
  [ -n "$CHMODX_SUDO" ] || return 1
  [ "$CHMODX_PM" = "unknown" ] && return 1
  case "${1:-}" in
    chmodx_pm_*|pkg|apt|apt-get|apk|pacman|dnf|yum|zypper|xbps-install) return 0 ;;
  esac
  if [ "$(type -t "${1:-}" 2>/dev/null || true)" = "function" ]; then
    local _body
    _body="$(declare -f "$1" 2>/dev/null || true)"
    case "$_body" in
      *chmodx_pm_*|*chmodx_priv*) return 0 ;;
    esac
  fi
  case " $* " in
    *" pkg "*|*" apt "*|*" apt-get "*|*" apk "*|*" pacman "*|*" dnf "*|*" zypper "*) return 0 ;;
  esac
  return 1
}

# Sugerencia de arreglo según el gestor y el estado del disco
_pm_hint() {
  local mb
  mb=$(chmodx_disk_free_mb "${PREFIX:-/}" 2>/dev/null || true)
  case "$mb" in ''|*[!0-9]*) : ;; *)
    if [ "$mb" -lt 80 ]; then
      warn "Espacio libre crítico (${mb} MB): libera espacio antes de reintentar"
      return 0
    fi ;;
  esac
  case "$CHMODX_PM" in
    pkg)    warn "Sugerencia: pkg update && pkg upgrade · revisa el nombre del paquete" ;;
    apt)    warn "Sugerencia: ${CHMODX_SUDO:+$CHMODX_SUDO }apt-get update && ${CHMODX_SUDO:+$CHMODX_SUDO }apt-get -f install" ;;
    apk)    warn "Sugerencia: ${CHMODX_SUDO:+$CHMODX_SUDO }apk update && ${CHMODX_SUDO:+$CHMODX_SUDO }apk fix" ;;
    pacman) warn "Sugerencia: ${CHMODX_SUDO:+$CHMODX_SUDO }pacman -Syu" ;;
    dnf)    warn "Sugerencia: ${CHMODX_SUDO:+$CHMODX_SUDO }dnf check-update" ;;
    *)      warn "Revisa la conexión y el nombre del paquete" ;;
  esac
}

# ¿El paquete existe en los índices del gestor? (para categorías opcionales)
chmodx_pm_available() {
  chmodx_env_ensure
  local canon="${1:-}" real
  [ -n "$canon" ] || return 1
  real="$(chmodx_pkg "$canon")"
  # shellcheck disable=SC2086
  case "$CHMODX_PM" in
    pkg|apt)
      if chmodx_has apt-cache; then apt-cache show $real >/dev/null 2>&1; else return 0; fi ;;
    apk)    apk search -x $real >/dev/null 2>&1 ;;
    pacman) pacman -Si $real >/dev/null 2>&1 ;;
    dnf)    dnf -q info $real >/dev/null 2>&1 ;;
    zypper) zypper -q info $real >/dev/null 2>&1 ;;
    xbps)   xbps-query -R $real >/dev/null 2>&1 ;;
    *)      return 0 ;;
  esac
}

# Igual que chmodx_pm_ensure, pero los paquetes que no existen en este
# entorno se omiten en vez de abortar toda la categoría.
chmodx_pm_ensure_optional() {
  chmodx_env_ensure
  local p rc=0
  for p in "$@"; do
    if chmodx_pm_installed "$p"; then
      chmodx_action_skip "$p" "ya instalado"
      continue
    fi
    if ! chmodx_pm_available "$p"; then
      chmodx_action_skip "$p" "no disponible en ${CHMODX_PM}"
      continue
    fi
    if ! chmodx_pm_install "$p"; then
      warn "No se pudo instalar $p · se omite"
      rc=1
    fi
  done
  return "$rc"
}

chmodx_pm_ensure() {   # instala solo lo que falte (una barra por paquete)
  chmodx_env_ensure
  local p
  for p in "$@"; do
    if chmodx_pm_installed "$p"; then
      chmodx_action_skip "$p" "ya instalado"
      continue
    fi
    if ! chmodx_pm_install "$p"; then
      warn "Fallo al instalar $p · actualizando índices y reintentando…"
      chmodx_pm_update >/dev/null 2>&1 || true
      if ! chmodx_pm_install "$p"; then
        err "No se pudo instalar $p"
        _pm_hint
        return 1
      fi
    fi
  done
  return 0
}

# Compatibilidad con proyectos antiguos
is_installed() { chmodx_pm_installed "$1"; }
pkg_ensure()   { chmodx_pm_ensure "$@"; }
need() { chmodx_has "$1" || { err "Falta el comando: $1"; return 1; }; }

# ============================================================
#  DIAGNÓSTICO PREVIO (preflight inteligente)
# ============================================================
CHMODX_PREFLIGHT_OK=1

_pf_ok()   { [ "$CHMODX_QUIET" = 1 ] && return 0; printf '  %b✓%b %s\n' "$C_SUCCESS" "$C_RESET" "$*"; }
_pf_warn() { [ "$CHMODX_QUIET" = 1 ] && return 0; printf '  %b!%b %s\n' "$C_WARN" "$C_RESET" "$*"; }
_pf_bad()  { CHMODX_PREFLIGHT_OK=0; printf '  %b✗%b %s\n' "$C_ERR" "$C_RESET" "$*" >&2; }

chmodx_disk_free_mb() {
  local dir="${1:-/}"
  [ -d "$dir" ] || dir=/
  df -Pk "$dir" 2>/dev/null | awk 'NR==2 { printf "%d", $4 / 1024 }'
}

chmodx_net_ok() {   # 0 = hay red (si no se puede comprobar, no bloquea)
  local url="${1:-https://example.com}"
  if chmodx_has curl; then
    curl -fsSI --max-time 5 "$url" >/dev/null 2>&1 && return 0 || return 1
  fi
  if chmodx_has wget; then
    wget -q -T 5 --spider "$url" >/dev/null 2>&1 && return 0 || return 1
  fi
  return 0
}

chmodx_preflight() {
  chmodx_env_ensure
  CHMODX_PREFLIGHT_OK=1
  [ "$CHMODX_QUIET" = 1 ] && return 0
  printf ' %bDiagnóstico%b\n' "$C_BOLD$C_PRIMARY" "$C_RESET"

  # 1. gestor de paquetes
  if [ "$CHMODX_PM" = "unknown" ]; then
    _pf_bad "Gestor de paquetes no detectado (${CHMODX_DISTRO})"
  else
    _pf_ok "Entorno $(chmodx_env_label) · gestor ${CHMODX_PM}"
  fi

  # 2. permisos reales de instalación
  if [ "$CHMODX_ROOT" = 1 ]; then
    _pf_ok "Permisos de instalación disponibles (root)"
  elif [ "$CHMODX_ENV" = "termux" ]; then
    _pf_ok "Permisos de instalación disponibles (Termux)"
  elif [ -n "$CHMODX_SUDO" ]; then
    _pf_ok "Se usará ${CHMODX_SUDO} (la contraseña se pide una sola vez)"
  else
    _pf_bad "Sin root ni sudo/doas: no se puede instalar ni desinstalar"
  fi

  # 3. espacio en disco
  local mb
  mb=$(chmodx_disk_free_mb "${PREFIX:-/}")
  case "$mb" in
    ''|*[!0-9]*) : ;;
    *)
      if [ "$mb" -lt 100 ]; then   _pf_bad  "Espacio libre bajo: ${mb} MB"
      elif [ "$mb" -lt 400 ]; then _pf_warn "Espacio libre justo: ${mb} MB"
      else                         _pf_ok   "Espacio libre: ${mb} MB"
      fi ;;
  esac

  # 4. red (en simulación no se comprueba)
  if [ "$CHMODX_DRYRUN" = 1 ]; then
    _pf_warn "Simulación activa: no se comprueba la red"
  elif chmodx_net_ok; then
    _pf_ok "Conectividad con los repositorios"
  else
    _pf_warn "Sin conexión a internet (o repositorios caídos)"
  fi

  # 5. herramientas del sistema para la UI en vivo
  local c miss=''
  for c in tail sed grep mktemp; do chmodx_has "$c" || miss="${miss}${c} "; done
  if [ -n "$miss" ]; then _pf_warn "Comandos ausentes: ${miss}"; else _pf_ok "Herramientas del sistema completas"; fi

  echo
  chmodx_pause "Revisa el diagnóstico"
  if [ "$CHMODX_PREFLIGHT_OK" != 1 ]; then
    warn "El entorno no está listo: revisa los puntos marcados con ✗"
    return 1
  fi
  return 0
}

# --- Init: detección + trap de limpieza + log ----------------
chmodx_init() {
  chmodx_env_detect
  chmodx_theme_apply
  CHMODX_START=${SECONDS:-0}
  if [ -n "$CHMODX_LOG" ]; then
    mkdir -p "$(dirname "$CHMODX_LOG")" 2>/dev/null || true
    : >"$CHMODX_LOG"
  fi
  trap 'printf "\033[0m"; [ -n "${CHMODX_SUDO_PID:-}" ] && kill "$CHMODX_SUDO_PID" 2>/dev/null || true; if [ -n "${_LIVE_PAUSE_FIFO:-}" ]; then exec 9>&-; rm -f "$_LIVE_PAUSE_FIFO" 2>/dev/null || true; fi; if command -v tput >/dev/null 2>&1; then tput cnorm 2>/dev/null || true; fi' EXIT
  trap 'err "Fallo en la línea $LINENO"; if [ -n "$CHMODX_LOG" ]; then tail -n 15 "$CHMODX_LOG" >&2; fi; exit 1' ERR
  trap 'exit 130' INT
  trap 'exit 143' TERM
}
# ============================================================
#  CHMODX UI · ancho, centrado, secciones, pasos,
#  barra de progreso de marca, resumen
#  (parte de lib/chmodx.sh)
# ============================================================

CHMODX_TOTAL=0
CHMODX_N=0
CHMODX_STEPS_OK=0
CHMODX_STEPS_SKIP=0
CHMODX_STEPS_ERR=0

_UI_W=''
_ui_width() {   # cacheado: tput es caro y se llama en cada frame
  if [ -n "$_UI_W" ]; then printf '%s' "$_UI_W"; return 0; fi
  local w
  w=$(command -v tput >/dev/null 2>&1 && tput cols 2>/dev/null || echo 80)
  case "$w" in ''|*[!0-9]*) w=80 ;; esac
  [ "$w" -lt 40 ] && w=40
  _UI_W=$w
  printf '%s' "$w"
}

_ui_width_refresh() { _UI_W=''; _ui_width >/dev/null; }

chmodx_center() {
  local t="${1:-}" w
  w=$(_ui_width)
  printf '%*s%s\n' $(( (w - ${#t}) / 2 )) '' "$t"
}

hr() {
  local w i line=''
  w=$(_ui_width)
  for ((i = 0; i < w; i++)); do line+='─'; done
  printf "${C_DARK}%s${C_RESET}\n" "$line"
}

# Barra por porcentaje (relleno continuo):  _bar_pct <0-100> [ancho]
_bar_pct_str() {   # _bar_pct_str <pct> <ancho>  → deja la barra en _BAR_PCT
  local pct="${1:-0}" w="${2:-22}" filled i f='' e='' num
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  filled=$(( w * pct / 100 ))
  for ((i = 0; i < filled; i++)); do f+='█'; done
  for ((i = filled; i < w; i++)); do e+='░'; done
  printf -v num '%4d' "$pct"
  printf -v _BAR_PCT '%b%s%b%s%b%s%%%b' \
    "$C_PRIMARY" "$f" "$C_DARK" "$e" "$C_PRIMARY" "$num" "$C_RESET"
}
_bar_pct() { _bar_pct_str "${1:-0}" "${2:-22}"; printf '%s' "$_BAR_PCT"; }

# Barra de progreso en el color de marca:  chmodx_bar <n> <total> [ancho]
chmodx_bar() {
  local n="${1:-0}" t="${2:-1}" w="${3:-}"
  [ -z "$w" ] && { w=22; [ "$(_ui_width)" -lt 60 ] && w=12; }
  [ "$t" -le 0 ] && t=1
  [ "$n" -gt "$t" ] && n="$t"
  [ "$n" -lt 0 ] && n=0
  _bar_pct $(( 100 * n / t )) "$w"
}

chmodx_steps_total() { CHMODX_TOTAL="${1:-0}"; }

_step_line() {   # _step_line <color> <tag> <texto> <segundos> [n_barra]
  local cols w tw bn
  bn="${5:-$CHMODX_N}"
  cols=$(_ui_width)
  if [ "$CHMODX_TTY" = 1 ] && [ "$CHMODX_TOTAL" -gt 1 ] && [ "$cols" -ge 60 ]; then
    w=18; [ "$cols" -ge 90 ] && w=22
    tw=$(( cols - (w + 30) ))
    [ "$tw" -lt 10 ] && tw=10
    [ "$tw" -gt 40 ] && tw=40
    printf ' [%d/%d] %s  %b%-*.*s%b %b%s%b %s\n' \
      "$CHMODX_N" "$CHMODX_TOTAL" \
      "$(chmodx_bar "$bn" "$CHMODX_TOTAL")" \
      "$C_BOLD" "$tw" "$tw" "${3:-}" "$C_RESET" \
      "$1" "$2" "$C_RESET" "${4:-}"
  elif [ "$CHMODX_TTY" = 1 ] && [ "$CHMODX_TOTAL" -gt 1 ]; then
    local bw tw
    bw=8; [ "$cols" -lt 46 ] && bw=6
    tw=$(( cols - 28 - bw ))
    [ "$tw" -lt 6 ] && tw=6
    [ "$tw" -gt 30 ] && tw=30
    printf ' [%d/%d] %s %b%-*.*s%b %b%s%b %s\n' \
      "$CHMODX_N" "$CHMODX_TOTAL" \
      "$(chmodx_bar "$bn" "$CHMODX_TOTAL" "$bw")" \
      "$C_BOLD" "$tw" "$tw" "${3:-}" "$C_RESET" \
      "$1" "$2" "$C_RESET" "${4:-}"
  else
    printf ' [%d/%d] %-40s %b%s%b %s\n' \
      "$CHMODX_N" "$CHMODX_TOTAL" "${3:-}" "$1" "$2" "$C_RESET" "${4:-}"
  fi
}

# ============================================================
#  ACCIONES ANIMADAS
#  Cada paquete / tarea tiene SU PROPIA barra: se llena de
#  0 a 100 %, con destello móvil, borde luminoso y contador.
# ============================================================
# Pausa sin fork: FIFO con read -t (en proot/Termux dormir es caro)
_LIVE_PAUSE_FIFO=''
_live_pause_setup() {
  [ -n "$_LIVE_PAUSE_FIFO" ] && return 0
  local d f
  d="$(_live_tmpdir)"
  f="${d}/cx-pause-${UID:-0}"
  rm -f "$f" 2>/dev/null || true
  if mkfifo "$f" 2>/dev/null && exec 9<>"$f"; then
    _LIVE_PAUSE_FIFO="$f"
  else
    rm -f "$f" 2>/dev/null || true
  fi
}

_live_pause() {   # _live_pause [segundos]
  if [ -n "$_LIVE_PAUSE_FIFO" ]; then
    read -r -t "${1:-0.07}" -u 9 _ 2>/dev/null || true
  else
    sleep "${1:-0.07}" 2>/dev/null || sleep 1
  fi
}

_ACT_ACTIVE=0
_ACT_DRAWN=0
_ACT_HAS_DET=0
_ACT_TOTAL=0
_ACT_OK=0
_ACT_FAIL=0
_ACT_LAST_PCT=0

_now_ms_v() {   # deja los ms en _NOW_MS (sin fork)
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local t="${EPOCHREALTIME//[!0-9]/}"
    _NOW_MS=$(( t / 1000 ))
  else
    _NOW_MS=$(( ${SECONDS:-0} * 1000 ))
  fi
}
_now_ms() { _now_ms_v; printf '%s' "$_NOW_MS"; }

_fmt_dur_v() {   # deja la duración en _FMT_DUR (sin fork)
  local ms="${1:-0}"
  [ "$ms" -lt 0 ] && ms=0
  if [ "$ms" -lt 10000 ]; then
    printf -v _FMT_DUR '%d.%ds' $(( ms / 1000 )) $(( (ms % 1000) / 100 ))
  elif [ "$ms" -lt 60000 ]; then
    printf -v _FMT_DUR '%ds' $(( (ms + 500) / 1000 ))
  else
    printf -v _FMT_DUR '%dm %02ds' $(( ms / 60000 )) $(( (ms % 60000) / 1000 ))
  fi
}
_fmt_dur() { _fmt_dur_v "${1:-0}"; printf '%s' "$_FMT_DUR"; }

_act_barw() {
  local c; c=$(_ui_width)
  if   [ "$c" -ge 95 ]; then printf 28
  elif [ "$c" -ge 70 ]; then printf 22
  elif [ "$c" -ge 50 ]; then printf 16
  else                       printf 10
  fi
}

_act_labelw() {
  local c bw lw
  c=$(_ui_width); bw=$(_act_barw)
  lw=$(( c - 21 - bw ))
  [ "$lw" -lt 6 ] && lw=6
  [ "$lw" -gt 32 ] && lw=32
  printf '%s' "$lw"
}

# Barra con relleno, destello móvil y borde luminoso
_bar_anim_str() {   # deja la barra en _BAR_ANIM (un solo write por frame)
  local pct="${1:-0}" w="${2:-20}" ph="${3:-0}" i filled sh edge out='' part
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  filled=$(( w * pct / 100 ))
  [ "$filled" -gt "$w" ] && filled=$w
  sh=0; [ "$filled" -gt 0 ] && sh=$(( ph % filled ))
  edge=0; [ "$pct" -gt 0 ] && [ "$pct" -lt 100 ] && edge=1
  printf -v part '%b' "$C_PRIMARY"; out+="$part"
  for ((i = 0; i < filled; i++)); do
    if [ "$edge" = 1 ] && [ "$i" -eq "$sh" ]; then
      out+=$'\033[1m█\033[22m'          # destello
    else
      out+='█'
    fi
  done
  printf -v part '%b' "$C_DARK"; out+="$part"
  [ "$edge" = 1 ] && [ "$filled" -lt "$w" ] && out+='▓'
  for ((i = filled + edge; i < w; i++)); do out+='░'; done
  printf -v part '%b' "$C_RESET"; out+="$part"
  _BAR_ANIM="$out"
}
_bar_anim() { _bar_anim_str "${1:-0}" "${2:-20}" "${3:-0}"; printf '%s' "$_BAR_ANIM"; }

# Línea de una acción:  ✓ git   ████████░░░░  62%   1.2s
_act_line_str() {   # deja la línea completa en _ACT_LINE
  local g="$1" col="$2" label="$3" pct="$4" secs="$5" ph="$6" tag="${7:-${4}%}" lw bw
  _ui_width >/dev/null 2>&1
  if   [ "${_UI_W:-80}" -ge 95 ]; then bw=28
  elif [ "${_UI_W:-80}" -ge 70 ]; then bw=22
  elif [ "${_UI_W:-80}" -ge 50 ]; then bw=16
  else bw=10; fi
  lw=$(( ${_UI_W:-80} - 21 - bw ))
  [ "$lw" -lt 6 ] && lw=6
  [ "$lw" -gt 32 ] && lw=32
  _bar_anim_str "$pct" "$bw" "$ph"
  printf -v _ACT_LINE '   %b%s%b %b%-*.*s%b  %s %b%4s%b  %b%6s%b' \
    "$col" "$g" "$C_RESET" "$C_BOLD" "$lw" "$lw" "$label" "$C_RESET" \
    "$_BAR_ANIM" "$C_PRIMARY" "$tag" "$C_RESET" "$C_DIM" "$secs" "$C_RESET"
}
_act_line() { _act_line_str "$@"; printf '%s' "$_ACT_LINE"; }

# Redibuja la acción en su sitio (detalle vivo debajo de la barra)
# Sin borrar antes: escribe encima y limpia el sobrante al final (anti-parpadeo)
_act_paint() {   # <glyph> <color> <label> <pct> <secs> <fase> [detalle]
  [ "${CHMODX_TTY:-0}" = 1 ] || return 0
  local det="${7:-}" maxw out detline
  _ui_width >/dev/null 2>&1
  maxw=$(( ${_UI_W:-80} - 9 )); [ "$maxw" -lt 12 ] && maxw=12
  _ACT_LAST_PCT="$4"
  _act_line_str "$1" "$2" "$3" "$4" "$5" "$6"

  if [ "$_ACT_DRAWN" = 1 ]; then
    out=$'\r'"$_ACT_LINE"$'\033[K'                 # sobrescribe la línea
  else
    out=$'\033[?25l'"$_ACT_LINE"$'\033[K'           # cursor oculto
  fi

  if [ -n "$det" ]; then
    printf -v detline '   %b  │%b %b%s%b' \
      "$C_DARK" "$C_RESET" "$C_DIM" "${det:0:$maxw}" "$C_RESET"
    out+=$'\n\r'"$detline"$'\033[K\033[1A'         # detalle y volver arriba
    _ACT_HAS_DET=1
  elif [ "$_ACT_HAS_DET" = 1 ]; then
    out+=$'\n\r\033[2K\033[1A'                    # quitar detalle viejo
    _ACT_HAS_DET=0
  fi
  printf '%s' "$out"
  _ACT_DRAWN=1
}

_act_close() {   # <glyph> <color> <label> <pct> <secs> [tag]
  [ "${CHMODX_TTY:-0}" = 1 ] || return 0
  local out
  _act_line_str "$1" "$2" "$3" "$4" "$5" 1 "${6:-${4}%}"
  out=$'\r'"$_ACT_LINE"$'\033[K'
  if [ "$_ACT_HAS_DET" = 1 ]; then
    out+=$'\n\r\033[2K'          # limpia el detalle; el cursor queda abajo
    _ACT_HAS_DET=0
  else
    out+=$'\n'
  fi
  out+=$'\033[?25h'               # restaurar cursor
  printf '%s' "$out"
  _ACT_DRAWN=0
}

# Acción animada: ejecuta el comando con su barra de 0 a 100 %
chmodx_action() {   # chmodx_action <etiqueta> <comando...>
  local label="${1:-}"; shift
  local rc=0 start out='' pid ticks=0 disp=0 target=0 bytes=0 last=-1 det='' ms dur spin
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

  # Sin animación: --quiet, sin TTY, salida redirigida o acción anidada
  if [ "${CHMODX_QUIET:-0}" = 1 ] || [ "${CHMODX_VERBOSE:-0}" = 1 ] \
     || [ "${CHMODX_TTY:-0}" != 1 ] || [ ! -t 1 ] || [ "$_ACT_ACTIVE" = 1 ]; then
    if "$@" </dev/null; then _ACT_OK=$((_ACT_OK + 1)); return 0; fi
    rc=$?; _ACT_FAIL=$((_ACT_FAIL + 1)); return "$rc"
  fi

  _ACT_TOTAL=$(( _ACT_TOTAL + 1 ))     # solo las acciones visibles cuentan
  _live_pause_setup
  _ACT_ACTIVE=1
  _ACT_DRAWN=0; _ACT_HAS_DET=0; _ACT_LAST_PCT=0
  local tmpd; tmpd="$(_live_tmpdir)"
  out=$(mktemp "${tmpd}/cx-act.XXXXXX" 2>/dev/null) || out=''
  [ -n "$out" ] && { : >"$out" 2>/dev/null || out=''; }

  _now_ms_v; start=$_NOW_MS
  if [ -n "$out" ]; then
    "$@" </dev/null >"$out" 2>&1 &
  else
    "$@" </dev/null >/dev/null 2>&1 &
  fi
  pid=$!

  _act_paint "${frames:0:1}" "$C_PRIMARY" "$label" 0 '0.0s' 0
  while kill -0 "$pid" 2>/dev/null; do
    ticks=$((ticks + 1))
    _now_ms_v; ms=$(( _NOW_MS - start ))
    target=$(( 10 + 88 * (ms / 500) / ((ms / 500) + 3) ))
    if [ -n "$out" ] && [ $((ticks % 6)) -eq 0 ]; then
      bytes=$(wc -c <"$out" 2>/dev/null || printf 0)
      case "$bytes" in ''|*[!0-9]*) bytes=0 ;; esac
      target=$(( target + bytes / 4096 ))
      if [ "$bytes" != "$last" ]; then
        last=$bytes
        det=$(_live_tail_lines "$out" 1 | head -n 1)
      fi
    fi
    [ "$target" -gt 94 ] && target=94
    [ "$target" -lt "$disp" ] && target=$disp
    disp=$(( (disp + target * 2) / 3 ))      # suavizado
    if [ -z "$det" ] && [ "$ms" -ge 8000 ]; then
      det='sin salida todavía · el proceso sigue trabajando'
    fi
    spin="${frames:$((ticks % 10)):1}"
    _fmt_dur_v "$ms"
    _act_paint "$spin" "$C_PRIMARY" "$label" "$disp" "$_FMT_DUR" "$ticks" "$det"
    _live_pause "${CHMODX_LIVE_DELAY:-0.07}"
  done
  wait "$pid" || rc=$?
  _now_ms_v; ms=$(( _NOW_MS - start ))
  _fmt_dur_v "$ms"; dur="$_FMT_DUR"

  if [ -n "$out" ] && [ -n "${CHMODX_LOG:-}" ]; then
    cat "$out" >>"$CHMODX_LOG" 2>/dev/null || true
  fi

  if [ "$rc" -eq 0 ]; then
    if [ "$ticks" -gt 0 ]; then
      _act_paint '✓' "$C_SUCCESS" "$label" 100 "$dur" $((ticks + 1)) ''
      _live_pause 0.07
    fi
    _act_close '✓' "$C_SUCCESS" "$label" 100 "$dur"
    _ACT_OK=$((_ACT_OK + 1))
  else
    _act_close '✗' "$C_ERR" "$label" "${_ACT_LAST_PCT:-0}" "$dur" 'ERR'
    _ACT_FAIL=$((_ACT_FAIL + 1))
    if [ -n "$out" ]; then
      CHMODX_LAST_OUT=$(cat "$out" 2>/dev/null || true)
      local maxw=$(( $(_ui_width) - 9 )); [ "$maxw" -lt 20 ] && maxw=20
      printf '%s\n' "$CHMODX_LAST_OUT" | tail -n 8 | while IFS= read -r l; do
        printf '      %b%s%b\n' "$C_DIM" "${l:0:$maxw}" "$C_RESET"
      done
    fi
  fi
  [ -n "$out" ] && rm -f "$out" 2>/dev/null || true
  _ACT_ACTIVE=0
  return "$rc"
}

# Paquete que ya estaba: línea informativa, sin barra
chmodx_action_skip() {   # <etiqueta> [motivo]
  [ "${CHMODX_TTY:-0}" = 1 ] && [ "${CHMODX_QUIET:-0}" != 1 ] || return 0
  local label="${1:-}" why="${2:-}" lw
  lw=$(_act_labelw)
  printf '   %b·%b %b%-*.*s%b  %b%s%b\n' \
    "$C_DIM" "$C_RESET" "$C_BOLD" "$lw" "$lw" "$label" "$C_RESET" "$C_DIM" "$why" "$C_RESET"
}

chmodx_run() { chmodx_action "$@"; }

# Cabecera de paso (sin barra: las barras son de cada acción)
_step_head() {
  [ "${CHMODX_TTY:-0}" = 1 ] || return 0
  local tw=$(( $(_ui_width) - 8 ))
  [ "$tw" -lt 10 ] && tw=10
  printf ' %b[%d/%d]%b %b%-*.*s%b\n' \
    "$C_PRIMARY" "$CHMODX_N" "$CHMODX_TOTAL" "$C_RESET" \
    "$C_BOLD" "$tw" "$tw" "${1:-}" "$C_RESET"
}

# ¿El paso dibuja acciones propias (paquetes) o usa la barra genérica?
_step_uses_actions() {
  local fn="${1:-}"
  case "$fn" in
    chmodx_action|chmodx_run|chmodx_pm_ensure|chmodx_pm_update|chmodx_pm_install|chmodx_pm_remove) return 0 ;;
  esac
  [ "$(type -t "$fn" 2>/dev/null || true)" = "function" ] || return 1
  local body
  body="$(declare -f "$fn" 2>/dev/null || true)"
  case "$body" in
    *chmodx_action*|*chmodx_run*|*chmodx_pm_ensure*|*chmodx_pm_update*|*chmodx_pm_install*|*chmodx_pm_remove*) return 0 ;;
  esac
  return 1
}

# Paso con acciones: cabecera + una barra por paquete + pie
_run_step_actions() {   # _run_step_actions <texto> <cmd...>
  local text="${1:-}"; shift
  local rc=0 start ms
  _ACT_TOTAL=0; _ACT_OK=0; _ACT_FAIL=0
  _step_head "$text"
  start=$(_now_ms)
  if "$@"; then rc=0; else rc=$?; fi
  ms=$(( $(_now_ms) - start ))
  if [ "$rc" -eq 0 ]; then
    CHMODX_STEPS_OK=$((CHMODX_STEPS_OK + 1))
    if [ "$_ACT_TOTAL" -gt 1 ]; then
      printf '   %b└─%b %b%d acciones · %s%b\n' \
        "$C_DARK" "$C_RESET" "$C_DIM" "$_ACT_TOTAL" "$(_fmt_dur "$ms")" "$C_RESET"
    fi
  else
    CHMODX_STEPS_ERR=$((CHMODX_STEPS_ERR + 1))
    if [ "$_ACT_TOTAL" -gt 0 ]; then
      printf '   %b└─%b %b%d/%d acciones · falló%b · %s\n' \
        "$C_DARK" "$C_RESET" "$C_ERR" "$_ACT_OK" "$_ACT_TOTAL" "$C_RESET" "$(_fmt_dur "$ms")"
    fi
  fi
  return "$rc"
}

# ============================================================
#  PROGRESO EN VIVO
#  La barra se llena mientras el proceso trabaja y encima se
#  muestran sus últimos mensajes (se limpian en cada refresco).
# ============================================================
_LIVE_DRAWN=0
_LIVE_TAIL_N="${CHMODX_LIVE_TAIL:-3}"
_LIVE_TAIL_CACHE=''
_LIVE_FRAME_CACHE=''

# Últimas líneas legibles de la salida del proceso
_live_tail_lines() {   # _live_tail_lines <archivo> <n>
  local f="$1" n="${2:-3}" max esc
  max=$(( $(_ui_width) - 4 )); [ "$max" -lt 16 ] && max=16
  esc=$(printf '\033')
  [ -s "$f" ] || return 0
  tail -c 8192 "$f" 2>/dev/null \
    | tr '\r' '\n' \
    | sed -e "s/${esc}\[[0-9;?]*[A-Za-z]//g" -e 's/[[:cntrl:]]//g' \
    | grep -v '^[[:space:]]*$' \
    | tail -n "$n" \
    | while IFS= read -r l; do LC_ALL=C printf '%s\n' "${l:0:$max}"; done
}

# Línea del paso: [n/N] barra · texto · spinner · tiempo
_live_frame_str() {   # deja la línea del paso en _LIVE_FRAME (sin forks)
  local pct="${1:-0}" text="${2:-}" spin="${3:-}" secs="${4:-}" cols w tw
  _ui_width >/dev/null 2>&1
  cols=${_UI_W:-80}
  if [ "$cols" -lt 60 ]; then      # compacto: misma barra que la línea final
    w=8; [ "$cols" -lt 46 ] && w=6
    tw=$(( cols - 28 - w ))
    [ "$tw" -lt 6 ] && tw=6
    [ "$tw" -gt 30 ] && tw=30
    _bar_pct_str "$pct" "$w"
    printf -v _LIVE_FRAME ' [%d/%d] %s %b%-*.*s%b %b%s%b %5s' \
      "$CHMODX_N" "$CHMODX_TOTAL" "$_BAR_PCT" \
      "$C_BOLD" "$tw" "$tw" "$text" "$C_RESET" \
      "$C_PRIMARY" "$spin" "$C_RESET" "$secs"
    return 0
  fi
  w=18; [ "$cols" -ge 90 ] && w=22
  tw=$(( cols - (w + 30) ))
  [ "$tw" -lt 12 ] && tw=12
  [ "$tw" -gt 46 ] && tw=46
  _bar_pct_str "$pct" "$w"
  printf -v _LIVE_FRAME ' [%d/%d] %s  %b%-*.*s%b %b%s%b %5s' \
    "$CHMODX_N" "$CHMODX_TOTAL" "$_BAR_PCT" \
    "$C_BOLD" "$tw" "$tw" "$text" "$C_RESET" \
    "$C_PRIMARY" "$spin" "$C_RESET" "$secs"
}
_live_frame() { _live_frame_str "$@"; printf '%s' "$_LIVE_FRAME"; }

# Dibuja el bloque (tail + barra) sin repintar lo que no cambió
# (evita el titileo: la data solo se redibuja cuando llega salida nueva)
_live_block() {   # _live_block <pct> <texto> <spinner> <tiempo> <archivo> [nota]
  local pct="$1" text="$2" spin="$3" secs="$4" f="$5" note="${6:-}"
  local n="$_LIVE_TAIL_N" i l tail='' frame
  local lines=()

  while IFS= read -r l; do lines+=("$l"); done < <(_live_tail_lines "$f" "$n")
  [ -n "$note" ] && lines+=("$note")
  while [ "${#lines[@]}" -gt "$n" ]; do
    unset 'lines[0]'
    lines=("${lines[@]}")
  done
  for ((i = 0; i < n; i++)); do tail+="${lines[$i]:-}"$'\n'; done
  _live_frame_str "$pct" "$text" "$spin" "$secs"
  frame="$_LIVE_FRAME"

  if [ "$_LIVE_DRAWN" != 1 ]; then          # primer dibujo: reserva el área
    printf '\033[?25l'                       # oculta el cursor (menos titileo)
    for ((i = 0; i < n; i++)); do printf '\033[2K\n'; done
    printf '%s' "$frame"
    _LIVE_DRAWN=1
    _LIVE_TAIL_CACHE="$tail"
    _LIVE_FRAME_CACHE="$frame"
    return 0
  fi

  if [ "$tail" != "$_LIVE_TAIL_CACHE" ]; then   # llegó salida nueva
    local out=$'\r' part
    [ "$n" -gt 0 ] && out=$'\033['"$n"A$'\r'
    for ((i = 0; i < n; i++)); do
      l="${lines[$i]:-}"
      part=''
      if [ -n "$l" ]; then
        printf -v part ' %b›%b %b%s%b' "$C_DARK" "$C_RESET" "$C_DIM" "$l" "$C_RESET"
      fi
      out+="$part"$'\033[K\n'                 # escribe y limpia el sobrante
    done
    out+="$frame"$'\033[K'                     # barra del paso
    printf '%s' "$out"
    _LIVE_TAIL_CACHE="$tail"
    _LIVE_FRAME_CACHE="$frame"
  elif [ "$frame" != "$_LIVE_FRAME_CACHE" ]; then
    printf '\r%s\033[K' "$frame"              # solo la barra, sin borrar antes
    _LIVE_FRAME_CACHE="$frame"
  fi
}

# Cierra el bloque y deja la línea final limpia
_live_end() {   # _live_end <color> <tag> <texto> <tiempo>
  if [ "$_LIVE_DRAWN" = 1 ]; then
    # Escribe la línea final ENCIMA del bloque y limpia lo que sobra después:
    # borrar antes de dibujar es lo que produce el destello.
    if [ "$_LIVE_TAIL_N" -gt 0 ]; then
      printf '\033[%dA\r' "$_LIVE_TAIL_N"
    else
      printf '\r'
    fi
    _step_line "$1" "$2" "$3" "$4" "$CHMODX_TOTAL"
    printf '\033[J\033[?25h'
    _LIVE_DRAWN=0
    _LIVE_TAIL_CACHE=''
    _LIVE_FRAME_CACHE=''
    _LIVE_SIZE=''
    _LIVE_NOTE=''
    return 0
  fi
  _step_line "$1" "$2" "$3" "$4" "$CHMODX_TOTAL"
}

# Directorio temporal válido (Termux no siempre tiene /tmp)
_live_tmpdir() {
  local d
  for d in "${TMPDIR:-}" "${PREFIX:-}/tmp" "${HOME:-}/.cache" \
           "/data/data/com.termux/files/usr/tmp" "/tmp"; do
    [ -n "$d" ] || continue
    if [ -d "$d" ] && [ -w "$d" ]; then printf '%s' "$d"; return 0; fi
  done
  d="${HOME:-/tmp}/.cache"
  mkdir -p "$d" 2>/dev/null && { printf '%s' "$d"; return 0; }
  printf '/tmp'
}

# Ejecuta el comando en segundo plano con barra animada + salida en vivo
_run_step_live() {   # _run_step_live <texto> <cmd...>
  local text="${1:-}"; shift
  local rc=0 pid out t0 ticks=1 secs pct step spin size note elapsed tmpdir
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  t0=${SECONDS:-0}
  _LIVE_TAIL_N="${CHMODX_LIVE_TAIL:-3}"
  [ "$(_ui_width)" -lt 60 ] && _LIVE_TAIL_N=2

  tmpdir="$(_live_tmpdir)"
  out=$(mktemp "${tmpdir}/cx-step.XXXXXX" 2>/dev/null) || out="${tmpdir}/cx-step.$$.$RANDOM"
  if ! : >"$out" 2>/dev/null; then
    # Sin temporal: ejecuta en directo (nunca "no pasa nada")
    warn "Sin directorio temporal utilizable; salida directa"
    if "$@"; then
      CHMODX_STEPS_OK=$((CHMODX_STEPS_OK + 1))
      _step_line "$C_SUCCESS" "[ OK ]" "$text" "$(( ${SECONDS:-0} - t0 ))s" "$CHMODX_TOTAL"
      return 0
    fi
    rc=$?
    CHMODX_STEPS_ERR=$((CHMODX_STEPS_ERR + 1))
    _step_line "$C_ERR" "[ERR ]" "$text" "$(( ${SECONDS:-0} - t0 ))s" "$CHMODX_TOTAL"
    return "$rc"
  fi

  # stdin de /dev/null: evita que pkg/apt se queden esperando (SIGTTIN)
  "$@" </dev/null >>"$out" 2>&1 &
  pid=$!
  _LIVE_SIZE=''
  _LIVE_NOTE=''
  _live_block 0 "$text" "${frames:0:1}" "0s" "$out"
  while kill -0 "$pid" 2>/dev/null; do
    spin="${frames:$(( ticks % ${#frames} )):1}"
    elapsed=$(( ${SECONDS:-0} - t0 ))
    size=$(wc -c <"$out" 2>/dev/null || printf 0)
    case "$size" in ''|*[!0-9]*) size=0 ;; esac
    # Progreso = tiempo + actividad real: la salida del proceso empuja la barra
    step=$(( 90 * elapsed / (elapsed + 15) + size / 2048 ))
    [ "$step" -gt 95 ] && step=95
    pct=$step
    note=''
    if [ "$size" -lt 40 ] && [ "$elapsed" -ge 8 ]; then
      note="sin salida todavía · el proceso sigue trabajando"
    fi
    if [ "$size" = "${_LIVE_SIZE:-}" ] && [ "$note" = "${_LIVE_NOTE:-}" ]; then
      # Sin salida nueva: repinta solo la barra (la data queda quieta, sin titileo)
      _live_frame_str "$pct" "$text" "$spin" "${elapsed}s"
      if [ "$_LIVE_FRAME" != "$_LIVE_FRAME_CACHE" ]; then
        printf '\r%s\033[K' "$_LIVE_FRAME"
        _LIVE_FRAME_CACHE="$_LIVE_FRAME"
      fi
    else
      _LIVE_SIZE="$size"
      _LIVE_NOTE="$note"
      _live_block "$pct" "$text" "$spin" "${elapsed}s" "$out" "$note"
    fi
    ticks=$((ticks + 1))
    _live_pause "${CHMODX_LIVE_DELAY:-0.25}"
  done
  wait "$pid" || rc=$?
  secs=$(( ${SECONDS:-0} - t0 ))

  if [ -n "$CHMODX_LOG" ]; then cat "$out" >>"$CHMODX_LOG" 2>/dev/null || true; fi
  if [ "$rc" -eq 0 ]; then
    _live_end "$C_SUCCESS" "[ OK ]" "$text" "${secs}s"
    CHMODX_STEPS_OK=$((CHMODX_STEPS_OK + 1))
    rm -f "$out" 2>/dev/null || true
    return 0
  fi
  _live_end "$C_ERR" "[ERR ]" "$text" "${secs}s"
  CHMODX_STEPS_ERR=$((CHMODX_STEPS_ERR + 1))
  CHMODX_LAST_OUT=$(cat "$out" 2>/dev/null || true)
  printf '%s\n' "$CHMODX_LAST_OUT" | tail -n 15 | while IFS= read -r l; do printf '        %b%s%b\n' "$C_DIM" "$l" "$C_RESET"; done >&2
  rm -f "$out" 2>/dev/null || true
  return "$rc"
}

run_step() {     # run_step "<texto>" <cmd> [args...]
  local text="${1:-}"; shift
  local rc=0 t0=${SECONDS:-0} secs out=''
  [ "${CHMODX_TOTAL:-0}" -le 0 ] && CHMODX_TOTAL=1
  CHMODX_N=$((CHMODX_N + 1))
  _ui_width_refresh
  if [ "$CHMODX_DRYRUN" = 1 ]; then
    CHMODX_STEPS_OK=$((CHMODX_STEPS_OK + 1))
    _step_line "$C_DIM" "[DRY ]" "$text" "—" "$CHMODX_TOTAL"
    return 0
  fi
  # Pide sudo/doas una sola vez, antes del bloque de progreso
  if _step_needs_privs "$@"; then
    if ! chmodx_sudo_acquire; then
      CHMODX_STEPS_ERR=$((CHMODX_STEPS_ERR + 1))
      # la barra se queda donde estaba: no se instaló nada
      _step_line "$C_ERR" "[ERR ]" "$text" "—" 0
      return 1
    fi
  fi
  if [ "$CHMODX_TTY" = 1 ] && [ "$CHMODX_QUIET" != 1 ]; then printf '\n'; fi

  # Pasos que instalan: una barra por paquete (acciones animadas)
  if [ "$CHMODX_TTY" = 1 ] && [ "$CHMODX_QUIET" != 1 ] && [ "$CHMODX_VERBOSE" != 1 ] \
     && _step_uses_actions "$@"; then
    _run_step_actions "$text" "$@"
    return $?
  fi
  if [ "$CHMODX_VERBOSE" = 1 ] || [ "$CHMODX_TTY" != 1 ] || [ "$CHMODX_QUIET" = 1 ]; then
    if [ "$CHMODX_VERBOSE" = 1 ]; then
      "$@" || rc=$?
    else
      out=$("$@" 2>&1) || rc=$?
      CHMODX_LAST_OUT="$out"
      if [ -n "$CHMODX_LOG" ]; then printf '%s\n' "$out" >>"$CHMODX_LOG" 2>/dev/null || true; fi
    fi
    secs="$(( ${SECONDS:-0} - t0 ))s"
    if [ "$rc" -eq 0 ]; then
      CHMODX_STEPS_OK=$((CHMODX_STEPS_OK + 1))
      _step_line "$C_SUCCESS" "[ OK ]" "$text" "$secs" "$CHMODX_TOTAL"
      return 0
    fi
    CHMODX_STEPS_ERR=$((CHMODX_STEPS_ERR + 1))
    _step_line "$C_ERR" "[ERR ]" "$text" "$secs" "$CHMODX_TOTAL"
    if [ "$CHMODX_VERBOSE" != 1 ] && [ -n "${CHMODX_LAST_OUT:-}" ]; then
      printf '%s\n' "$CHMODX_LAST_OUT" | tail -n 15 | while IFS= read -r l; do printf '        %s\n' "$l"; done >&2
    fi
    return "$rc"
  fi
  _run_step_live "$text" "$@"
}

skip_step() {    # skip_step "<texto>"
  CHMODX_N=$((CHMODX_N + 1))
  CHMODX_STEPS_SKIP=$((CHMODX_STEPS_SKIP + 1))
  _step_line "$C_DIM" "[SKIP]" "${1:-}" "—" "$CHMODX_TOTAL"
}

chmodx_fmt_time() {
  local s="${1:-0}"
  if [ "$s" -ge 60 ]; then printf '%dm %ds' $((s / 60)) $((s % 60)); else printf '%ds' "$s"; fi
}

# Sección: limpia la pantalla, redibuja el header compacto y titula
# (en modo --quiet no limpia ni imprime cabeceras)
section() {
  [ "$CHMODX_QUIET" = 1 ] && return 0
  _ui_width_refresh
  chmodx_clear
  chmodx_banner_min
  printf '\n%b▌ %s%b\n' "$C_BOLD$C_PRIMARY" "${1:-}" "$C_RESET"
  hr
  printf '\n'
}

summary() {
  local total=$(( ${SECONDS:-0} - ${CHMODX_START:-0} ))
  echo
  hr
  printf ' %bResumen:%b %d pasos · %b%d OK%b · %b%d SKIP%b · %b%d ERR%b · %s\n' \
    "$C_BOLD" "$C_RESET" "$CHMODX_TOTAL" \
    "$C_SUCCESS" "$CHMODX_STEPS_OK" "$C_RESET" \
    "$C_DIM" "$CHMODX_STEPS_SKIP" "$C_RESET" \
    "$C_ERR" "$CHMODX_STEPS_ERR" "$C_RESET" \
    "$(chmodx_fmt_time "$total")"
  if [ "$CHMODX_TTY" = 1 ] && [ "$CHMODX_TOTAL" -gt 0 ]; then
    printf ' %b\n' "$(chmodx_bar "$CHMODX_STEPS_OK" "$CHMODX_TOTAL")"
  fi
  hr
}

# Spinner para operaciones largas:  spinner "texto" &  ...  spinner_stop
spinner() {
  [ "$CHMODX_TTY" = 1 ] || return 0
  local text="${1:-}" i=0 n ch frames='|/-\'
  n=${#frames}
  while :; do
    ch="${frames:$(( i % n )):1}"
    printf '\r  %b%s%b %s' "$C_PRIMARY" "$ch" "$C_RESET" "$text"
    i=$((i + 1))
    sleep 0.12
  done
}

spinner_stop() {
  [ "$CHMODX_TTY" = 1 ] || return 0
  printf '\r%*s\r' "$(_ui_width)" ''
}
# ============================================================
#  CHMODX Splash · lluvia en cascada + wordmark responsive
#  La lluvia se muestra por defecto; --no-matrix la desactiva.
#  (parte de lib/chmodx.sh)
# ============================================================

chmodx_splash() {
  # Se desactiva solo: sin TTY, --quiet o --no-splash
  [ "$CHMODX_TTY" = 1 ] || return 0
  [ "$CHMODX_QUIET" = 1 ] && return 0
  [ "${NO_SPLASH:-0}" = 1 ] && return 0

  chmodx_clear
  # La lluvia va primero: no hay logo ni banner antes de la animación.
  if [ "${CHMODX_MATRIX:-1}" = 1 ]; then
    chmodx_matrix_rain
    chmodx_clear
  fi
  chmodx_logo_small         # logo estático, después de la lluvia
  CHMODX_HERO=1             # avisa al banner para no repetir el logo
  echo
  sleep "${CHMODX_SPLASH_DELAY:-1.0}"
}

chmodx_matrix_rain() {      # lluvia en cascada con el color de marca
  local cols rows frames f c i ch chars n h l t
  cols=$(command -v tput >/dev/null 2>&1 && tput cols 2>/dev/null || echo 80)
  case "$cols" in ''|*[!0-9]*) cols=80 ;; esac
  if [ "$cols" -gt 110 ]; then cols=110; fi
  if [ "$cols" -lt 20 ]; then cols=20; fi
  rows=$(command -v tput >/dev/null 2>&1 && tput lines 2>/dev/null || echo 24)
  case "$rows" in ''|*[!0-9]*) rows=24 ;; esac
  if [ "$rows" -gt 28 ]; then rows=28; fi
  if [ "$rows" -lt 8 ]; then rows=8; fi

  # ASCII de ancho simple: letras pequeñas y cascada vertical.
  chars='0123456789abcdefghijklmnopqrstuvwxyz'
  n=${#chars}
  frames=18
  local -a head=() len=()
  for ((c = 0; c < cols; c += 2)); do
    head[c]=$((RANDOM % rows))
    len[c]=$((3 + RANDOM % 6))
  done

  printf '\033[?25l\033[2J\033[H'
  for ((f = 0; f < frames; f++)); do
    for ((c = 0; c < cols; c += 2)); do
      h=${head[c]}
      l=${len[c]}
      for ((t = 0; t < l; t++)); do
        i=$((h - t))
        if [ "$i" -ge 0 ] && [ "$i" -lt "$rows" ]; then
          ch="${chars:$((RANDOM % n)):1}"
          if [ "$t" -eq 0 ]; then
            printf '\033[%d;%dH%b%s%b' "$((i + 1))" "$((c + 1))" "$C_BOLD$C_PRIMARY" "$ch" "$C_RESET"
          else
            printf '\033[%d;%dH%b%s%b' "$((i + 1))" "$((c + 1))" "$C_PRIMARY" "$ch" "$C_RESET"
          fi
        fi
      done
      # Borra la cola para que la cascada no deje un rastro infinito.
      i=$((h - l))
      if [ "$i" -ge 0 ] && [ "$i" -lt "$rows" ]; then
        printf '\033[%d;%dH ' "$((i + 1))" "$((c + 1))"
      fi
      h=$((h + 1))
      if [ "$h" -ge $((rows + 4)) ]; then
        h=0
        l=$((3 + RANDOM % 6))
        len[c]=$l
      fi
      head[c]=$h
    done
    sleep 0.045
  done
  printf '\033[0m\033[2J\033[H'
}
# ============================================================
#  CHMODX-CODE Banner · logo + panel de ancho completo
#  Nombre, versión y metadatos alineados al terminal
#  (parte de lib/chmodx.sh)
# ============================================================

# Limpia pantalla solo si hay terminal (no ensucia logs/pipes)
chmodx_clear() {
  [ "$CHMODX_TTY" = 1 ] || return 0
  clear 2>/dev/null || printf '\033[2J\033[H'
}

# Ancho usable del terminal (para cajas y textos)
_ui_usable() {
  local w
  w=$(_ui_width)
  [ "$w" -gt 78 ] && w=78
  [ "$w" -lt 24 ] && w=24
  printf '%s' "$w"
}

# Longitud máxima de un texto multilínea (sin dependencias)
_maxlen() {
  local m=0 l
  while IFS= read -r l; do
    [ "${#l}" -gt "$m" ] && m="${#l}"
  done
  printf '%s' "$m"
}

# Caja de ancho completo y centrada: chmodx_box "<texto>" [color] [ancho_min]
chmodx_box() {
  local text="${1:-}" color="${2:-$C_PRIMARY}" min="${3:-30}"
  local term avail w pad left right line='' i cpad
  term=$(_ui_width)
  avail=$(( term - 2 ))
  [ "$avail" -lt "$min" ] && avail="$min"
  [ "$avail" -lt 20 ] && avail=20
  w="$avail"
  if [ "${#text}" -gt $((w - 2)) ]; then text="${text:0:$((w - 3))}…"; fi
  pad=$(( w - ${#text} - 2 ))
  left=$(( pad / 2 )); right=$(( pad - left ))
  for ((i = 0; i < w - 2; i++)); do line+='─'; done
  cpad=$(( (term - w) / 2 )); [ "$cpad" -lt 0 ] && cpad=0
  printf '%*s' "$cpad" ''
  printf "${color}╭%s╮${C_RESET}\n" "$line"
  printf '%*s' "$cpad" ''
  printf "${color}│${C_RESET}%*s%s%*s${color}│${C_RESET}\n" "$left" '' "$text" "$right" ''
  printf '%*s' "$cpad" ''
  printf "${color}╰%s╯${C_RESET}\n" "$line"
}

# Logo de marca responsive: wordmark + tagline (estático)
chmodx_logo_small() {
  local term i pad line color brand_idx tag_idx
  local -a art=()
  term=$(_ui_width)
  if [ "$term" -ge 64 ]; then
    art=(
'  ____ _   _ __  __  ___  ______  __'
' / ___| | | |  \/  |/ _ \|  _ \ \/ /'
'| |   | |_| | |\/| | | | | | | \  / '
'| |___|  _  | |  | | |_| | |_| /  \ '
' \____|_| |_|_|  |_|\___/|____/_/\_\'
''
'T E R M I N A L   I N S T A L L E R'
    )
    brand_idx=-1
    tag_idx=6
  elif [ "$term" -ge 48 ]; then
    art=(
'  ___ _  _ __  __  ___  _____  __'
' / __| || |  \/  |/ _ \|   \ \/ /'
'| (__| __ | |\/| | (_) | |) >  < '
' \___|_||_|_|  |_|\___/|___/_/\_\'
''
'T E R M I N A L   I N S T A L L E R'
    )
    brand_idx=-1
    tag_idx=5
  else
    art=(
'T E R M I N A L   I N S T A L L E R'
    )
    brand_idx=-1
    tag_idx=0
  fi
  for i in "${!art[@]}"; do
    line="${art[$i]}"
    pad=$(( (term - ${#line}) / 2 )); [ "$pad" -lt 0 ] && pad=0
    if [ "$i" = "$brand_idx" ]; then
      color="$C_BOLD$C_PRIMARY"
    elif [ "$i" = "$tag_idx" ]; then
      color="$C_DIM"
    else
      color="$C_PRIMARY"
    fi
    printf '%*s%b%s%b\n' "$pad" '' "$color" "$line" "$C_RESET"
  done
}

# Logo grande: figlet si cabe (auto-selección de fuente), si no el wordmark
chmodx_logo() {
  local w cur art font
  w=$(_ui_width)
  if chmodx_has figlet; then
    for font in small mini standard; do
      art="$(figlet -c -f "$font" -w "$w" 'CHMODX-CODE' 2>/dev/null)" || art=''
      [ -n "$art" ] || continue
      cur=$(printf '%s\n' "$art" | _maxlen)
      if [ "$cur" -le "$w" ] 2>/dev/null; then
        printf '%b%s%b\n' "$C_PRIMARY" "$art" "$C_RESET"
        return 0
      fi
    done
  fi
  chmodx_logo_small
}

# Regla horizontal de una fila del panel
_panel_rule() {   # _panel_rule <ancho> [carácter]
  local n="${1:-0}" ch="${2:-─}" out='' i
  for ((i = 0; i < n; i++)); do out+="$ch"; done
  printf '%s' "$out"
}

# Fila del banner: izquierda/derecha alineadas dentro del panel
_banner_row() {   # _banner_row <pad> <izq> <der> <interior> [color_izq] [color_der]
  local pad="${1:-0}" left="${2:-}" right="${3:-}" inner="${4:-0}"
  local lc="${5:-$C_BOLD}" rc="${6:-$C_BOLD}"
  local gap text l r
  if [ $(( ${#left} + ${#right} + 2 )) -le "$inner" ]; then
    gap=$(( inner - ${#left} - ${#right} - 2 ))
    printf '%*s%b│%b %b%s%b%*s%b%s%b %b│%b\n' \
      "$pad" '' "$C_PRIMARY" "$C_RESET" \
      "$lc" "$left" "$C_RESET" "$gap" '' \
      "$rc" "$right" "$C_RESET" "$C_PRIMARY" "$C_RESET"
  else
    text="$left"
    [ -n "$right" ] && text="$left · $right"
    [ "${#text}" -gt $(( inner - 2 )) ] && text="${text:0:$((inner - 3))}…"
    l=$(( (inner - ${#text}) / 2 )); r=$(( inner - ${#text} - l ))
    printf '%*s%b│%b%*s%b%s%b%*s%b│%b\n' \
      "$pad" '' "$C_PRIMARY" "$C_RESET" "$l" '' \
      "$lc" "$text" "$C_RESET" "$r" '' "$C_PRIMARY" "$C_RESET"
  fi
}

# Banner completo: logo (si el splash no lo puso ya) + panel de ancho completo
chmodx_banner() {   # chmodx_banner [nombre] [versión]
  [ "$CHMODX_QUIET" = 1 ] && return 0     # en --quiet no se dibuja banner
  local name="${1:-${CHMODX_NAME:-INSTALADOR}}"
  local ver="${2:-${CHMODX_VERSION:-1.0.0}}"
  local term w inner pad rule env meta left right
  if [ "${CHMODX_HERO:-0}" = 1 ]; then
    :                          # el splash ya dibujó el logo: no se repite
  else
    chmodx_clear
    chmodx_logo
    echo
  fi
  term=$(_ui_width)
  w=$(( term - 2 )); [ "$w" -lt 30 ] && w=30
  inner=$(( w - 2 ))
  pad=$(( (term - w) / 2 )); [ "$pad" -lt 0 ] && pad=0
  rule=$(_panel_rule "$inner" '─')
  env="$(chmodx_env_label)"
  left='CHMODX-CODE'
  right="$name · v$ver"
  printf '%*s%b╭%s╮%b\n' "$pad" '' "$C_PRIMARY" "$rule" "$C_RESET"
  _banner_row "$pad" "$left" "$right" "$inner" "$C_BOLD$C_PRIMARY" "$C_BOLD"
  printf '%*s%b├%s┤%b\n' "$pad" '' "$C_DARK" "$rule" "$C_RESET"
  meta="$env  ·  ${CHMODX_PM:-?}"
  right='Powered by CHMODX'
  if [ $(( ${#meta} + ${#right} + 4 )) -le "$inner" ]; then
    _banner_row "$pad" "$meta" "$right" "$inner" "$C_DIM" "$C_DIM"
  else
    _banner_row "$pad" "$meta" '' "$inner" "$C_DIM" "$C_DIM"
  fi
  printf '%*s%b╰%s╯%b\n' "$pad" '' "$C_PRIMARY" "$rule" "$C_RESET"
  echo
}

# Banner compacto para menús y secciones (una línea + regla, truncado al ancho)
chmodx_banner_min() {
  local name="${CHMODX_NAME:-INSTALADOR}" ver="${CHMODX_VERSION:-1.0.0}"
  local head='CHMODX-CODE  │  ' room mid tail t=''
  local env; env="$(chmodx_env_label)"
  mid="${name} v${ver}"
  tail="   · ${env} · ${CHMODX_PM:-?}"
  room=$(( $(_ui_width) - 1 - ${#head} ))
  if [ "$(( ${#mid} + ${#tail} ))" -le "$room" ]; then
    t="$tail"
  elif [ "${#mid}" -gt "$room" ]; then
    mid="${mid:0:$((room-1))}…"
  fi
  printf '%bCHMODX-CODE%b  %b│%b  %b%s%b%b%s%b\n' \
    "$C_BOLD$C_PRIMARY" "$C_RESET" "$C_DARK" "$C_RESET" \
    "$C_BOLD" "$mid" "$C_RESET" "$C_DIM" "$t" "$C_RESET"
  hr
}
# ============================================================
#  CHMODX Menu · menú interactivo (whiptail → dialog → read)
#  (parte de lib/chmodx.sh)
# ============================================================

# Pausa legible: deja ver el resultado antes de limpiar la pantalla.
# Se salta con --yes, --quiet, sin TTY o --no-pause.
chmodx_pause() {   # chmodx_pause ["motivo"]
  [ "${CHMODX_TTY:-0}" = 1 ] || return 0
  [ "${CHMODX_YES:-0}" = 1 ] && return 0
  [ "${CHMODX_QUIET:-0}" = 1 ] && return 0
  [ "${CHMODX_NO_PAUSE:-0}" = 1 ] && return 0
  local msg="${1:-Revisa la salida}"
  printf '\n  %b%s%b\n  %bPulsa [Enter] para continuar…%b\n' \
    "$C_BOLD" "$msg" "$C_RESET" "$C_DIM" "$C_RESET" >&2
  if [ -r /dev/tty ]; then
    IFS= read -r _ </dev/tty || true
  else
    IFS= read -r _ || true
  fi
}

# ¿Mostrar el menú? Por defecto SÍ en TTY; --no-menu o --yes lo saltan
chmodx_menu_enabled() {
  [ "${CHMODX_NO_MENU:-0}" = 1 ] && return 1
  [ "${CHMODX_FORCE_MENU:-0}" = 1 ] && return 0
  [ "${CHMODX_TTY:-0}" = 1 ] && [ "${CHMODX_YES:-0}" != 1 ] && [ "${CHMODX_QUIET:-0}" != 1 ]
}

chmodx_confirm() {   # chmodx_confirm "<pregunta>"  → 0 = sí / 1 = no
  local q="${1:-¿Continuar?}"
  if [ "$CHMODX_YES" = 1 ] || [ "$CHMODX_DRYRUN" = 1 ]; then
    return 0
  fi
  if chmodx_has whiptail; then
    whiptail --title "CHMODX · ${CHMODX_NAME:-Instalador}" --yesno "$q" 0 0 3>&1 1>&2 2>&3
    return $?
  fi
  local a=''
  printf '%s %b[s/N]%b ' "$q" "$C_GRAY" "$C_RESET"
  if [ -r /dev/tty ]; then read -r a </dev/tty; else read -r a || a=''; fi
  case "$a" in s|S|y|Y|si|sí|SI) return 0 ;; *) return 1 ;; esac
}

# chmodx_menu "<mensaje>" "tag" "Etiqueta · descripción" ...
# Escribe el tag elegido en stdout y devuelve 0; 1 si se cancela.
chmodx_menu() {
  local msg="${1:-Selecciona una opción}"; shift

  if chmodx_has whiptail; then
    whiptail --title "CHMODX · ${CHMODX_NAME:-Instalador}" \
             --cancel-button "Salir" --menu "$msg" 0 0 0 "$@" 3>&1 1>&2 2>&3
    return $?
  fi

  local -a tags=() items=()
  while [ $# -ge 1 ]; do
    tags+=("${1:-}"); shift
    if [ $# -ge 1 ]; then items+=("$1"); shift; else items+=(""); fi
  done

  local i choice='' t iw label
  iw=$(( $(_ui_width) - 6 ))
  printf '\n' >&2
  for i in "${!tags[@]}"; do
    label="${items[$i]}"
    if [ "${#label}" -gt "$iw" ]; then label="${label:0:$((iw-1))}…"; fi
    printf '  %b[%s]%b %s\n' "$C_PRIMARY" "${tags[$i]}" "$C_RESET" "$label" >&2
  done
  printf '\n  %bSelecciona una opción (q = salir):%b ' "$C_GRAY" "$C_RESET" >&2
  if [ -r /dev/tty ]; then read -r choice </dev/tty; else read -r choice || choice=''; fi
  case "$choice" in q|Q|'') return 1 ;; esac
  for t in "${tags[@]}"; do
    if [ "$t" = "$choice" ]; then printf '%s\n' "$t"; return 0; fi
  done
  return 1
}
# ============================================================
#  CHMODX Outro · cierre del instalador + invitación al curso
#  (parte de lib/chmodx.sh)
# ============================================================

# Abre una URL en el navegador del sistema (Termux, proot, Linux, WSL, macOS)
# Devuelve 0 solo si un lanzador respondió bien de verdad.
_chmodx_open_try() {   # [--strict] <cmd...>
  local strict=0 out rc
  [ "${1:-}" = "--strict" ] && { strict=1; shift; }
  out="$("$@" 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] || return 1
  case "$out" in
    *"cannot open display"*|*"no method available"*) return 1 ;;
  esac
  if [ "$strict" = 1 ]; then
    case "$out" in
      *"Error"*|*"error"*|*"Exception"*|*"Failure"*|*"failed"*|*"does not exist"*) return 1 ;;
    esac
  fi
  return 0
}

chmodx_open_url() {   # chmodx_open_url <url>  → 0 si se lanzó el navegador
  local url="${1:-}" t tp tpath
  [ -n "$url" ] || return 1

  # Prefijo de Termux: en proot-distro suele estar montado en su ruta original.
  tp="${CHMODX_TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
  tpath="$tp/bin:/system/bin:/system/xbin:$PATH"

  # 1) Termux: termux-open-url / termux-open (con su bin y am en el PATH)
  for t in "$tp/bin/termux-open-url" "$tp/bin/termux-open" \
           termux-open-url termux-open; do
    if chmodx_has "$t" || [ -x "$t" ]; then
      PATH="$tpath" _chmodx_open_try "$t" "$url" && return 0
    fi
  done

  # 2) Android am (el de Termux primero; luego /system/bin/am)
  for t in "$tp/bin/am" /system/bin/am am; do
    if chmodx_has "$t" || [ -x "$t" ]; then
      PATH="$tpath" _chmodx_open_try --strict "$t" start --user 0 \
        -a android.intent.action.VIEW -d "$url" && return 0
    fi
  done
  if [ -x /system/bin/cmd ]; then
    PATH="$tpath" _chmodx_open_try --strict /system/bin/cmd activity start \
      --user 0 -a android.intent.action.VIEW -d "$url" && return 0
  fi

  # 3) WSL
  chmodx_has wslview && _chmodx_open_try wslview "$url" && return 0
  chmodx_has cmd.exe && _chmodx_open_try --strict cmd.exe /c start "" "$url" && return 0

  # 4) macOS
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ] && chmodx_has open; then
    _chmodx_open_try open "$url" && return 0
  fi

  # 5) Linux de escritorio (solo con servidor gráfico real)
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    chmodx_has xdg-open && _chmodx_open_try xdg-open "$url" && return 0
    chmodx_has gio && _chmodx_open_try gio open "$url" && return 0
    if chmodx_has sensible-browser; then
      local out rc
      out="$(timeout 6 sensible-browser "$url" 2>&1)"; rc=$?
      if [ "$rc" -eq 0 ] || [ "$rc" -eq 124 ]; then
        case "$out" in *"cannot open display"*|*"no method available"*) : ;; *) return 0 ;; esac
      fi
    fi
  fi

  # 6) Navegador elegido por el usuario
  if [ -n "${BROWSER:-}" ] && chmodx_has "${BROWSER%% *}"; then
    ${BROWSER} "$url" >/dev/null 2>&1 &
    return 0
  fi
  return 1
}

# Módulos del curso (19), en una o dos columnas según el ancho
_outro_modules() {
  local cols="${1:-80}" i half n=19 w
  local -a m=(
    "Presentación y bienvenida"
    "Primeros pasos"
    "Operadores y expresiones"
    "Controlando el flujo"
    "Colecciones"
    "Scripts"
    "Funciones"
    "Errores y excepciones"
    "POO (orientada a objetos)"
    "Herencia"
    "Métodos de colección"
    "Módulos y paquetes"
    "Ficheros"
    "Interfaces gráficas"
    "App con interfaces gráficas"
    "Bases de datos SQLite"
    "Funciones avanzadas"
    "Bonus · Docs y pruebas"
    "Bonus · App de escritorio"
  )
  if [ "$cols" -ge 60 ]; then
    w=24; [ "$cols" -ge 72 ] && w=30
    half=$(( (n + 1) / 2 ))
    for ((i = 0; i < half; i++)); do
      local l="${m[$i]}" r="${m[$((i + half))]:-}"
      if [ -n "$r" ]; then
        printf '   %b%02d%b %-*.*s   %b%02d%b %-*.*s\n' \
          "$C_PRIMARY" $((i + 1)) "$C_RESET" "$w" "$w" "$l" \
          "$C_PRIMARY" $((i + half + 1)) "$C_RESET" "$w" "$w" "$r"
      else
        printf '   %b%02d%b %s\n' "$C_PRIMARY" $((i + 1)) "$C_RESET" "$l"
      fi
    done
  else
    for ((i = 0; i < n; i++)); do
      printf '   %b%02d%b %s\n' "$C_PRIMARY" $((i + 1)) "$C_RESET" "${m[$i]}"
    done
  fi
}

# Ajusta un párrafo al ancho sin cortar palabras
_outro_wrap() {   # _outro_wrap <ancho> <texto...>
  local w="${1:-72}" text line='' word
  shift
  text="$*"
  for word in $text; do
    if [ -z "$line" ]; then
      line="$word"
    elif [ $(( ${#line} + 1 + ${#word} )) -le "$w" ]; then
      line="$line $word"
    else
      printf '  %s\n' "$line"
      line="$word"
    fi
  done
  [ -n "$line" ] && printf '  %s\n' "$line"
}

# Copia texto al portapapeles: Termux API, X11/Wayland o OSC 52
chmodx_clipboard_set() {   # chmodx_clipboard_set <texto>
  local text="${1:-}" tp t b64
  [ -n "$text" ] || return 1
  tp="${CHMODX_TERMUX_PREFIX:-/data/data/com.termux/files/usr}"

  for t in termux-clipboard-set "$tp/bin/termux-clipboard-set"; do
    if chmodx_has "$t" || [ -x "$t" ]; then
      PATH="$tp/bin:$PATH" "$t" "$text" >/dev/null 2>&1 && return 0
    fi
  done
  if [ -n "${DISPLAY:-}" ]; then
    if chmodx_has xclip; then
      printf '%s' "$text" | xclip -selection clipboard >/dev/null 2>&1 && return 0
    fi
    if chmodx_has xsel; then
      printf '%s' "$text" | xsel --clipboard --input >/dev/null 2>&1 && return 0
    fi
  fi
  if [ -n "${WAYLAND_DISPLAY:-}" ] && chmodx_has wl-copy; then
    printf '%s' "$text" | wl-copy >/dev/null 2>&1 && return 0
  fi
  if chmodx_has pbcopy; then
    printf '%s' "$text" | pbcopy >/dev/null 2>&1 && return 0
  fi

  # OSC 52: lo soportan Termux y la mayoría de terminales modernos
  if chmodx_has base64; then
    b64="$(printf '%s' "$text" | base64 | tr -d '\n')"
  elif chmodx_has openssl; then
    b64="$(printf '%s' "$text" | openssl base64 -A)"
  fi
  if [ -n "${b64:-}" ] && [ -w /dev/tty ]; then
    printf '\033]52;c;%s\a' "$b64" >/dev/tty 2>/dev/null && return 0
  fi
  return 1
}

# Pantalla final: copy AIDA + los 19 módulos + Ir / Terminar
chmodx_outro() {
  [ "${CHMODX_NO_PROMO:-0}" = 1 ] && return 0
  local url="https://chmodxcode.pro" cols sel
  _ui_width >/dev/null 2>&1
  cols=${_UI_W:-80}

  # Sin interacción (--yes, sin TTY o --quiet): CTA de una línea y fuera
  if [ "${CHMODX_TTY:-0}" != 1 ] || [ "${CHMODX_YES:-0}" = 1 ] \
     || [ "${CHMODX_QUIET:-0}" = 1 ]; then
    [ "${CHMODX_QUIET:-0}" = 1 ] && return 0
    printf '  %bAprende Python de 0 a master:%b %s\n' "$C_BOLD" "$C_RESET" "$url"
    return 0
  fi

  section "Tu siguiente paso"

  local w=$(( cols - 4 )); [ "$w" -lt 20 ] && w=20
  printf '  %b¿Y ahora qué?%b\n\n' "$C_BOLD" "$C_RESET"
  _outro_wrap "$w" "Ver tutoriales sueltos frustra: avanzas sin rumbo y copias código sin entenderlo. Aquí tienes una ruta clara."
  echo
  _outro_wrap "$w" "PYTHON 3 DE 0 A MASTER · 19 módulos, de cero a tus propios programas, con código en cada clase."
  _outro_wrap "$w" "+38.000 alumnos ya confiaron en Brian De Vita. Sin experiencia previa: solo tu compu y ganas."
  echo

  printf '  %b▌ Módulos%b\n' "$C_BOLD$C_PRIMARY" "$C_RESET"
  _outro_modules "$cols"
  echo

  sel="$(chmodx_menu "¿Qué quieres hacer ahora?" \
    "1" "Ir · abrir chmodxcode.pro en el navegador" \
    "2" "Terminar · salir")" || sel=2

  if [ "$sel" = 1 ]; then
    local copied=0
    chmodx_clipboard_set "$url" && copied=1
    if chmodx_open_url "$url"; then
      printf '\n  %bAbriendo chmodxcode.pro…%b\n' "$C_BOLD" "$C_RESET"
      printf '  %bEnlace:%b %s\n' "$C_DIM" "$C_RESET" "$url"
    else
      printf '\n  %bAbre el curso en tu navegador:%b\n    %b%s%b\n' \
        "$C_BOLD" "$C_RESET" "$C_BOLD" "$url" "$C_RESET"
      if [ "$copied" = 1 ]; then
        printf '  %bEnlace copiado al portapapeles.%b\n' "$C_DIM" "$C_RESET"
        printf '  Pégalo en la barra de direcciones de tu navegador.\n'
      else
        printf '  %bMantén pulsado el enlace para copiarlo.%b\n' "$C_DIM" "$C_RESET"
      fi
    fi
    printf '\n  %b¡Nos vemos en el curso!%b\n' "$C_SUCCESS" "$C_RESET"
    printf '  %bPowered by CHMODX%b\n' "$C_GRAY" "$C_RESET"
    exit 0
  fi

  printf '\n  %bGracias por confiar en CHMODX.%b\n' "$C_BOLD" "$C_RESET"
  printf '  Todo lo que imaginas lo puedes crear.\n\n'
  printf '  %bAprende Python de 0 a master:%b\n    %s\n' \
    "$C_BOLD" "$C_RESET" "$url"
  printf '\n  %bPowered by CHMODX%b\n' "$C_GRAY" "$C_RESET"
  exit 0
}
