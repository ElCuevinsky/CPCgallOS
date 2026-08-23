# Modelo de seguridad del prototipo

## Controles incluidos

- La sesión live elimina el acceso `sudo` de los usuarios creados por Casper.
- La cuenta Linux root queda bloqueada.
- La entrada persistente de GRUB requiere una contraseña PBKDF2 independiente.
- `apt-daily`, `unattended-upgrades` y PackageKit quedan deshabilitados.
- Snap refresh se pone en espera indefinida durante el arranque.
- VS Code solo acepta las extensiones aprobadas y desactiva sus funciones de IA.
- Chromium bloquea toda navegación salvo los dominios de la whitelist.
- El instalador, Firefox y la tienda de software se retiran de la semilla live o
  se ocultan de la sesión.

## Límites conocidos

- La política de Chromium no bloquea programas de línea de comandos como
  `curl`, Java o Python. La versión 0.1 no debe anunciarse como un entorno de
  red hermético.
- Una persona con acceso físico puede modificar una USB no verificada. Para una
  competencia se deben validar los hashes SHA-256 y controlar físicamente las
  memorias.
- La contraseña de GRUB protege una opción de arranque; no cifra por sí misma la
  partición persistente.
- El driver NVIDIA debe probarse con y sin Secure Boot. Un fallo debe caer en el
  controlador gráfico libre o documentarse antes del evento.

## Próxima capa

Implementar un proxy/firewall de egreso administrado que resuelva la whitelist
de dominios sin permitir rutas alternativas, más una partición persistente
cifrada y firmada para el modo administrativo.
