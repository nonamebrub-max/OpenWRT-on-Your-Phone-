# 📱 OpenWRT on Your Phone!

<p align="center">
  <strong>Run OpenWrt on your Android phone with QEMU.</strong>
  <br>
  <em>No firmware flashing. No bootloader unlocking. Just a virtual router in your pocket.</em>
</p><p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Virtualization-QEMU-blue?style=for-the-badge" alt="QEMU">
  <img src="https://img.shields.io/badge/Guest-OpenWrt-00A3E0?style=for-the-badge" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Architecture-ARM64-orange?style=for-the-badge" alt="ARM64">
  <img src="https://img.shields.io/badge/Status-Experimental-yellow?style=for-the-badge" alt="Experimental">
</p><p align="center">
  <strong>Explore OpenWrt. Test LuCI. Experiment with networking. All from your phone.</strong>
</p>---

📖 Table of Contents

- "✨ About" (#-about)
- "🚀 Features" (#-features)
- "📱 Tested Device" (#-tested-device)
- "🧰 Requirements" (#-requirements)
- "⚡ Quick Start" (#-quick-start)
- "🌐 Access LuCI" (#-access-luci)
- "⚙️ Configuration" (#️-configuration)
- "💾 Persistence" (#-persistence)
- "🛠️ Troubleshooting" (#️-troubleshooting)
- "⚠️ Limitations" (#️-limitations)
- "🗺️ Roadmap" (#️-roadmap)
- "🤝 Contributing" (#-contributing)
- "📜 License" (#-license)

✨ About

OpenWRT on Your Phone! is an experimental project that runs the OpenWrt router operating system inside a QEMU virtual machine on Android.

The project uses Termux as the host environment and QEMU system emulation to boot an ARM64 OpenWrt image. Once the virtual machine is running, users can access LuCI, the OpenWrt web interface, directly from their Android browser.

The goal is simple: make OpenWrt experimentation more accessible without replacing Android or flashing router firmware.

«💡 This project runs OpenWrt inside Android. It does not replace the phone's operating system.»

🚀 Features

- 📱 Run OpenWrt on Android through Termux.
- 🖥️ Boot an ARM64 OpenWrt image with QEMU.
- 🌐 Access LuCI from the phone's browser.
- 🔌 Use QEMU user-mode networking with NAT.
- 🧠 Configure virtual RAM and CPU resources.
- 🧪 Experiment with OpenWrt packages and router settings.
- 🛡️ Keep the original Android firmware untouched.
- 🧰 Use a terminal-based workflow without requiring a PC.

📱 Tested Device

Component| Configuration
Device| Samsung Galaxy A24
Host OS| Android
Host environment| Termux
Emulator| QEMU System
Guest OS| OpenWrt 25.12.6
Guest target| "armsr/armv8"
Architecture| ARM64
Web interface| LuCI
Networking| QEMU user-mode NAT
Test status| Boots successfully; LuCI accessed

Compatibility: The project was tested on a Samsung Galaxy A24. Other devices may work, but their compatibility has not been verified.

🧰 Requirements

Before getting started, make sure you have:

- An Android phone with an ARM64 processor.
- "Termux" (https://github.com/termux/termux-app).
- An active internet connection.
- Enough free storage for the OpenWrt image and packages.
- Sufficient available RAM for Android and the virtual machine.
- Basic familiarity with terminal commands.

Required packages

The installation uses these Termux packages:

- "qemu-system-aarch64-headless"
- "wget"
- "curl"
- "tar"

⚡ Quick Start

1. Update Termux

Open Termux and run:

pkg update
pkg upgrade

2. Install dependencies

pkg install qemu-system-aarch64-headless wget curl tar

Verify QEMU:

qemu-system-aarch64 --version

3. Download OpenWrt

Create a working directory:

mkdir -p ~/openwrt-vm
cd ~/openwrt-vm

Download the ARM64 initramfs image:

wget -c https://downloads.openwrt.org/releases/25.12.6/targets/armsr/armv8/openwrt-25.12.6-armsr-armv8-generic-initramfs-kernel.bin

Official download directory:

"OpenWrt ARMv8 Downloads" (https://downloads.openwrt.org/releases/25.12.6/targets/armsr/armv8/)

4. Start the virtual machine

The following is the initial experimental configuration, using 512 MB of virtual RAM and two virtual CPUs.

cd ~/openwrt-vm

qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a57 \
  -m 512 \
  -smp 2 \
  -kernel openwrt-25.12.6-armsr-armv8-generic-initramfs-kernel.bin \
  -append "console=ttyAMA0" \
  -nographic \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:8080-10.0.2.15:80 \
  -device virtio-net-device,netdev=net0

Wait for OpenWrt to boot.

You should see the OpenWrt console and a login prompt.

Important: The guest network must be configured correctly before LuCI can be installed or accessed.

5. Configure the guest network

At the OpenWrt console, configure the LAN interface to obtain an address from QEMU's virtual DHCP server:

uci set network.lan.proto='dhcp'
uci commit network
/etc/init.d/network restart

Check the address and default route:

ip addr
ip route

The expected configuration is:

Setting| Expected value
Guest address| "10.0.2.15"
Virtual gateway| "10.0.2.2"
Host browser port| "8080"
Guest web port| "80"

The interface may be "br-lan", with "eth0" attached to the bridge.

Test connectivity:

ping -c 3 10.0.2.2
ping -c 3 1.1.1.1

If the guest cannot reach the network, troubleshoot connectivity before continuing.

6. Install LuCI

Once internet access works inside OpenWrt, run:

apk update
apk add luci

Set the root password:

passwd

Enable and restart the web server:

/etc/init.d/uhttpd enable
/etc/init.d/uhttpd restart

7. Open the web interface

Open Chrome or another browser on the same Android phone.

URL:

http://127.0.0.1:8080

Log in with:

- Username: "root"
- Password: The password you configured with "passwd"

🎉 You can now explore the LuCI interface from your phone.

🌐 Access LuCI

The initial QEMU command forwards TCP port "8080" on the Android loopback interface to port "80" inside the guest.

Android Browser
      |
      | http://127.0.0.1:8080
      v
QEMU Port Forwarding
      |
      v
OpenWrt Guest :80
      |
      v
LuCI / uhttpd

The forwarding rule is configured with:

hostfwd=tcp:127.0.0.1:8080-10.0.2.15:80

Binding to "127.0.0.1" keeps this published port restricted to the Android device's loopback interface under normal networking conditions.

⚙️ Configuration

The virtual machine can be customized by changing QEMU's command-line options.

Option| Purpose| Initial value
"-machine virt"| Select the virtual ARM machine| "virt"
"-cpu cortex-a57"| Select the virtual CPU model| Cortex-A57
"-m 512"| Allocate virtual RAM| 512 MB
"-smp 2"| Configure virtual CPUs| 2
"-nographic"| Use terminal-only output| Enabled
"hostfwd"| Forward the LuCI port| "8080 → 80"

Lower-memory configuration

To experiment with 256 MB of virtual RAM, change:

-m 512

to:

-m 256

A lower-memory configuration may reduce resource availability and can cause package installation or services to fail. It has not been established as a reliable configuration for every device.

Virtual CPU model

The configured CPU model is an emulated CPU model, not a direct mapping of the phone's physical processor.

Changing "-cpu" does not reproduce the exact MediaTek Helio G99 SoC, its hardware accelerators, or its power-management behavior.

💾 Persistence

The project currently uses an initramfs image, which is intended for temporary testing.

Changes made inside the guest may disappear when QEMU shuts down. Installing packages during a session does not guarantee that they will remain installed after the next boot.

Persistent virtual storage is a planned improvement.

Always back up any configuration you need to keep before stopping the virtual machine.

🛠️ Troubleshooting

QEMU package not found

Check the available packages:

pkg update
pkg search qemu

Install the package available in your Termux repository:

pkg install qemu-system-aarch64-headless

OpenWrt has no internet connection

Check the interface and routing table:

ip addr
ip route

Check the virtual gateway:

ping -c 3 10.0.2.2

If there is no default route, investigate the guest's network configuration.

"apk update" fails

Check connectivity first:

ping -c 3 10.0.2.2
ping -c 3 1.1.1.1

If the guest cannot reach the internet, fix networking before retrying package installation.

LuCI does not open

Inside OpenWrt:

ps | grep uhttpd

Restart the web server:

/etc/init.d/uhttpd restart

Also verify that the QEMU process is still running and that the port-forwarding option is present in its launch command.

The browser reports connection refused

Confirm that LuCI is installed, "uhttpd" is running, and the guest is listening on TCP port "80".

The host URL is:

http://127.0.0.1:8080

OpenWrt changes disappear after reboot

This is expected with the current temporary initramfs setup. Persistent virtual storage has not yet been implemented as part of the tested workflow.

⚠️ Limitations

- OpenWrt runs inside QEMU rather than directly on the phone's hardware.
- The virtual CPU is not an exact emulation of the MediaTek Helio G99.
- QEMU user-mode networking is not equivalent to a physical router's WAN/LAN interfaces.
- The virtual machine does not automatically manage the phone's physical Wi-Fi chipset.
- Performance depends on the Android device, available memory, thermal conditions, and emulation overhead.
- Hardware acceleration may be unavailable in the Termux environment.
- The initramfs-based workflow is temporary unless persistent storage is added.
- The project is experimental and has not been validated across a broad range of devices.

This project is intended for learning and experimentation, not as a guaranteed replacement for a dedicated router.

🗺️ Roadmap

- [x] Boot OpenWrt ARM64 on Android using QEMU.
- [x] Access LuCI from the Android browser.
- [x] Configure virtual networking.
- [ ] Develop a one-command installation script.
- [ ] Add start and stop helper scripts.
- [ ] Implement persistent virtual storage.
- [ ] Test 256 MB RAM configurations.
- [ ] Improve automated network diagnostics.
- [ ] Document additional Android device compatibility.
- [ ] Explore safe, reproducible router networking experiments.

🤝 Contributing

Contributions are welcome!

You can help by:

- Reporting bugs and unexpected behavior.
- Testing on additional Android devices.
- Improving installation instructions.
- Contributing scripts and documentation.
- Sharing verified configurations and performance observations.

When submitting an issue, include:

1. Device model and Android version.
2. Termux version.
3. QEMU version.
4. OpenWrt image version.
5. The command you executed.
6. Relevant error messages.

Please remove passwords, tokens, and private network details before sharing logs.

🔒 Security

- Set a strong root password before enabling remote administration.
- Keep the LuCI port bound to "127.0.0.1" unless external access is explicitly required.
- Do not expose the management interface to untrusted networks.
- Download OpenWrt images and packages from trusted sources.
- Review scripts before executing them with elevated privileges.

📜 License

This repository is intended to contain project-specific scripts and documentation. Add a "LICENSE" file before redistributing original project code.

OpenWrt and QEMU are separate upstream projects with their own licenses:

- "OpenWrt source code" (https://github.com/openwrt/openwrt)
- "QEMU source code" (https://github.com/qemu/qemu)

The license for this repository does not replace or override the licenses of third-party software.

❤️ Acknowledgements

- "OpenWrt" (https://openwrt.org/) for the router operating system.
- "QEMU" (https://www.qemu.org/) for system emulation.
- "Termux" (https://termux.dev/) for the Android terminal environment.

---

<p align="center">
  <strong>📱 OpenWRT on Your Phone!</strong>
  <br>
  <em>A tiny virtual router. A whole lot of possibilities.</em>
</p>
