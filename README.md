# 📱 OpenWRT on Your Phone!

<p align="center">
  <strong>Run OpenWrt on your Android phone with QEMU.</strong><br>
  <em>No firmware flashing. No bootloader unlocking. Just a virtual router in your pocket.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Virtualization-QEMU-blue?style=for-the-badge" alt="QEMU">
  <img src="https://img.shields.io/badge/Guest-OpenWrt-00A3E0?style=for-the-badge" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Architecture-ARM64-orange?style=for-the-badge" alt="ARM64">
  <img src="https://img.shields.io/badge/Status-Experimental-yellow?style=for-the-badge" alt="Experimental">
</p>

<p align="center">
  <strong>Explore OpenWrt and experiment with router software from your phone.</strong>
</p>

> [!WARNING]
> This project is experimental. The installer downloads an OpenWrt initramfs image and creates helper scripts. It does **not** currently configure every guest-network setting, install LuCI into images that lack it, or provide persistent storage automatically.

## 📖 Table of Contents

- [✨ About](#-about)
- [🚀 Features](#-features)
- [📱 Tested Device](#-tested-device)
- [🧰 Requirements](#-requirements)
- [⚡ Quick Start](#-quick-start)
- [🌐 Access LuCI](#-access-luci)
- [⚙️ Configuration](#-configuration)
- [💾 Persistence](#-persistence)
- [🛠️ Troubleshooting](#-troubleshooting)
- [⚠️ Limitations](#-limitations)
- [🗺️ Roadmap](#-roadmap)
- [🤝 Contributing](#-contributing)
- [🔒 Security](#-security)
- [📜 License](#-license)
- [❤️ Acknowledgements](#-acknowledgements)

## ✨ About

**OpenWRT on Your Phone!** is an experimental project for running the OpenWrt router operating system inside a QEMU virtual machine on Android.

It uses Termux as the host environment and QEMU system emulation to boot an ARM64 OpenWrt initramfs image. The goal is to make OpenWrt experimentation more accessible without replacing Android, flashing firmware, or unlocking the bootloader.

## 🚀 Features

- 📱 **Android host:** Run QEMU from Termux.
- 📦 **Automated setup:** Install required Termux packages and download the OpenWrt image.
- 🖥️ **ARM64 guest:** Boot an OpenWrt `armsr/armv8` image using QEMU.
- 🌐 **Optional LuCI access:** Use a local browser connection when LuCI, the guest network, and port forwarding are configured.
- 🔌 **User-mode networking:** QEMU provides NAT-style guest networking.
- 🧠 **Adjustable resources:** Set virtual RAM and vCPU count when launching the VM.
- 🧰 **Phone-only workflow:** No PC is required for the basic Termux workflow.

## 📱 Tested Device

| Component | Configuration |
|---|---|
| Device | Samsung Galaxy A24 |
| Host OS | Android |
| Host environment | Termux |
| Emulator | QEMU System (`qemu-system-aarch64`) |
| Guest OS image | OpenWrt 25.12.6 initramfs |
| Guest target | `armsr/armv8` |
| Guest architecture | ARM64 |
| Networking mode | QEMU user-mode networking |
| Status | QEMU boot and LuCI access have been achieved in a manually configured setup |

> [!NOTE]
> The tested-device entry describes the project setup, not a guarantee that every fresh install will expose LuCI immediately. Results may vary by Android version, available RAM, and device thermal limits.

## 🧰 Requirements

- An Android device with a 64-bit ARM processor.
- Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or the [official Termux GitHub releases](https://github.com/termux/termux-app/releases).
- An active internet connection.
- Around 1.5 GB or more of free storage for packages, the image, and logs.
- Adequate free memory. **512 MB is the VM's default allocation**, in addition to Android and Termux memory usage.

## ⚡ Quick Start

Open Termux and run:

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/nonamebrub-max/OpenWRT-on-Your-Phone-/main/install.sh")
```

The installer will:

1. Update Termux package metadata.
2. Install QEMU and download utilities.
3. Download the OpenWrt 25.12.6 ARM64 initramfs image.
4. Create helper scripts in `~/openwrt-vm/`.

**The installer does not start QEMU automatically.** Start the VM separately:

```bash
bash ~/openwrt-vm/start.sh
```

Check whether it is running:

```bash
bash ~/openwrt-vm/status.sh
```

Stop it:

```bash
bash ~/openwrt-vm/stop.sh
```

View the QEMU log:

```bash
tail -f ~/openwrt-vm/qemu.log
```

## 🌐 Access LuCI

If the guest has a working network configuration and LuCI/`uhttpd` is installed and running, open this address in your Android browser:

**http://127.0.0.1:8080**

QEMU forwards the host's local port `8080` to guest address `10.0.2.15`, port `80`.

```text
Android browser
      |
      | http://127.0.0.1:8080
      v
QEMU host port forwarding
      |
      v
OpenWrt guest: 10.0.2.15:80
      |
      v
LuCI / uhttpd
```

> [!IMPORTANT]
> Port forwarding alone does not install LuCI or configure the guest interface. The launcher expects the guest to be reachable at `10.0.2.15`. If the page does not open on a fresh boot, check the guest network configuration and whether `uhttpd` is installed and running. The current installer does not automate those guest-side steps.

The OpenWrt root account is usually named `root`. Set or change its password from the OpenWrt console with `passwd` if you have console access. Do not assume a web login will work until LuCI and the guest network are ready.

## ⚙️ Configuration

The generated launcher defaults to **512 MB RAM** and **2 virtual CPUs**.

| Setting | Default | Meaning |
|---|---:|---|
| Machine | `virt` | Generic QEMU ARM virtual machine |
| CPU model | `cortex-a57` | Emulated ARM CPU model; not the phone's actual SoC |
| RAM | `512` MB | Memory assigned to the guest |
| vCPUs | `2` | Virtual CPU count |
| Display | `-nographic` | No graphical display |
| HTTP forwarding | `127.0.0.1:8080 → guest:80` | Local web access |
| SSH forwarding | `127.0.0.1:2222 → guest:22` | Port mapping; SSH must be enabled in the guest |

Override RAM or vCPU count for a launch:

```bash
RAM_MB=256 CPUS=2 bash ~/openwrt-vm/start.sh
```

> [!WARNING]
> A 256 MB guest profile is experimental. It can limit package installation and may cause out-of-memory errors. Lowering the VM's memory does not change the physical RAM available to Android.

## 💾 Persistence

This project currently boots an **initramfs image**. The guest runs from memory, so package installations and configuration changes may be lost when the VM exits.

Persistent virtual-disk storage is not implemented by the current installer. A backup created inside the guest's temporary filesystem, such as `/tmp/backup.tar.gz`, is also lost when that guest session ends unless you copy it somewhere persistent before stopping the VM.

## 🛠️ Troubleshooting

<details>
<summary><strong>curl or package installation fails</strong></summary>

Update Termux and install the download utilities:

```bash
pkg update
pkg install curl wget -y
```

Then rerun the installer. If repository errors continue, check your internet connection and Termux repository configuration.
</details>

<details>
<summary><strong>The VM does not stay running</strong></summary>

Check the QEMU log:

```bash
tail -n 80 ~/openwrt-vm/qemu.log
```

Confirm that the image exists and that Termux has enough free memory. Android may terminate background processes under memory pressure.
</details>

<details>
<summary><strong>LuCI shows “Connection refused” or does not load</strong></summary>

The guest must have the expected IP address, port 80 must be reachable, and LuCI/`uhttpd` must be installed and running. Check the guest configuration from an available OpenWrt console. The current launcher runs QEMU in the background and writes output to `~/openwrt-vm/qemu.log`; it does not provide an interactive console window.
</details>

<details>
<summary><strong>OpenWrt has no internet access</strong></summary>

Inside the guest, inspect the interface, route, and DNS configuration:

```sh
ip addr
ip route
cat /etc/resolv.conf
```

QEMU user-mode networking provides a virtual NAT network; it is not a direct bridge to the phone's Wi-Fi or cellular interface.
</details>

<details>
<summary><strong>Changes disappear after stopping the VM</strong></summary>

This is expected with the current initramfs-only setup. Persistent storage is planned but not yet included.
</details>

## ⚠️ Limitations

- OpenWrt runs as a QEMU guest, not as the phone's native operating system.
- The `cortex-a57` CPU setting is an emulated model and does not reproduce the phone's Helio G99 hardware exactly.
- QEMU user-mode networking uses virtual NAT and does not directly bridge the guest to the phone's physical Wi-Fi or cellular interfaces.
- The guest cannot automatically use the phone's Wi-Fi chipset as a router access point.
- Performance depends on the device, QEMU build, memory pressure, and thermal throttling.
- LuCI availability and guest network setup are not fully automated by the current installer.
- Initramfs changes are temporary; persistent disk support is not yet implemented.

## 🗺️ Roadmap

- [x] Boot an OpenWrt ARM64 initramfs image with QEMU.
- [x] Create an installer for Termux dependencies and the image.
- [x] Generate start, stop, and status helper scripts.
- [x] Support QEMU user-mode networking and local port-forwarding arguments.
- [ ] Automate guest network configuration for first boot.
- [ ] Detect or install LuCI where supported.
- [ ] Add persistent virtual-disk storage.
- [ ] Test low-memory profiles such as 256 MB.
- [ ] Document USB tethering options and limitations.

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome.

When opening an issue, include:

- Device model and Android version.
- Termux version and installation source.
- The command you ran.
- Relevant error messages or the last lines of `~/openwrt-vm/qemu.log`.

## 🔒 Security

- Use a strong OpenWrt root password when account access is enabled.
- The launcher binds forwarded ports to `127.0.0.1`, limiting them to the Android device by default.
- Download OpenWrt images only from official upstream sources.
- Review scripts before running them; this command executes the installer directly from the repository.

## 📜 License

Project scripts and documentation are intended to be licensed under the MIT License. Add a `LICENSE` file containing the full MIT License text to make the repository's licensing explicit.

Upstream projects have their own licenses and terms, including OpenWrt, QEMU, and Termux.

## ❤️ Acknowledgements

- The [OpenWrt Project](https://openwrt.org/) for its modular embedded Linux router distribution.
- The [QEMU Project](https://www.qemu.org/) for machine emulation.
- The [Termux team](https://github.com/termux/termux-app) for bringing a powerful terminal environment to Android.

<p align="center">
  <strong>📱 OpenWRT on Your Phone!</strong><br>
  <em>A tiny virtual router. A whole lot of possibilities.</em>
</p>
