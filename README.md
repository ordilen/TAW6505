# Philips TAW6505 / TWA6505 / TAW6205 — Reverse Engineering Notes

If your wireless speaker does not run anymore, there is a good chance, that its firmware got
corrupted. It's exactly what happened to mine. Unfortunately, you cannot download and flash official firmare, because it's encrypted. And if the main system of the speaker is not working, it is not
enabling USB port on the back and cannot decrypt and update firmware delivered on USB stick.

So that's why I provide you with following findings, that will hopefully allow you to fix your speaker. Please be cautious and be advised, that chip flashing and soldering skills may be required, although you can flash it from UBOOT using UART connecton (I don't remember which one was working: ymodem, zmodem, kermit or something else - but after some fiddling and loooong time it worked). Fortunately to all of us, the firmware password is static and same for all devices (not sure if this applies to TAW6205).

In the first part you will get firmware password and commands to extract firmware binary partitions.

In the second I will show you how to get root shell on the device. It's easy do get to the UBOOT
bootloader, but as soon as you start linux kernel the device goes silent. With some settings in the
UBOOT you can however get linux shell as root. Unfortunately, I was not able to make the telnet service
persistent across reboots, because the data on the main partition are not saved to the flash
chip. If you find a way to make telnet (or SSH) persistent, let me know.

I do not take any responsibility for your actions. Take care everybody.


**Device**: Philips TAW6505 wireless speaker  
**Platform**: Phorus Caprica5 / ALi M3921 (ARMv7 dual-core Cortex-A9)  
**Flash**: Macronix NAND 528 MB  
**Firmware version**: 506.2.0.035  

---

## Firmware Decryption Password

```
1848db40-f54a-49d7-a5dc-97b5f3223ad2
```

Stored at offset `+0x58` in the `see` partition security block (MTD8, primary copy at raw NAND offset `0x162C000`, backup at `0x164D000`). This is a **product-wide** UUID — identical on every TWA6505 unit.

---

## Decrypt Firmware

The firmware ZIP (`factorytest0.zip` inside `system5.zip`) is encrypted with Blowfish-CBC, key derived from the password via `EVP_BytesToKey` (MD5):

```bash
openssl enc -bf-cbc -d -md md5 \
    -provider legacy -provider default \
    -pass pass:1848db40-f54a-49d7-a5dc-97b5f3223ad2 \
    -in factorytest0.zip \
    -out firmware_decrypted.zip
```

> `-provider legacy -provider default` is required on OpenSSL 3.x (Blowfish moved to legacy provider).



`system5.zip` contains:

```
-rwxr-xr-x 1 kali kali   271974 Mar  5 14:56 Caprica5_app_upd
-rwxr-xr-x 1 kali kali     7682 Mar  5 14:56 CommonFunctions.sh
-rwxr-xr-x 1 kali kali      169 Mar  5 14:56 Credential.sh
-rwxr-xr-x 1 kali kali    16785 Mar  5 14:56 factorytest.sh
-rw-r--r-- 1 kali kali  8866060 Mar  5 14:56 main.ubo
-rwxr-xr-x 1 kali kali    14025 Mar  5 14:56 PhorusCaprica5AzureStorage.sh
-rwxr-xr-x 1 kali kali    91961 Mar  5 14:56 PhorusCaprica5FactoryCommon.sh
-rwxr-xr-x 1 kali kali     7059 Mar  5 14:56 PhorusCaprica5UICommon.sh
-rwxr-xr-x 1 kali kali    16745 Mar  5 14:56 PhorusCaprica5UpdateCommon.sh
-rw-r--r-- 1 kali kali 52297728 Mar  5 14:56 rootfs.ubi
-rw-r--r-- 1 kali kali  3959952 Mar  5 14:56 see.ubo
-rwxr-xr-x 1 kali kali   397024 Mar  5 14:56 update_fail.wav
-rw-r--r-- 1 kali kali      713 Mar  5 14:56 update.manifest
-rwxr-xr-x 1 kali kali   264724 Mar  5 14:56 update_success.wav
-rwxr-xr-x 1 kali kali   264724 Mar  5 14:56 update.wav
-rwxr-xr-x 1 kali kali    11924 Mar  5 14:56 wifi_led
```

