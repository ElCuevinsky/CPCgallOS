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
