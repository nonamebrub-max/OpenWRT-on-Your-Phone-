# 📱 OpenWRT on Your Phone!

Run OpenWrt on your Android phone using QEMU. No flashing. No bootloader unlocking required.

OpenWRT on Your Phone is an experimental project that brings the OpenWrt router operating system to Android devices through QEMU system emulation.

The goal is to make it easy to explore OpenWrt, experiment with router configurations, and access LuCI, the OpenWrt web interface, directly from a phone.

«🚧 Experimental project: This project runs OpenWrt inside a virtual machine. It does not replace Android or turn the phone's physical Wi-Fi interface into an OpenWrt-managed radio.»

✨ Features

- 📱 Run OpenWrt on Android using Termux.
- 🖥️ Emulate an ARM64 virtual machine with QEMU.
- 🌐 Access the LuCI web interface from your phone's browser.
- 🔌 Provide virtual networking through QEMU user-mode networking.
- 🧠 Configure virtual RAM and CPU settings.
- 🛡️ Experiment without flashing firmware or modifying Android partitions.

🧰 Requirements

- An Android phone with an ARM64 processor.
- "Termux" (https://github.com/termux/termux-app)
- An internet connection.
- Sufficient free storage and memory.
- Basic familiarity with Linux commands.

Test device: Samsung Galaxy A24
Host OS: Android
Virtualization: QEMU system emulation
Guest OS: OpenWrt 25.12.6
Guest architecture: ARM64 ("armsr/armv8")
Web interface: LuCI

The project was initially tested on a Samsung Galaxy A24. Other Android devices may work, but compatibility and performance have not been verified.

🚀 Installation

1. Install the required packages

Open Termux and run:

pkg update
pkg install qemu-system-aarch64-headless wget curl tar

If your Termux repository uses a different package configuration, check available packages with:

pkg search qemu

2. Download OpenWrt

Create a working directory:

mkdir -p ~/openwrt-vm
cd ~/openwrt-vm

Download the OpenWrt ARM64 initramfs image:

wget -c https://downloads.openwrt.org/releases/25.12.6/targets/armsr/armv8/openwrt-25.12.6-armsr-armv8-generic-initramfs-kernel.bin

Official download directory:

https://downloads.openwrt.org/releases/25.12.6/targets/armsr/armv8/

3. Start the virtual machine

Run the following command in Termux:

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

This configuration allocates 512 MB of RAM and two virtual CPUs.

Wait for OpenWrt to finish booting. The console should display the OpenWrt login prompt.

«Note: The command above is the initial experimental configuration. The guest network must be configured correctly before package installation and LuCI access will work.»

4. Configure the virtual network

At the OpenWrt console, configure the LAN interface to use DHCP for QEMU's virtual network:

uci set network.lan.proto='dhcp'
uci commit network
/etc/init.d/network restart

Check the network configuration:

ip addr
ip route

The expected address is "10.0.2.15", with a default gateway of "10.0.2.2".

If the network configuration does not work, inspect the bridge and interface configuration before proceeding.

5. Install LuCI

Once internet connectivity is available inside the guest:

apk update
apk add luci

Set the root password:

passwd

Enable and restart the web server:

/etc/init.d/uhttpd enable
/etc/init.d/uhttpd restart

6. Open LuCI

Open your browser on the same Android phone:

http://127.0.0.1:8080

Log in with username "root" and the password you configured.

If the page does not load, verify that QEMU is running, "uhttpd" is active, and the guest is listening on port 80.

⚙️ Virtual Machine Configuration

Setting| Value
Emulator| QEMU
Machine type| "virt"
Guest architecture| ARM64
Initial CPU model| Cortex-A57
Initial RAM| 512 MB
Initial virtual CPUs| 2
Network mode| User-mode NAT
LuCI host port| "8080"
LuCI guest port| "80"

These are virtual hardware settings, not a direct representation of the phone's physical hardware.

CPU models and RAM allocation can be changed experimentally. Lower RAM settings may reduce memory usage but can also cause package installation or services to fail.

💾 Persistence

The initramfs setup is intended for temporary experiments. Changes made inside the guest may be lost when the virtual machine shuts down.

Persistent storage using a virtual disk is a planned improvement. Do not assume configurations survive a restart unless persistent storage has been configured and tested.

⚠️ Limitations

- QEMU emulates a virtual machine; it does not run OpenWrt natively on the phone.
- The virtual CPU does not reproduce the exact MediaTek Helio G99 hardware.
- QEMU user-mode networking is not equivalent to a physical router WAN/LAN setup.
- The virtual machine does not automatically control the phone's Wi-Fi chipset.
- Performance depends on the phone, Android version, thermal conditions, and QEMU configuration.
- Hardware acceleration may not be available in the Android environment.
- The initial configuration is experimental and may require adjustments on different devices.

🗺️ Roadmap

- [x] Boot OpenWrt ARM64 on Android using QEMU.
- [x] Access LuCI from the phone's browser.
- [x] Establish virtual networking.
- [ ] Test lower-memory configurations.
- [ ] Add persistent virtual storage.
- [ ] Provide start and stop scripts.
- [ ] Improve networking diagnostics.
- [ ] Document compatibility with additional Android devices.

🤝 Contributing

Contributions, bug reports, tested configurations, and documentation improvements are welcome.

When reporting a problem, include:

- Android device and Android version.
- Termux version.
- QEMU version.
- OpenWrt image version.
- The exact command used.
- Relevant error messages.

Please do not submit private information, passwords, or sensitive network configurations.

📜 License

This project does not redistribute OpenWrt firmware binaries.

OpenWrt and QEMU are separate projects governed by their respective licenses. See their official repositories and documentation for licensing information.

- "OpenWrt" (https://github.com/openwrt/openwrt)
- "QEMU" (https://github.com/qemu/qemu)

A project-specific license should be added before redistributing original scripts or other project code.

---

Made for experimenting with OpenWrt, right from your phone. 📱🌐
