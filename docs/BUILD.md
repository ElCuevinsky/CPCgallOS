# Construcción reproducible

## Requisitos

- Docker con soporte para contenedores privilegiados.
- 35 GB libres como mínimo; 50 GB son recomendables.
- Internet para descargar la ISO, paquetes, Chromium y extensiones.
- Entre 30 y 90 minutos según el equipo y la conexión.

Para `make validate` solo se requieren Bash, `jq` y `rg`; ShellCheck se usa si
está instalado. La integración continua se añadirá cuando la autenticación de
GitHub tenga permiso para administrar workflows.

El contenedor se limita por defecto a 5 GB de RAM, 7 GB incluyendo swap y dos
CPU. SquashFS usa un máximo de 768 MB para evitar agotar equipos de desarrollo
de 16 GB; estos valores se encuentran en `config/build.env`.

## Contraseña del modo persistente

Genera un hash diferente para cada imagen oficial:

```bash
make password
export CPCGALLOS_GRUB_PASSWORD_HASH='grub.pbkdf2.sha512.10000....'
```

El hash protege la entrada persistente del menú GRUB. No reutilices la
contraseña de una cuenta personal o institucional. El modo competencia no pide
contraseña.

## Generar la ISO

```bash
make validate
make build
sha256sum -c out/CPCgallOS-0.1.0-amd64.iso.sha256
```

La ISO base queda en `.cache/`, el árbol temporal en `work/` y la salida en
`out/`. Ninguno de esos directorios se publica en Git.

La reconstrucción descarga actualizaciones de los repositorios de Ubuntu,
Microsoft, Snap Store y VS Marketplace. Por ello el contenido de paquetes puede
cambiar aunque la ISO base esté fijada. Una versión de producción deberá fijar
también snapshots o artefactos de todos esos repositorios.