`factorytest.zip` contains:
```
-rwxr-xr-x 1 kali kali 271974 Mar  5 14:56 Caprica5_app_upd
-rwxr-xr-x 1 kali kali   7682 Mar  5 14:56 CommonFunctions.sh
-rwxr-xr-x 1 kali kali    169 Mar  5 14:56 Credential.sh
-rwxr-xr-x 1 kali kali  16785 Mar  5 14:56 factorytest.sh
-rwxr-xr-x 1 kali kali  14025 Mar  5 14:56 PhorusCaprica5AzureStorage.sh
-rwxr-xr-x 1 kali kali  91961 Mar  5 14:56 PhorusCaprica5FactoryCommon.sh
-rwxr-xr-x 1 kali kali   7059 Mar  5 14:56 PhorusCaprica5UICommon.sh
-rwxr-xr-x 1 kali kali  16745 Mar  5 14:56 PhorusCaprica5UpdateCommon.sh
-rwxr-xr-x 1 kali kali 397024 Mar  5 14:56 update_fail.wav
-rw-r--r-- 1 kali kali    713 Mar  5 14:56 update.manifest
-rwxr-xr-x 1 kali kali 264724 Mar  5 14:56 update_success.wav
-rwxr-xr-x 1 kali kali 264724 Mar  5 14:56 update.wav
-rwxr-xr-x 1 kali kali   3704 Mar  5 14:56 virtualx_parameter_3_1.json
-rwxr-xr-x 1 kali kali   3704 Mar  5 14:56 virtualx_parameter.json
-rwxr-xr-x 1 kali kali    206 Mar  5 14:56 vx_config.json
-rwxr-xr-x 1 kali kali  11924 Mar  5 14:56 wifi_led
```

`gc4a5` contains:
```
-rwxr-xr-x 1 kali kali   271974 Mar  5 14:56 Caprica5_app_upd
-rwxr-xr-x 1 kali kali     7682 Mar  5 14:56 CommonFunctions.sh
-rwxr-xr-x 1 kali kali      169 Mar  5 14:56 Credential.sh
-rwxr-xr-x 1 kali kali    16785 Mar  5 14:56 factorytest.sh
-rw-r--r-- 1 kali kali 38005456 Mar  5 14:56 gcast_sw.yaffs2.gz
-rwxr-xr-x 1 kali kali    14025 Mar  5 14:56 PhorusCaprica5AzureStorage.sh
-rwxr-xr-x 1 kali kali    91961 Mar  5 14:56 PhorusCaprica5FactoryCommon.sh
-rwxr-xr-x 1 kali kali     7059 Mar  5 14:56 PhorusCaprica5UICommon.sh
-rwxr-xr-x 1 kali kali    16745 Mar  5 14:56 PhorusCaprica5UpdateCommon.sh
-rwxr-xr-x 1 kali kali   397024 Mar  5 14:56 update_fail.wav
-rw-r--r-- 1 kali kali      713 Mar  5 14:56 update.manifest
-rwxr-xr-x 1 kali kali   264724 Mar  5 14:56 update_success.wav
-rwxr-xr-x 1 kali kali   264724 Mar  5 14:56 update.wav
-rwxr-xr-x 1 kali kali    11924 Mar  5 14:56 wifi_led
```

`recovery5` contains:
```
-rwxr-xr-x  1 kali kali   271974 Mar  5 14:56 Caprica5_app_upd
-rwxr-xr-x  1 kali kali     7682 Mar  5 14:56 CommonFunctions.sh
-rwxr-xr-x  1 kali kali      169 Mar  5 14:56 Credential.sh
-rwxr-xr-x  1 kali kali    16785 Mar  5 14:56 factorytest.sh
-rwxr-xr-x  1 kali kali    14025 Mar  5 14:56 PhorusCaprica5AzureStorage.sh
-rwxr-xr-x  1 kali kali    91961 Mar  5 14:56 PhorusCaprica5FactoryCommon.sh
-rwxr-xr-x  1 kali kali     7059 Mar  5 14:56 PhorusCaprica5UICommon.sh
-rwxr-xr-x  1 kali kali    16745 Mar  5 14:56 PhorusCaprica5UpdateCommon.sh
-rw-r--r--  1 kali kali 27555724 Mar  5 14:56 recovery.ubo
-rw-r--r--  1 kali kali  3959952 Mar  5 14:56 see.ubo
-rwxr-xr-x  1 kali kali   397024 Mar  5 14:56 update_fail.wav
-rw-r--r--  1 kali kali      713 Mar  5 14:56 update.manifest
-rwxr-xr-x  1 kali kali   264724 Mar  5 14:56 update_success.wav
-rwxr-xr-x  1 kali kali   264724 Mar  5 14:56 update.wav
-rwxr-xr-x  1 kali kali    11924 Mar  5 14:56 wifi_led
```

You can use the automation script:

```bash
bash decrypt_firmware.sh
```

---

## Get a Root Shell

### Why the console goes silent at "Starting kernel..."

The DTB on flash (`/dev/mtd1`) has no serial/UART node. The kernel's serial8250 driver finds no platform device, `ttyS0` is never registered, and the console goes silent immediately. The fix is to inject a UART DT node in RAM before booting.

### Step 1 — Interrupt U-Boot (1-second window)

Connect a 3.3V serial adapter to the UART pads (115200 8N1). Press any key during the 1-second U-Boot countdown (`bootdelay=1`).

### Step 2 — Inject UART node + drop to root shell

Paste at the U-Boot prompt (DTB is already in RAM at `0x86108000` from normal boot sequence):
**WARNING: use paste-slow feature in your software (Minicom or Picocom), otherwise you may get some characters lost while pasting, due to slow UART connection without flow control.**

