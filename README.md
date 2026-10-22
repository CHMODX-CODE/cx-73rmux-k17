<div align="center">

# Termux Kit

### Tu arsenal de terminal, organizado por categorías

Un instalador para Termux que reúne desarrollo, redes, seguridad, multimedia, IA y escritorio en un solo menú. Elige las categorías que necesitas y deja que el kit prepare el resto.

![Shell](https://img.shields.io/badge/Shell-Bash-018582?logo=gnubash&logoColor=white&style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Termux-018582?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-018582?style=flat-square)
![Creado por CHMODX-CODE](https://img.shields.io/badge/Creado%20por-CHMODX--CODE-018582?style=flat-square)

</div>

---

## ¿Qué hace?

Termux Kit convierte una instalación de Termux en un entorno de trabajo completo, sin tener que recordar ni escribir decenas de comandos `pkg install`. El instalador ofrece una base lista para usar y **14 categorías opcionales** para que elijas solo lo que necesitas.

Al terminar, tendrás disponibles las herramientas de las categorías seleccionadas: editores, compiladores, lenguajes, clientes SSH, utilidades de red, herramientas de seguridad, procesamiento de audio y vídeo, bases de datos, aplicaciones gráficas y mucho más.

## ¿Para qué sirve?

- **Preparar Termux para desarrollar**: compiladores, Git, Python, Node.js, Rust, Go, Java y utilidades de terminal.
- **Administrar servidores y redes**: SSH, transferencia de archivos, diagnóstico DNS, túneles y monitorización.
- **Aprender seguridad y reversing**: escaneo, análisis de binarios, inspección de APK y herramientas de criptografía.
- **Trabajar con audio, vídeo, imágenes y documentos**: conversión, edición, metadatos y generación de contenido.
- **Montar servicios locales**: SQLite, PostgreSQL, MariaDB, Redis, nginx, Apache o Lighttpd.
- **Usar IA y ciencia de datos**: NumPy, SciPy, PyTorch, Ollama, modelos locales y OCR.
- **Abrir un escritorio gráfico**: XFCE, VNC y aplicaciones como Firefox, LibreOffice o GIMP.
- **Personalizar y disfrutar la terminal**: prompts, gestores de archivos, juegos retro y utilidades ASCII.

## Lo que incluye

- **Instalación guiada en español**: menú claro, submenú de categorías y confirmaciones.
- **Tú eliges qué instalar**: base + 14 categorías; no tienes que instalar todo de golpe.
- **Instalación por categoría o por paquete**, omitiendo lo que ya está instalado.
- **Progreso visible por paquete**, con estado y tiempo de cada operación.
- **Plan y verificación final**: ves lo que se instalará y lo que quedó correctamente instalado.
- **Diagnóstico previo** para detectar problemas de entorno, permisos o conectividad.
- **Desinstalación segura desde el menú**: elimina lo añadido por el kit y conserva las dependencias esenciales de Termux.
- **Compatible con Termux, proot-distro y Linux** con gestor de paquetes.
- **Modo simulación** (`--dry-run`), logs y opciones para automatización.


## Comandos disponibles

El kit no instala un único comando: deja disponibles las herramientas de las categorías que elijas. Estos son los comandos más representativos:

| Área | Comandos | Para qué sirven |
|---|---|---|
| Base | `git`, `curl`, `wget`, `python`, `node`, `nano`, `htop`, `figlet` | Control de versiones, descargas, scripting, edición y monitorización. |
| Terminal | `zsh`, `fish`, `tmux`, `screen`, `zellij`, `fzf`, `zoxide`, `eza`, `bat`, `rg`, `fd`, `lazygit`, `gh`, `starship`, `jq`, `yq` | Shells, multiplexores, búsqueda, navegación y productividad. |
| Desarrollo | `clang`, `make`, `cmake`, `ninja`, `gdb`, `rustc`, `cargo`, `go`, `php`, `composer`, `ruby`, `lua`, `java`, `gradle`, `sqlite3` | Compilar, depurar y ejecutar proyectos en varios lenguajes. |
| Python / IA | `python`, `pip`, `ollama`, `llama-cli`, `tesseract` | Ciencia de datos, modelos locales y OCR. |
| Redes y descargas | `ssh`, `scp`, `mosh`, `rsync`, `aria2c`, `rclone`, `curl`, `wget`, `nmap`, `nc`, `socat`, `http`, `xh`, `transmission-cli`, `rtorrent` | Conexiones remotas, descargas, diagnóstico y transferencia. |
| Seguridad / RE | `nmap`, `radare2`, `rizin`, `binwalk`, `apktool`, `jadx`, `xxd`, `hexyl`, `openssl`, `gpg`, `age`, `pass` | Auditoría, reversing, análisis de archivos y gestión de secretos. |
| Multimedia | `ffmpeg`, `ffprobe`, `magick`, `gm`, `sox`, `lame`, `flac`, `opusenc`, `oggenc`, `mediainfo`, `mpv`, `mpd`, `ncmpcpp`, `cmus`, `cava`, `pdftoppm`, `qpdf`, `gs`, `pandoc`, `chafa`, `timg`, `vlc` | Convertir, reproducir, analizar y documentar audio, vídeo, imágenes y PDF. |
| Bases de datos / web | `sqlite3`, `psql`, `mysql`, `redis-server`, `redis-cli`, `nginx`, `apachectl`, `lighttpd`, `php`, `php-fpm` | Motores de datos y servidores web locales. |
| Editores | `nano`, `vim`, `nvim`, `emacs`, `micro`, `hx`, `ranger`, `nnn`, `mc`, `lazygit`, `gitui` | Edición de código, navegación de archivos y Git visual. |
| Comunicación | `irssi`, `weechat`, `profanity`, `mutt`, `neomutt`, `alpine`, `newsboat`, `znc`, `task`, `calcurse`, `pandoc` | Chat, correo, RSS, tareas y documentos. |
| Juegos / Fun | `nethack`, `angband`, `crawl`, `bastet`, `ninvaders`, `pacman4console`, `moon-buggy`, `nsnake`, `nudoku`, `tty-solitaire`, `cmatrix`, `cbonsai`, `sl`, `cowsay`, `fortune`, `figlet`, `toilet`, `neofetch`, `fastfetch`, `hollywood` | Entretenimiento, arte ASCII e información del sistema. |
| Escritorio X11 | `startxfce4`, `xfce4-terminal`, `thunar`, `openbox`, `fluxbox`, `i3`, `awesome`, `vncserver`, `x11vnc`, `pulseaudio`, `pavucontrol`, `pcmanfm`, `geany`, `mousepad`, `xclip`, `xdotool`, `scrot`, `feh` | Entorno gráfico, VNC y utilidades de escritorio. |
| Apps gráficas | `firefox`, `chromium`, `code-oss`, `libreoffice`, `gimp`, `inkscape`, `krita`, `qemu-system-x86_64`, `mkvmerge`, `chocolate-doom` | Navegación, ofimática, diseño, virtualización y juegos. |
| TUR avanzado | `mongod`, `hashcat`, `ettercap`, `dsniff` | MongoDB, auditoría de contraseñas y análisis de tráfico. |

> No todos los paquetes exponen un comando propio: algunos son librerías, servicios o complementos. El catálogo completo está en la siguiente sección.

## Paquetes disponibles en Termux

El kit incluye **8 paquetes base** y **14 categorías opcionales** con más de 290 paquetes. La disponibilidad exacta puede variar según la versión de Termux, los repositorios habilitados y la arquitectura del dispositivo.

### Paquetes base

| Paquete | Para qué sirve |
|---|---|
| `git` | Control de versiones distribuido. |
| `curl` | Descargas y peticiones HTTP/HTTPS. |
| `wget` | Descargas HTTP/FTP con reanudación. |
| `python` | Intérprete de Python. |
| `node` | Runtime de JavaScript/TypeScript. |
| `nano` | Editor de texto sencillo en terminal. |
| `htop` | Monitor interactivo de procesos y recursos. |
| `figlet` | Texto grande en ASCII para banners y scripts. |

### Catálogo por categorías

Cada categoría se instala por separado. Los paquetes repetidos entre categorías se muestran una vez por categoría para que sepas qué aporta cada una.

<details>
<summary><strong>Esencial Pro</strong> · Base del sistema y utilidades imprescindibles · 30 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `coreutils` | Utilidades UNIX básicas: `ls`, `cp`, `mv`, `rm`, `cat`, `chmod`, `sort`, etc. |
| `findutils`, `grep`, `sed`, `gawk` | Búsqueda de archivos, filtrado, edición y procesamiento de texto. |
| `tar`, `gzip`, `bzip2`, `xz-utils`, `zstd`, `unzip`, `zip`, `7zip`, `unrar` | Crear, extraer y comprimir archivos en los formatos más habituales. |
| `less`, `mandoc` | Lectura paginada de archivos y consulta de manuales (`man`). |
| `file`, `which`, `procps`, `psmisc`, `util-linux`, `diffutils`, `patch` | Inspección de archivos, procesos, discos, diferencias y parches del sistema. |
| `rsync` | Sincronización y copia incremental de archivos local o remota. |
| `ncurses-utils` | Utilidades de terminal basadas en ncurses (`tput`, `clear`, `reset`). |
| `termux-tools`, `termux-api`, `termux-am`, `termux-exec`, `termux-keyring` | Integración esencial con Android/Termux: APIs, lanzadores, ejecución y llavero de repositorios. |

</details>

<details>
<summary><strong>Terminal Hacker</strong> · Shells, productividad y herramientas modernas de terminal · 43 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `zsh`, `fish` | Shells interactivas con autocompletado y resaltado. |
| `tmux`, `screen`, `zellij` | Multiplexores de terminal: varias sesiones y paneles en una sola ventana. |
| `fzf` | Buscador difuso para archivos, historial y listas. |
| `zoxide` | Navegación rápida entre directorios aprendiendo de tu uso. |
| `eza`, `lsd` | Listado de archivos moderno con iconos, colores y metadatos. |
| `bat` | Visor de archivos con resaltado de sintaxis y números de línea. |
| `ripgrep`, `fd`, `silversearcher-ag` | Búsqueda rápida de texto (`rg`) y de archivos (`fd`, `ag`). |
| `git-delta`, `lazygit`, `tig`, `gitui`, `onefetch` | Diffs legibles, interfaces TUI para Git y resumen visual del repositorio. |
| `gh`, `glab-cli` | Clientes de GitHub (`gh`) y GitLab (`glab`) desde la terminal. |
| `starship` | Prompt minimalista y rápido para cualquier shell. |
| `tree`, `ncdu`, `duf`, `dust` | Explorar árboles de directorios y analizar el uso de disco. |
| `htop`, `procs` | Monitorizar procesos y recursos del sistema. |
| `parallel`, `entr` | Ejecutar tareas en paralelo o al cambiar archivos. |
| `glow`, `mdcat` | Renderizar Markdown en la terminal. |
| `sd` | Sustituto simple y seguro de `sed` para reemplazos. |
| `hyperfine`, `tokei` | Medir rendimiento de comandos y contar líneas de código. |
| `jq`, `yq`, `gojq`, `pup`, `xmlstarlet` | Consultar y transformar JSON, YAML, HTML y XML. |
| `shellcheck`, `shfmt` | Analizar y formatear scripts de shell. |
| `bash-completion`, `zsh-completions` | Autocompletado para Bash y Zsh. |

</details>

<details>
<summary><strong>Desarrollo</strong> · Compiladores, lenguajes y herramientas de build · 59 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `clang`, `lld`, `lldb`, `llvm`, `llvm-tools` | Toolchain de C/C++ basada en LLVM: compilador, enlazador, depurador y utilidades. |
| `make`, `cmake`, `ninja`, `pkg-config`, `binutils`, `autoconf`, `automake`, `libtool`, `flex`, `bison`, `gettext` | Sistemas de build, enlazadores, generadores de configuración y análisis léxico/sintáctico. |
| `gdb`, `strace`, `ltrace`, `patchelf` | Depuración de binarios, trazas de syscalls/librerías y modificación de ELF. |
| `rust`, `rust-analyzer` | Compilador de Rust y servidor de lenguaje para editores. |
| `golang` | Compilador y toolchain de Go. |
| `nodejs-lts`, `yarn`, `pnpm`, `deno`, `bun` | Runtimes y gestores de paquetes para JavaScript/TypeScript. |
| `python`, `python-pip` | Intérprete de Python y gestor de paquetes `pip`. |
| `ruby` | Intérprete y ecosistema de Ruby. |
| `php`, `php-fpm`, `composer` | PHP, gestor de procesos FastCGI y gestor de dependencias Composer. |
| `perl` | Intérprete y ecosistema de Perl. |
| `lua54`, `luarocks` | Intérprete de Lua 5.4 y gestor de módulos. |
| `tcl` | Intérprete del lenguaje Tcl. |
| `openjdk-17`, `gradle`, `maven`, `ant`, `scala` | Java 17, sistemas de build JVM y lenguaje Scala. |
| `elixir`, `erlang` | Lenguaje Elixir y máquina virtual Erlang/BEAM. |
| `ghc` | Compilador de Haskell. |
| `zig`, `nim`, `crystal`, `dart`, `kotlin` | Compiladores y runtimes de lenguajes modernos. |
| `racket`, `guile`, `sbcl`, `chicken` | Implementaciones de Scheme, Lisp y Common Lisp. |
| `git`, `subversion`, `git-lfs` | Control de versiones Git, Subversion y soporte para archivos grandes. |
| `sqlite` | Base de datos SQLite y su cliente de línea de comandos. |

</details>

<details>
<summary><strong>Python / IA</strong> · Ciencia de datos, machine learning y visión · 11 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `python-pip` | Gestor de paquetes de Python. |
| `python-numpy`, `python-scipy`, `matplotlib` | Cálculo numérico, álgebra, estadística y gráficas. |
| `python-torch`, `onnxruntime`, `fftw`, `libopenblas` | Deep learning, inferencia ONNX, transformadas FFT y álgebra lineal optimizada. |
| `ollama`, `llama-cpp` | Ejecutar modelos de lenguaje locales desde la terminal. |
| `tesseract` | Reconocimiento óptico de caracteres (OCR). |

</details>

<details>
<summary><strong>Redes y descargas</strong> · SSH, transferencia, diagnóstico y respaldo · 27 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `curl`, `wget`, `aria2`, `rclone` | Descargas HTTP/FTP, descargas aceleradas y sincronización con la nube. |
| `openssh`, `sshpass`, `mosh`, `autossh` | Conexiones SSH, automatización, roaming y reconexión persistente. |
| `inetutils`, `dnsutils`, `whois`, `traceroute` | Diagnóstico de red, DNS, dominios y rutas. |
| `nmap`, `netcat-openbsd`, `socat` | Escaneo de puertos, conexiones TCP/UDP y transferencia entre descriptores. |
| `speedtest-go` | Medir velocidad de conexión desde la terminal. |
| `transmission`, `rtorrent` | Clientes de descarga BitTorrent. |
| `httpie`, `xh`, `websocat` | Clientes HTTP/HTTPS y WebSocket legibles. |
| `restic`, `borgbackup` | Copias de seguridad cifradas e incrementales. |
| `syncthing`, `croc` | Sincronización continua y transferencia segura de archivos. |
| `rsync` | Sincronización eficiente de archivos locales o remotos. |
| `termux-api` | Acceso a APIs de Android desde scripts de Termux. |

</details>

<details>
<summary><strong>Seguridad / RE</strong> · Auditoría, reversing y criptografía · 14 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `nmap`, `netcat-openbsd`, `socat` | Reconocimiento de red, conexiones y túneles. |
| `radare2`, `rizin` | Análisis, desensamblado y reversing de binarios. |
| `binwalk`, `apktool`, `jadx` | Inspección de firmware, descompilación de APK y lectura de código Android. |
| `xxd`, `hexyl` | Visores hexadecimales para analizar archivos y binarios. |
| `openssl`, `gnupg`, `age`, `pass` | Cifrado, firmas, gestión de claves y contraseñas. |

</details>

<details>
<summary><strong>Multimedia</strong> · Audio, vídeo, imágenes y documentos · 33 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `ffmpeg`, `ffmpegthumbnailer` | Convertir, recortar, comprimir y generar miniaturas de audio/vídeo. |
| `imagemagick`, `graphicsmagick` | Edición, conversión y procesamiento por lotes de imágenes. |
| `sox`, `lame`, `flac`, `opus-tools`, `vorbis-tools`, `wavpack` | Procesar audio y codificar/decodificar MP3, FLAC, Opus, Vorbis y WavPack. |
| `mediainfo`, `atomicparsley` | Leer metadatos multimedia y editar etiquetas de MP4/M4A. |
| `mpv`, `mpd`, `ncmpcpp`, `cmus`, `cava` | Reproducción de audio/vídeo, servidor musical y visualizador. |
| `gifsicle`, `optipng`, `jpegoptim`, `pngquant`, `libwebp` | Optimizar GIF, PNG, JPEG y WebP. |
| `exiftool` | Leer y editar metadatos EXIF de fotos y vídeos. |
| `poppler`, `qpdf`, `ghostscript` | Leer, transformar, reparar y comprimir PDF/PostScript. |
| `pandoc`, `groff` | Convertir documentos entre Markdown, HTML, PDF, EPUB y otros formatos. |
| `chafa`, `timg`, `jp2a` | Ver imágenes y vídeos dentro de la terminal. |
| `vlc` | Reproductor multimedia completo. |
| `tesseract` | OCR para extraer texto de imágenes. |

</details>

<details>
<summary><strong>Bases de datos</strong> · Motores SQL/NoSQL y servidores web · 10 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `sqlite`, `postgresql`, `mariadb`, `redis` | Bases de datos SQLite, PostgreSQL, MariaDB y Redis. |
| `nginx`, `apache2`, `lighttpd` | Servidores web ligeros y proxies inversos. |
| `php`, `php-fpm`, `composer` | Stack PHP para aplicaciones y gestor de dependencias. |

</details>

<details>
<summary><strong>Editores / IDE</strong> · Editores de texto, IDE y gestores de archivos · 11 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `nano`, `vim`, `neovim`, `emacs`, `micro`, `helix` | Editores de texto para principiantes y usuarios avanzados. |
| `ranger`, `nnn`, `mc` | Gestores de archivos en terminal con navegación tipo TUI. |
| `lazygit`, `gitui` | Interfaces visuales para revisar, commitear y gestionar Git. |

</details>

<details>
<summary><strong>Comunicación</strong> · Chat, correo, RSS y organización personal · 15 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `irssi`, `weechat`, `profanity` | Clientes de IRC y XMPP. |
| `mutt`, `neomutt`, `alpine` | Clientes de correo en terminal. |
| `newsboat` | Lector de feeds RSS/Atom. |
| `znc`, `bitlbee` | Bouncer de IRC y puente hacia otras redes de chat. |
| `taskwarrior`, `calcurse` | Gestión de tareas y calendario personal. |
| `pandoc`, `groff`, `mdcat`, `glow` | Redacción, conversión y lectura de documentos en terminal. |

</details>

<details>
<summary><strong>Juegos / Fun</strong> · Juegos retro, ASCII y curiosidades · 20 paquetes</summary>

| Paquetes | Para qué sirve |
|---|---|
| `nethack`, `angband`, `crawl`, `bastet` | Roguelikes clásicos de mazmorras. |
| `ninvaders`, `pacman4console`, `moon-buggy`, `nsnake`, `nudoku`, `tty-solitaire` | Juegos arcade y pasatiempos en terminal. |
| `cmatrix`, `cbonsai`, `sl`, `cowsay`, `fortune`, `figlet`, `toilet` | Animaciones ASCII, arte de texto y mensajes divertidos. |
| `neofetch`, `fastfetch` | Mostrar información del sistema con estilo. |
| `hollywood` | Pantalla de “hacker” con ventanas y actividad simulada. |

</details>

<details>
<summary><strong>Escritorio X11</strong> · Entornos gráficos, VNC y utilidades de escritorio · 25 paquetes</summary>

> Requiere habilitar `x11-repo` antes de instalar esta categoría.

| Paquetes | Para qué sirve |
|---|---|
| `xfce4`, `xfce4-terminal`, `xfce4-panel`, `xfce4-session`, `thunar` | Entorno de escritorio XFCE, terminal, panel y gestor de archivos. |
| `openbox`, `fluxbox`, `i3`, `awesome` | Gestores de ventanas ligeros y mosaico. |
| `tigervnc`, `x11vnc`, `xorg-server` | Servidor X11 y acceso remoto por VNC. |
| `dbus`, `pulseaudio`, `alsa-utils`, `pavucontrol` | Bus de sesión, audio y control de volumen. |
| `pcmanfm` | Gestor de archivos ligero para X11. |
| `geany`, `mousepad` | Editores gráficos ligeros. |
| `xclip`, `xsel`, `xdotool`, `wmctrl`, `scrot`, `feh` | Portapapeles, automatización de ventanas, capturas y fondos. |

</details>

<details>
<summary><strong>Apps gráficas</strong> · Navegadores, ofimática, diseño y virtualización · 11 paquetes</summary>

> Requiere habilitar `x11-repo` antes de instalar esta categoría.

| Paquetes | Para qué sirve |
|---|---|
| `firefox`, `chromium` | Navegadores web completos. |
| `code-oss` | Editor de código basado en VS Code. |
| `libreoffice` | Suite ofimática: documentos, hojas de cálculo y presentaciones. |
| `gimp`, `inkscape`, `krita` | Edición de imágenes, vectores y pintura digital. |
| `qemu-system-x86-64` | Virtualización de sistemas x86_64. |
| `mkvtoolnix` | Crear y editar contenedores MKV. |
| `chocolate-doom` | Motor para jugar Doom. |
| `opencv` | Visión por computador y procesamiento de imágenes. |

</details>

<details>
<summary><strong>TUR avanzado</strong> · Paquetes pesados del repositorio TUR · 5 paquetes</summary>

> Requiere habilitar `tur-repo` antes de instalar esta categoría.

| Paquetes | Para qué sirve |
|---|---|
| `python-pandas` | Análisis y manipulación de datos tabulares. |
| `mongodb` | Base de datos NoSQL orientada a documentos. |
| `hashcat` | Recuperación y auditoría de contraseñas con GPU/CPU. |
| `ettercap`, `dsniff` | Auditoría y análisis de tráfico en redes locales. |

</details>



> `x11-repo` y `tur-repo` se habilitan automáticamente al elegir sus categorías. Algunos paquetes pueden no estar disponibles para todas las arquitecturas.

## Requisitos

- **Termux** instalado desde F-Droid (recomendado) o una distribución Linux compatible.
- **Bash 4 o superior.**
- Conexión a internet para descargar paquetes y dependencias.
- Espacio libre suficiente para los paquetes y dependencias.
- En Termux, ejecuta primero `pkg update` si hace tiempo que no actualizas.
- Para las categorías **Escritorio X11** y **Apps gráficas** se necesita `x11-repo`; para **TUR avanzado**, `tur-repo`. El instalador los prepara cuando corresponde.
- Las aplicaciones gráficas y los modelos de IA pueden requerir bastante espacio y memoria.
- En Termux no se necesita root; en Linux se usará `sudo`/`doas` solo cuando sea necesario.

## Instalación

### One-liner

El instalador se distribuye con archivos auxiliares, así que el one-liner descarga el proyecto completo en una carpeta temporal:

```bash
d="$(mktemp -d)" && curl -fsSL https://github.com/CHMODX-CODE/cx-73rmux-k17/archive/refs/heads/main.tar.gz | tar -xz -C "$d" && bash "$d/cx-73rmux-k17-main/scripts/cx-73rmux-k17.sh"; rm -rf "$d"
```

### Desde el repositorio

```bash
git clone https://github.com/CHMODX-CODE/cx-73rmux-k17.git
cd cx-73rmux-k17
bash scripts/cx-73rmux-k17.sh
```

También puedes ejecutarlo desde la copia local:

```bash
bash /sdcard/SCRIPTCHMODX/cx-73rmux-k17/scripts/cx-73rmux-k17.sh
```

## Uso

El menú principal permite **instalar**, abrir el **submenú de categorías**, **desinstalar** o consultar la **información** del entorno. Si eliges categorías, verás el plan completo antes de confirmar y una barra de progreso por cada paquete.

### Ejemplos rápidos

```bash
# Menú interactivo
bash scripts/cx-73rmux-k17.sh

# Instalar solo algunas categorías
bash scripts/cx-73rmux-k17.sh --profiles=ux,dev,net

# Ver todas las categorías disponibles
bash scripts/cx-73rmux-k17.sh --list-profiles

# Simular la instalación sin tocar el sistema
bash scripts/cx-73rmux-k17.sh --dry-run --profiles=python,media

# Diagnóstico del entorno
bash scripts/cx-73rmux-k17.sh --doctor

# Desinstalar base + extras registrados
bash scripts/cx-73rmux-k17.sh --uninstall
```

### Opciones de línea de comandos

| Flag | Efecto |
|---|---|
| `--no-splash` | Inicia sin la animación de marca (ideal para logs o CI) |
| `--no-matrix` | Desactiva la lluvia del splash |
| `--menu` | Abre el menú interactivo |
| `--no-menu` | Ejecuta la instalación directamente, sin menú |
| `--theme=<auto\|dark\|light>` | Ajusta la interfaz al fondo del terminal |
| `--no-color` | Desactiva los colores (también respeta `NO_COLOR`) |
| `--profiles=<lista>` | Instala la base + categorías (`ux,dev,net` o `all`) |
| `--list-profiles` | Muestra las categorías disponibles y sale |
| `--uninstall` | Desinstala lo que añadió este instalador |
| `--no-pause` | No se detiene a pedir `[Enter]` entre pantallas |
| `--no-promo` | No muestra la invitación final del curso |
| `--dry-run` | Simula la instalación sin modificar el sistema |
| `--env` | Muestra el entorno detectado y sale |
| `--doctor` | Ejecuta el diagnóstico completo y sale |
| `--quiet`, `-q` | Salida mínima |
| `--verbose`, `-v` | Muestra la salida completa de los comandos |
| `--yes`, `-y` | Modo automático, sin preguntas |
| `--log <ruta>` | Guarda el detalle de la ejecución en un archivo |
| `-h`, `--help` | Muestra la ayuda |

## Desinstalación

Puedes desinstalar desde el menú interactivo o directamente:

```bash
bash scripts/cx-73rmux-k17.sh --uninstall
```

La desinstalación elimina los paquetes base y **todos los extras registrados** por el kit. Los paquetes esenciales de Termux, como `curl` y `termux-tools`, se conservan para no romper `pkg`; al final se muestra la lista de lo que quedó por ser dependencia del sistema.

## Problemas frecuentes

- **Un paquete no aparece**: ejecuta `pkg update`, revisa que la categoría tenga su repositorio (`x11-repo` o `tur-repo`) y confirma que existe para tu arquitectura.
- **La instalación se detiene**: revisa el mensaje, prueba `--doctor` y ejecuta de nuevo; los paquetes ya instalados se omiten.
- **Problemas de permisos en Linux**: usa un usuario con `sudo`/`doas` o ejecuta el diagnóstico para ver qué falta.
- **X11 o VNC no arranca**: instala `x11-repo`, inicia `startxfce4` desde una sesión X y revisa el comando `vncserver` o `x11vnc`.
- **Quiero ver qué ocurrió**: usa `--log /sdcard/termux-kit.log` y revisa el archivo.
- **No puedo quitar `curl`**: es una dependencia de `termux-tools`; el instalador lo conserva a propósito.

## Licencia

MIT License. Consulta [`LICENSE`](LICENSE) para más detalles.

## Créditos

Creado y mantenido por **CHMODX-CODE**.

> Instalador desarrollado con la fábrica de instaladores **CHMODX-CODE**.
