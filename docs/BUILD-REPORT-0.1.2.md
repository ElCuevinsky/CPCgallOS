# Informe de construcción de CPCgallOS 0.1.2

Este documento se completa con los resultados reales de la reconstrucción de
la ISO `0.1.2`. La contraseña PBKDF2 de GRUB se proporciona al proceso de
construcción mediante una variable de entorno efímera y no se almacena en el
repositorio.

## Cambios de esta revisión

- Se eliminó del escritorio el acceso directo separado de “Gallos C++”.
- Se conserva la carpeta de plantillas `concursos` y sus configuraciones de
  compilación y depuración de C++, Java y Python.
- Se configuró la contraseña administrativa de prototipo para el modo
  persistente durante la construcción.

## Resultado de la construcción

- Archivo: `out/CPCgallOS-0.1.2-amd64.iso`.
- Tamaño: 5,385,420,800 bytes (5.02 GB; 5.015 GiB).
- SHA-256: `258f4da10e5a9a49cd840ba23ce863fb69f19ec9bfcb8c88f921cc4d20438e40`.
- Base ISO verificada contra el SHA-256 fijado en `config/build.env`.
- El catálogo El Torito conserva BIOS heredado y UEFI.

## Inspección estática de la ISO

- GRUB contiene exactamente las entradas competencia y persistente.
- Ambas entradas incluyen `toram`; la entrada persistente usa `persistent` y
  requiere el usuario GRUB `root` mediante PBKDF2.
- El squashfs contiene G++, GDB, Java, Python 3, VS Code, Code::Blocks,
  Chromium, CPH, las plantillas de C++, Java y Python, el wallpaper y los
  cinco accesos directos esperados: Chromium, VS Code, Code::Blocks, Bloc de
  notas y Calculadora.
- El acceso directo `cpcgallos-desktop-cpp-template.desktop` está ausente.
- La política de Chromium mantiene el bloqueo de instalación de extensiones;
  esta revisión sigue sin whitelist de URLs y no bloquea todo el tráfico del
  sistema.
- La política de VS Code conserva las extensiones y restricciones de IA,
  telemetría y actualizaciones definidas por el proyecto.

## Límites de la prueba

Esta revisión fue verificada por inspección de la ISO, pero todavía no se ha
arrancado en VirtualBox ni se ha escrito en una USB. Por tanto, el arranque
físico, el funcionamiento gráfico en hardware NVIDIA/AMD y la persistencia
real quedan pendientes.