```
fdt addr 0x86108000
fdt resize 512
fdt mknode / uart0
fdt set /uart0 compatible "ns16550a"
fdt set /uart0 reg <0x18018300 0x100>
fdt set /uart0 clock-frequency <0x1c2000>
fdt set /uart0 interrupt <0 22 4>
fdt set /aliases serial0 "/uart0"
setenv bootargs "ubi.mtd=11 root=ubi0:rootfs rootfstype=ubifs rootflags=sync rw init=/bin/sh console=ttyS0,115200N8 no_console_suspend cver=9"
boot
```

The kernel mounts the UBIFS rootfs and spawns `/bin/sh` as PID 1 with a fully functional ttyS0 console.

### Step 3 — Inside the shell

```sh
exec /bin/sh -i          # enable job control
mount -t proc proc /proc
mount -t sysfs sysfs /sys
```

### Start telnetd for WiFi access

```sh
busybox telnetd -l /bin/sh -p 4444 &
```

Wait ~30 seconds for S51phorus to connect to WiFi, then from Kali:

```sh
telnet 10.10.1.137 4444
```

### Restore normal boot

```
setenv bootargs "ubi.mtd=11 root=ubi0:rootfs rootfstype=ubifs rootflags=sync rw console=ttyS0,115200N8 no_console_suspend cver=9"
saveenv
boot
```

---

## Why Changes Don't Persist (UBIFS Write Failure)

**The rootfs (MTD11) appears writable but all changes are silently lost on reboot.**

### Evidence

- `cat /sys/class/mtd/mtd11/flags` → `0x400` (`MTD_WRITEABLE`) — MTD driver reports writable
- UBIFS mounts `rw,sync` — writes return no errors to userspace
- But on every boot: `UBIFS: start fixing up free space` — the UBIFS `space_fixup` superblock flag is **never cleared**, which means the filesystem always comes up in its original factory-flashed state

### Root cause

U-Boot sets **hardware NAND block locks** on the rootfs partition before handing control to Linux. The ALi NAND driver honours the MTD_WRITEABLE flag from its configuration, but the underlying NAND chip rejects write and erase operations at the hardware level. The UBIFS journal accumulates in RAM and is discarded at power-off — it never reaches NAND.

Attempted workarounds that all failed:
- `sync` + `reboot` — kernel 3.12 reboot path does not guarantee UBIFS commit before reset
- SysRq force-remount — `CONFIG_MAGIC_SYSRQ` not compiled in; `/proc/sysrq-trigger` absent
- `Caprica5_app_upd filesystem_status 1` — flag already 1; not the watchdog mechanism
- Direct writes via shell — silently lost every reboot

### What IS persistent

The `/data` partition (MTD12, 4 MB, YAFFS2) uses atomic writes at the flash level. Writes to `/data` **survive reboots** without any special flush. Confirmed: `/data/persist_test.txt` written before reboot, present after reboot.

### How to write to rootfs

Only `Caprica5_app_upd` can write to MTD11 — it handles NAND block unlock internally:

```sh
Caprica5_app_upd rootfs /tmp/rootfs_new.ubi   # expects a full UBIFS image
```

**Warning**: passing anything other than a complete UBIFS image destroys the filesystem.

---

## Flash Partition Table

| Partition | MTD# | Offset | Size | FS | Notes |
|---|---|---|---|---|---|
| boot_total_area | 0 | 0x00000000 | 1 MB | raw | Bootloader area |
| dts | 1 | 0x00100000 | 256 KB | raw | Device tree blob (FDT at +0x40) |
| uboot | 2 | 0x00140000 | 1 MB | raw | U-Boot 2016.01-rc2 |
| bootenv | 3 | 0x00240000 | 256 KB | raw | U-Boot env (no `bootargs` var — comes from DTB) |
| deviceinfo | 4 | 0x00280000 | 256 KB | YAFFS2 | Device provisioning info |
| bootmedia | 5 | 0x002C0000 | 8 MB | raw | Boot media (blank on this unit) |
| boot_logo | 6 | 0x00AC0000 | 1 MB | raw | Splash screen |
| kernel | 7 | 0x00BC0000 | 10 MB | raw | Linux 3.12.74 `main.ubo` |
| see | 8 | 0x015C0000 | 5 MB | raw | Security Engine + credentials |
| see_backup | 9 | 0x01AC0000 | 5 MB | raw | Security Engine backup |
| recovery_sys | 10 | 0x01FC0000 | 32 MB | raw | **Blank on this unit** |
| rootfs | 11 | 0x03FC0000 | 74 MB | UBIFS | Root filesystem — hardware NAND-locked |
| data | 12 | — | 4 MB | YAFFS2 | Persistent data — writable |
| data2 | 13 | — | ~114 MB | YAFFS2 | Secondary data |
| data3 | 14 | — | 54 MB | YAFFS2 | — |
| gcast_data | 15 | — | 10 MB | YAFFS2 | Google Cast data |
| gcast_sw | 16 | — | 192 MB | YAFFS2 | Google Cast software |
