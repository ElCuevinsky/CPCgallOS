# Matriz mínima de pruebas

No publiques una versión para competencia hasta completar esta matriz.

| Caso | Resultado esperado |
|---|---|
| BIOS heredado, PC antigua Intel/AMD | Menú visible y escritorio funcional |
| UEFI con Secure Boot | Arranque y escritorio funcionales |
| RTX 5060 | Resolución nativa, XFCE y VS Code estables |
| RTX 5070 | Resolución nativa, XFCE y VS Code estables |
| Modo competencia | Cambios eliminados tras reiniciar |
| Modo persistente sin clave | GRUB niega el acceso |
| Modo persistente con clave | Cambios conservados tras reiniciar |
| Chromium, dominio permitido | La página carga |
| Chromium, dominio no permitido | Chromium muestra bloqueo administrativo |
| VS Code, extensión no aprobada | La instalación es rechazada |
| `sudo`, PackageKit y tienda | El usuario no puede instalar paquetes |
| C++ | Compila, ejecuta y depura con GDB |
| Java | Compila, ejecuta y depura |
| Python | Ejecuta y depura |
| RAM de 8 GB | Registrar si `toram` completa o falla |
| RAM de 16 GB | Arranque `toram` y uso simultáneo de IDE/juez |

Para una primera prueba virtual se recomienda QEMU/KVM con UEFI y 16 GB de RAM.
La validación de BIOS debe hacerse además en hardware real, porque una VM no
reproduce firmware escolar antiguo.

Para VirtualBox en esta revisión se usa la configuración estable observada:
4096 MB de RAM, 2 CPU, gráficos VMSVGA, 128 MB de VRAM, aceleración 3D
desactivada, paravirtualización `None`, dispositivo señalador USB Tablet y la
ISO conectada como unidad óptica. La VM de revisión no tiene disco virtual y no
escribe ninguna USB.

## Resultado del prototipo 0.1.0

La imagen final del 24 de agosto de 2026 se verificó estáticamente y arrancó en
VirtualBox con BIOS heredado usando la configuración estable indicada arriba.
El primer arranque tardó aproximadamente 5–6 minutos mientras `toram` y el
sembrado inicial de snaps terminaban. Una segunda VM con firmware EFI alcanzó
el splash gráfico de Xubuntu.

Pasaron las siguientes pruebas: checksum externo e interno, dos entradas GRUB
exactas con `toram`, autenticación PBKDF2 en el modo persistente, estructura
híbrida MBR/GPT/El Torito, escritorio XFCE, bienvenida, compilación y ejecución
de C++/Java/Python, IDEs, extensiones exactas, políticas de Chromium y VS Code,
semilla exacta de snaps, ausencia del instalador/Firefox/tienda y presencia de
los módulos NVIDIA. En la prueba interactiva final, `chrome://policy` indicó
`URLAllowlist: OK`, Codeforces cargó y Stack Overflow fue bloqueado. La política
contiene los 26 dominios de `config/whitelist.txt`; la plantilla C++ de VS Code
tiene un `preLaunchTask` resuelto y accesos directos de escritorio para las
herramientas principales.

Siguen pendientes las pruebas en USB física, persistencia real entre reinicios,
Secure Boot, firmware BIOS escolar y tarjetas RTX 5060/5070. La presencia de
módulos NVIDIA en el SquashFS no equivale a validar ese hardware.
