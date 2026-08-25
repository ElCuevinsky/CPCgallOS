# Informe de construcción CPCgallOS 0.1.1

Fecha: 25 de agosto de 2026

## Artefacto

- ISO: `CPCgallOS-0.1.1-amd64.iso`
- Tamaño: 5,385,158,656 bytes (5.02 GB; 5.015 GiB)
- SHA-256: `37f50d71a5b1de4d10779755e581e8df7ef8b483dcdb503b18eced091f83b1c7`
- Salida local de prueba: `outputs/CPCgallOS-0.1.1-amd64.iso`

## Cambios incluidos

- Teclado predeterminado XKB `latam`, tanto en `/etc/default/keyboard` como
  en la configuración inicial de XFCE.
- Se retiraron por completo `URLAllowlist` y `URLBlocklist` de la política de
  Chromium. La lista humana `config/whitelist.txt` también fue eliminada.
  Chromium conserva otras políticas administrativas, incluido el bloqueo de
  instalación de extensiones no aprobadas; esto no filtra el tráfico general
  del sistema.
- Se instaló `DivyanshuAgrawal.competitive-programming-helper` (CPH) en el
  perfil live de VS Code. VS Code normaliza el identificador instalado a
  minúsculas; el verificador compara sin distinguir mayúsculas.
- Las plantillas se copian al escritorio como `concursos`.
- Se añadieron accesos directos de Bloc de notas (`mousepad`) y Calculadora
  (`galculator`).

## Verificaciones realizadas

- `make validate`: correcto.
- ISO base oficial: checksum fijado en `config/build.env`, correcto.
- El Torito: BIOS heredado y UEFI presentes; la imagen conserva MBR
  protector/GPT y las imágenes `/boot/grub/i386-pc/eltorito.img` y EFI.
- GRUB: exactamente los modos competencia y persistente, ambos con `toram`;
  persistente protegido por PBKDF2 para `root`.
- SquashFS: presentes G++, GDB, Java/JDK, Python 3, VS Code, Code::Blocks,
  Chromium, CPH, `mousepad`, `galculator`, teclado `latam`, plantillas,
  configuración de XFCE y accesos directos.
- No se encontró whitelist de sitios en la política de Chromium.
- La construcción terminó con `xorriso` y checksum interno coincidente.

## Pendiente

La ISO se escribió en la Kingston DataTraveler identificada como Windows
`Disk 2` y el flasheador terminó con código 0. La lectura completa de vuelta
no se pudo ejecutar porque Windows canceló la UAC del verificador; por ello no
se declara una verificación byte a byte. Tampoco se declaran validados arranque
físico, persistencia real, Secure Boot o NVIDIA
RTX 5060/5070; deben probarse fuera de la VM.
