# Arquitectura

```text
Xubuntu 26.04 Minimal oficial
        |
        v
extracción ISO + overlay de las dos capas squashfs
        |
        +--> paquetes: G++, GDB, JDK, Python, Code::Blocks, VS Code
        +--> snap sembrado: Chromium
        +--> políticas: Chromium + VS Code + bloqueo de actualizaciones
        +--> marca: wallpaper + bienvenida
        +--> arranque: competencia / persistente, ambos con toram
        |
        v
ISO híbrida CPCgallOS (BIOS + UEFI)
```

La vista combinada de `minimal.squashfs` y `minimal.live.squashfs` se consolida
en una sola imagen. El initramfs se regenera para que Casper no vuelva a buscar
la capa superior retirada, y el UUID del initramfs se copia al marcador de la
ISO antes del repaquetado.

El modo competencia usa `nopersistent`: el overlay vive en RAM y se descarta al
reiniciar. El modo persistente usa `persistent` y busca una partición compatible
con Casper; su entrada de GRUB está protegida con el usuario administrativo
`root` y un hash PBKDF2.

Se usa la imagen Minimal para reducir el tamaño que debe copiarse a RAM. El
objetivo de la versión 0.1 es permanecer por debajo de 8 GB de ISO y entrar sin
problema en una memoria de 32 GB.
