# CPCgallOS

CPCgallOS es un sistema live para programación competitiva del club CPC
Gallos. Arranca desde USB, copia el sistema a RAM y ofrece un entorno uniforme
con C++, Java y Python.

> Estado: prototipo `0.1.0`. Todavía requiere pruebas en hardware real antes de
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
- Instalación de paquetes y actualizaciones automáticas bloqueadas para la
  sesión live.
- NVIDIA 580 Open para probar RTX 5060/5070, además de Mesa y firmware de
  Ubuntu para Intel/AMD.
- Fondo y página de bienvenida con la identidad de CPC Gallos.

## Construcción rápida

Requisitos: Docker, al menos 35 GB libres y conexión a Internet. La compilación
descarga la ISO oficial y paquetes, por lo que puede tardar bastante la primera
vez.

```bash
make password
export CPCGALLOS_GRUB_PASSWORD_HASH='grub.pbkdf2.sha512.10000....'
make build
```

La ISO resultante se escribe en `out/CPCgallOS-0.1.0-amd64.iso`. La contraseña
no se guarda en Git ni dentro de los scripts.

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
