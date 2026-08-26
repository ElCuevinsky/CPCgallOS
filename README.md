# CPCgallOS

CPCgallOS es un sistema live para programación competitiva del club CPC
Gallos. Arranca desde USB, copia el sistema a RAM y ofrece un entorno uniforme
con C++, Java y Python.

> Estado: el prototipo arrancable `0.1.2` incorpora el teclado latinoamericano,
> CPH, los accesos directos solicitados y la contraseña administrativa de
> prototipo. Esta revisión elimina el acceso directo separado de “Gallos C++”;
> la carpeta de plantillas `concursos` se conserva. Requiere pruebas de
> arranque en VirtualBox y hardware real antes de utilizarse en una competencia
> oficial.

## Alcance del prototipo

- Xubuntu 26.04 LTS Minimal (`amd64`), basado en Ubuntu con XFCE.
- Arranque híbrido UEFI y BIOS heredado, conservando el esquema de la ISO base.
- Ejecución obligatoria en RAM mediante `toram`.
- Modo competencia sin persistencia.
- Modo persistente protegido por autenticación PBKDF2 de GRUB para el usuario
  administrativo `root`.
- GCC/G++, GDB, JDK predeterminado de Ubuntu y Python 3.
- Visual Studio Code y Code::Blocks como únicos IDE oficiales.
- Extensiones de VS Code limitadas a C/C++, Python, Java y Competitive
  Programming Helper (CPH).
- Chromium sin whitelist por ahora; conserva únicamente el bloqueo de
  instalación de extensiones no aprobadas.
- Teclado predeterminado en español latinoamericano (`latam`), sin cambiar el
  idioma de la interfaz.
- Carpeta de plantillas de C++, Java y Python en el escritorio, como
  `concursos`.
- Accesos directos visibles para Bloc de notas y Calculadora.
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

La ISO resultante se escribe en `out/CPCgallOS-0.1.2-amd64.iso`. La contraseña
se entrega únicamente al proceso de construcción; no se guarda en Git ni
dentro de los scripts.

## Resultado construido de 0.1.2

- Tamaño: 5,385,420,800 bytes (5.02 GB; 5.015 GiB).
- SHA-256: `258f4da10e5a9a49cd840ba23ce863fb69f19ec9bfcb8c88f921cc4d20438e40`.
- La inspección confirmó dos entradas GRUB, ambas con `toram`, y PBKDF2 para
  `root` en el modo persistente.
- El acceso directo separado de “Gallos C++” no está en la imagen; la carpeta
  `concursos` y sus plantillas siguen disponibles.
- La ISO está lista para probarse en VirtualBox. Esta revisión no se ha escrito
  en ninguna USB.

El detalle reproducible está en
[docs/BUILD-REPORT-0.1.2.md](docs/BUILD-REPORT-0.1.2.md).

## Resultado construido de 0.1.1

- Tamaño: 5,385,158,656 bytes (5.02 GB; 5.015 GiB).
- SHA-256: `37f50d71a5b1de4d10779755e581e8df7ef8b483dcdb503b18eced091f83b1c7`.
- La inspección de la ISO confirmó arranque BIOS/UEFI, las dos entradas GRUB
  exactas con `toram`, PBKDF2 para `root`, teclado `latam`, CPH y las
  herramientas solicitadas.
- Chromium no tiene whitelist en esta revisión; conserva el bloqueo de
  extensiones no aprobadas.
- La ISO está en `outputs/CPCgallOS-0.1.1-amd64.iso` y fue escrita en la
  Kingston `Disk 2` con código de salida 0. La lectura completa de vuelta y
  el arranque físico quedan pendientes.

El detalle reproducible está en
[docs/BUILD-REPORT-0.1.1.md](docs/BUILD-REPORT-0.1.1.md).

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

La sesión copia al escritorio la carpeta `concursos`, con proyectos de ejemplo
de C++, Java y Python. La plantilla C++ contiene `tasks.json` y `launch.json` con la misma
etiqueta `CPCgallOS: g++ build active file`, evitando el bloqueo de
`preLaunchTask`; VS Code inicia sin Restricted Mode para el workspace de
práctica. También se instalan accesos directos de Chromium, VS Code,
Code::Blocks, Bloc de notas y Calculadora.

Para comprobar la estructura sin construir varios gigabytes:

```bash
make validate
```

Consulta [docs/BUILD.md](docs/BUILD.md), [docs/SECURITY.md](docs/SECURITY.md) y
[docs/TESTING.md](docs/TESTING.md) antes de distribuir una imagen.

## Estado de navegación

Por ahora Chromium no aplica una whitelist de sitios. La política de
extensiones permanece administrada para impedir instalaciones no aprobadas;
esto no es un filtro de tráfico del sistema.

## Licencias

Los scripts del proyecto usan la licencia MIT. Ubuntu, Xubuntu, Chromium, Visual
Studio Code, Code::Blocks, NVIDIA y sus paquetes conservan sus propias
licencias. El nombre y logo de CPC Gallos no se relicencian bajo MIT; consulta
[THIRD_PARTY.md](THIRD_PARTY.md).
