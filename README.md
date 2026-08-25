# CPCgallOS

CPCgallOS es un sistema live para programación competitiva del club CPC
Gallos. Arranca desde USB, copia el sistema a RAM y ofrece un entorno uniforme
con C++, Java y Python.

> Estado: el prototipo arrancable `0.1.0` fue construido y verificado en
> VirtualBox el 24 de agosto de 2026. Todavía requiere pruebas en hardware real antes de
> utilizarse en una competencia oficial.

## Alcance del prototipo

- Xubuntu 26.04 LTS Minimal (`amd64`), basado en Ubuntu con XFCE.
- Arranque híbrido UEFI y BIOS heredado, conservando el esquema de la ISO base.
- Ejecución obligatoria en RAM mediante `toram`.
- Modo competencia sin persistencia.
- Modo persistente protegido por autenticación PBKDF2 de GRUB para el usuario
  administrativo `root`.
- GCC/G++, GDB, JDK predeterminado de Ubuntu y Python 3.
- Visual Studio Code y Code::Blocks como únicos IDE oficiales.
- Extensiones de VS Code limitadas a C/C++, Python y Java.
- Chromium con una lista administrada de sitios permitidos.
- Whitelist de jueces, plataformas y documentación de programación competitiva
  en [config/whitelist.txt](config/whitelist.txt); no incluye Stack Overflow,
  GitHub, GitLab, YouTube ni buscadores generales.
- Instalación de paquetes y actualizaciones automáticas bloqueadas para la
  sesión live.
- NVIDIA 580 Open para probar RTX 5060/5070, además de Mesa y firmware de
  Ubuntu para Intel/AMD.
- Fondo y página de bienvenida con la identidad de CPC Gallos.

## Construcción rápida

Requisitos: Docker, al menos 35 GB libres, 16 GB de RAM recomendados y conexión
a Internet. La compilación descarga la ISO oficial y paquetes, por lo que puede
tardar bastante la primera vez.

```bash
make password
export CPCGALLOS_GRUB_PASSWORD_HASH='grub.pbkdf2.sha512.10000....'
make build
```

La ISO resultante se escribe en `out/CPCgallOS-0.1.0-amd64.iso`. La contraseña
no se guarda en Git ni dentro de los scripts.

## Resultado verificado de 0.1.0

- Tamaño: 5,382,733,824 bytes (5.01 GiB).
- SHA-256: `48028d9b72119e248cb4304109c27da8dfeeddbe8155ac0f5947b4b1ab53c0e7`.
- Arranque BIOS y escritorio XFCE comprobados en VirtualBox; UEFI alcanzó el
  arranque gráfico de Xubuntu.
- 12 GB de RAM es el mínimo práctico observado para la VM; se recomiendan
  16 GB por el uso obligatorio de `toram`.
- Una USB de 32 GB deja espacio holgado para la ISO y una futura partición de
  persistencia.

Los detalles, versiones y límites de la prueba están en
[docs/BUILD-REPORT-0.1.0.md](docs/BUILD-REPORT-0.1.0.md).

La sesión copia a `~/CPCgallOS/Plantillas` proyectos de ejemplo de C++, Java y
Python. La plantilla C++ contiene `tasks.json` y `launch.json` con la misma
etiqueta `CPCgallOS: g++ build active file`, evitando el bloqueo de
`preLaunchTask`; VS Code inicia sin Restricted Mode para el workspace de
práctica. También se instalan accesos directos de Chromium, VS Code, Code::Blocks
y la plantilla C++ en el escritorio del usuario live.

Para comprobar la estructura sin construir varios gigabytes:

```bash
make validate
```

Consulta [docs/BUILD.md](docs/BUILD.md), [docs/SECURITY.md](docs/SECURITY.md) y
[docs/TESTING.md](docs/TESTING.md) antes de distribuir una imagen.

## Advertencia sobre la whitelist

El prototipo aplica la whitelist mediante políticas administradas de Chromium.
Esto evita la navegación normal a sitios no aprobados, pero no es todavía un
filtro completo de todo el tráfico de red del sistema. El firewall/proxy de
egreso está programado para la siguiente etapa.

## Licencias

Los scripts del proyecto usan la licencia MIT. Ubuntu, Xubuntu, Chromium, Visual
Studio Code, Code::Blocks, NVIDIA y sus paquetes conservan sus propias
licencias. El nombre y logo de CPC Gallos no se relicencian bajo MIT; consulta
[THIRD_PARTY.md](THIRD_PARTY.md).
