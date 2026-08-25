# Informe de construcción 0.1.0

Fecha de la reconstrucción: 24 de agosto de 2026.

## Artefacto

- Archivo: `out/CPCgallOS-0.1.0-amd64.iso`.
- Tamaño: 5,382,733,824 bytes (5.01 GiB).
- SHA-256: `b2e9fe2fa6806d03ea9717f1cd0822ed3aa184a44794a77736ed8e6b6a1737ef`.
- SquashFS: 4,003.77 MiB, XZ, bloque de 1 MiB, 46.29 % del tamaño sin
  comprimir.
- ISO base oficial: `xubuntu-26.04-minimal-amd64.iso`, 3,225,190,400 bytes.
- SHA-256 de la base:
  `5807130e296adfba785678fa048cf9d351b11d7ac52fb02cf87dc57b7c4d66e3`.

La ISO no se publicó como GitHub Release. Se conserva en `out/`, que está
excluido de Git.

## Entorno de construcción

- Windows con WSL2 Ubuntu 24.04 y Docker Engine.
- WSL: 16 GB de RAM, 8 GB de swap y ocho procesadores disponibles.
- Construcción: cuatro CPU, límite Docker de 14 GB más 8 GB de swap y 2 GB para
  SquashFS.
- Durante el empaquetado final la swap permaneció prácticamente sin uso y no
  hubo presión de memoria ni de disco.

## Verificaciones realizadas

- SHA-256 externo y todos los MD5 internos válidos.
- El Torito BIOS y UEFI presentes; MBR protector, GPT y datos GRUB conservados.
- Exactamente dos modos GRUB, ambos con `toram`; competencia usa
  `nopersistent` y persistente usa `persistent`, `--users root` y PBKDF2.
- Ninguna opción visible de instalación.
- Initramfs sin la antigua capa `minimal.live.squashfs` y UUID de Casper
  sincronizado.
- C++ compilado y ejecutado con G++ 15.2; GDB 17.1 presente.
- Java compilado y ejecutado con OpenJDK/Javac 25.0.3.
- Python 3.14.4 ejecutado.
- Visual Studio Code 1.134.0 y Code::Blocks 25.03 presentes.
- Las siete extensiones permitidas de VS Code coinciden exactamente con la
  lista del repositorio; IA, Copilot, chat, telemetría y extensiones externas
  están bloqueados por política.
- Chromium está sembrado como snap junto con sus nueve dependencias aprobadas;
  no quedan snaps preinstalados fuera de esa semilla.
- Política de Chromium con bloqueo predeterminado, lista permitida y bloqueo de
  todas las extensiones. La lista contiene exactamente los 26 dominios de
  `config/whitelist.txt`, incluidos jueces, plataformas y documentación de CP.
- Plantillas de VS Code para C++, Java y Python con tareas de compilación y
  depuración; la plantilla C++ enlaza explícitamente el mismo label de tarea
  desde `launch.json` y `tasks.json`.
- Accesos directos de Chromium, VS Code, Code::Blocks y plantilla C++ copiados al
  escritorio del usuario live.
- Wallpaper, logo y bienvenida instalados; el inicializador los copia al
  directorio personal para que Chromium snap pueda leerlos.
- Firefox, tienda, accesos de instalación y `ubuntu-desktop-bootstrap` ausentes.
- Kernel 7.0.0-14 y siete módulos `nvidia*.ko.zst` presentes.
- VirtualBox BIOS (4 GB RAM, 2 CPU, VMSVGA, sin 3D, paravirtualización None y
  USB Tablet) alcanzó XFCE, wallpaper, bienvenida y los cuatro accesos directos.
- En Chromium, `chrome://policy` mostró `URLAllowlist` en estado `OK`; Codeforces
  cargó y Stack Overflow fue bloqueado. UEFI en VirtualBox alcanzó el splash
  gráfico de Xubuntu; no se esperó el escritorio completo en esa segunda VM.

## Requisitos y límites observados

El archivo cabe holgadamente en una USB de 32 GB. Por el uso obligatorio de
`toram`, se consideran 12 GB el mínimo práctico observado y 16 GB la
recomendación de ejecución. Equipos con 8 GB deben probarse explícitamente y no
se consideran validados.

El primer arranque en VirtualBox tardó aproximadamente 5–6 minutos con 4 GB y
2 CPU, principalmente por `toram` y el sembrado inicial de snaps. VirtualBox
mostró el aviso `vmwgfx: unsupported hypervisor`; se documenta como limitación
del adaptador virtual, no como validación o fallo de NVIDIA.

No se han validado todavía una USB física, la conservación real de persistencia,
Secure Boot, equipos escolares antiguos ni NVIDIA RTX 5060/5070. La whitelist
de Chromium es solo una primera capa del navegador y no bloquea todo el tráfico
del sistema.
