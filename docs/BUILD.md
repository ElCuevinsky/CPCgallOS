# Construcción reproducible

## Requisitos

- Docker con soporte para contenedores privilegiados.
- 35 GB libres como mínimo; 50 GB son recomendables.
- 16 GB de RAM disponibles para WSL/Docker; 32 GB de RAM en el host son
  recomendables para construir sin presionar al sistema anfitrión.
- Internet para descargar la ISO, paquetes, Chromium y extensiones.
- Entre 30 y 90 minutos según el equipo y la conexión.

Para `make validate` solo se requieren Bash, `jq` y `rg`; ShellCheck se usa si
está instalado. La integración continua se añadirá cuando la autenticación de
GitHub tenga permiso para administrar workflows.

El contenedor se limita por defecto a 14 GB de RAM, 22 GB incluyendo swap y
cuatro CPU. SquashFS usa un máximo de 2 GB. Estos valores, pensados para un host
de 32 GB, se encuentran en `config/build.env` y pueden reducirse para otros
equipos.

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

La ISO Xubuntu 26.04 Minimal actual contiene
`casper/minimal.squashfs` y `casper/minimal.live.squashfs`. El proceso monta
ambas como overlay, copia la vista combinada y genera un único
`minimal.squashfs`. Después regenera el initramfs sin `LAYERFS_PATH` y sincroniza
su UUID de Casper con `.disk/casper-uuid-generic`; omitir cualquiera de esos
pasos impide encontrar el sistema live al arrancar.

El repaquetado usa `xorriso -boot_image any replay` para conservar el arranque
híbrido de la ISO oficial. `boot/grub/i386-pc/eltorito.img` se excluye del MD5
interno porque xorriso actualiza su Boot Info Table durante ese proceso.

La reconstrucción descarga actualizaciones de los repositorios de Ubuntu,
Microsoft, Snap Store y VS Marketplace. Por ello el contenido de paquetes puede
cambiar aunque la ISO base esté fijada. Una versión de producción deberá fijar
también snapshots o artefactos de todos esos repositorios.
