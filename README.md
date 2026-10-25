# 📱 OpenWRT on Your Phone!
<p align="center">
<strong>Run OpenWrt on your Android phone with QEMU.</strong>


<em>No firmware flashing. No bootloader unlocking. Just a virtual router in your pocket.</em>
</p>
<p align="center">
<img src="[https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)" alt="Android">
<img src="[https://img.shields.io/badge/Virtualization-QEMU-blue?style=for-the-badge](https://img.shields.io/badge/Virtualization-QEMU-blue?style=for-the-badge)" alt="QEMU">
<img src="[https://img.shields.io/badge/Guest-OpenWrt-00A3E0?style=for-the-badge](https://img.shields.io/badge/Guest-OpenWrt-00A3E0?style=for-the-badge)" alt="OpenWrt">
<img src="[https://img.shields.io/badge/Architecture-ARM64-orange?style=for-the-badge](https://img.shields.io/badge/Architecture-ARM64-orange?style=for-the-badge)" alt="ARM64">
<img src="[https://img.shields.io/badge/Status-Experimental-yellow?style=for-the-badge](https://img.shields.io/badge/Status-Experimental-yellow?style=for-the-badge)" alt="Experimental">
</p>
<p align="center">
<strong>Explore OpenWrt. Test LuCI. Experiment with networking. All from your phone.</strong>
</p>
📖 Table of Contents
 * ✨ About
 * 🚀 Features
 * 📱 Tested Device
 * 🧰 Requirements
 * ⚡ Quick Start
 * 🌐 Access LuCI
 * ⚙️ Configuration
 * 💾 Persistence
 * 🛠️ Troubleshooting
 * ⚠️ Limitations
 * 🗺️ Roadmap
 * 🤝 Contributing
 * 🔒 Security
 * 📜 License
 * ❤️ Acknowledgements
✨ About
OpenWRT on Your Phone! is an experimental project that runs the OpenWrt router operating system inside a QEMU virtual machine on Android.
The project uses Termux as the host environment and QEMU system emulation to boot an ARM64 OpenWrt image. Once the virtual machine is running, users can access LuCI, the OpenWrt web interface, directly from their Android browser.
The goal is simple: make OpenWrt experimentation more accessible without replacing Android or flashing router firmware.
> [!NOTE]
> This project runs OpenWrt inside Android via emulation. It does not replace the phone's operating system.
> 
🚀 Features
 * 📱 Native Execution: Run OpenWrt directly on Android through Termux.
 * ⚡ One-Command Setup: Automated setup, dependency installation, and launch script.
 * 🖥️ Virtual Architecture: Boot an ARM64 OpenWrt image with QEMU.
 * 🌐 Web Management: Access LuCI directly from your phone's mobile browser.
 * 🔌 Isolated Network: Utilize QEMU user-mode networking with internal NAT.
 * 🧠 Resource Control: Configure virtual RAM and CPU resource allocation dynamically.
 * 🧪 Package Ecosystem: Experiment with OpenWrt packages and router settings.
 * 🛡️ Zero-Risk Environment: Keep the host Android system and bootloader untouched.
 * 🧰 PC-Free: Completely standalone mobile terminal workflow.
📱 Tested Device
| Component | Configuration |
|---|---|
| Device | Samsung Galaxy A24 |
| Host OS | Android |
| Host Environment | Termux |
| Emulator | QEMU System (qemu-system-aarch64) |
| Guest OS | OpenWrt 25.12.6 |
| Guest Target | armsr/armv8 |
| Architecture | ARM64 |
| Web Interface | LuCI |
| Networking | QEMU user-mode NAT |
| Test Status | Boots successfully; LuCI fully accessible |
> [!TIP]
> The project was verified on a Samsung Galaxy A24. Other 64-bit ARM Android devices should work with minor performance differences depending on SoC thermal throttling.
> 
🧰 Requirements
Before getting started, make sure you have:
 * An Android phone with an ARM64 (aarch64) processor.
 * Termux (installed via F-Droid or GitHub Releases, not Google Play Store).
 * An active internet connection.
 * At least 1.5 GB of free internal storage.
 * Sufficient free RAM (minimum 3 GB total physical RAM recommended).
⚡ Quick Start
Open Termux and run this single command to download dependencies, set up the environment, and boot OpenWrt:
bash <(curl -fsSL "https://raw.githubusercontent.com/nonamebrub-max/OpenWRT-on-Your-Phone-/main/install.sh")

The script will automatically:
 * Update repositories and install required packages (qemu, wget, curl).
 * Download the compatible OpenWrt ARM64 image.
 * Launch the QEMU virtual machine with port forwarding ready.
Once boot logs complete, press Enter to open the OpenWrt console.
🌐 Access LuCI
After the virtual machine finishes booting and LuCI is started, open Chrome or any browser on your Android device:
👉 [http://127.0.0.1:8080](http://127.0.0.1:8080)
 * Username: root
 * Password: The password configured inside OpenWrt via passwd
Traffic is routed through QEMU user-mode networking:
Android Browser
      │
      │ http://127.0.0.1:8080
      ▼
QEMU Port Forwarding (Host)
      │
      ▼
OpenWrt Guest (:80)
      │
      ▼
LuCI / uhttpd Daemon

⚙️ Configuration
The VM defaults to 512 MB virtual RAM and 2 virtual CPUs.
| Option | Purpose | Default Value |
|---|---|---|
| -machine virt | Virtual generic ARM machine platform | virt |
| -cpu cortex-a57 | Virtualized ARM CPU model | cortex-a57 |
| -m 512 | Allocated virtual RAM | 512 (MB) |
| -smp 2 | Virtual CPU cores | 2 |
| -nographic | Headless serial I/O console | Enabled |
| hostfwd | Port forwarding definition | 8080 -> 80 |
Low-Memory Mode
For devices with limited RAM, edit the run parameters to:
-m 256

> [!WARNING]
> Running with 256 MB RAM limits package installations and may trigger the kernel out-of-memory (OOM) killer during heavy service loads.
> 
💾 Persistence
> [!WARNING]
> This baseline setup uses an initramfs image that runs entirely in RAM. All installed packages and custom configs will reset when the QEMU process exits.
> 
Persistent storage backing (qemu-img with an ext4/squashfs rootfs disk image) is planned for upcoming milestones. Back up your UCI configurations before terminating Termux:
sysupgrade -b /tmp/backup.tar.gz

🛠️ Troubleshooting
<details>
<summary><strong>curl: command not found or repository errors</strong></summary>
Ensure Termux repositories are up-to-date and install curl manually:
pkg update && pkg install curl -y

Then re-run the one-liner command.
</details>
<details>
<summary><strong>OpenWrt has no internet connection inside the VM</strong></summary>
Check default routes and DNS inside the OpenWrt console:
ip route
ping -c 3 10.0.2.2

If the virtual gateway is unreachable, check whether Android battery optimization is restricting Termux background networking.
</details>
<details>
<summary><strong>LuCI / Web Interface returns "Connection Refused"</strong></summary>
Verify that uhttpd is running and listening on port 80 inside OpenWrt:
ps | grep uhttpd
/etc/init.d/uhttpd restart

Ensure the QEMU process in Termux has not been killed by Android's low memory killer (LMK).
</details>
<details>
<summary><strong>Changes lost after reboot</strong></summary>
Expected behavior when booting an initramfs image directly without a secondary persistent block storage device.
</details>
⚠️ Limitations
 * Runs under user-space emulation (virtio/emulated ARM), not bare-metal virtualization (KVM is not exposed on stock Android kernels).
 * QEMU user networking runs behind an internal NAT; it does not bridge directly to the phone's physical Wi-Fi or cellular interfaces.
 * Emulation performance is CPU-bound and subject to thermal throttling on mobile SoCs.
 * Physical Wi-Fi AP / hotspot routing using the phone's physical Wi-Fi hardware is not supported from inside the guest.
🗺️ Roadmap
 * [x] Boot OpenWrt ARM64 on Android using QEMU.
 * [x] Access LuCI from the Android browser.
 * [x] Configure virtual user networking.
 * [x] Automated one-command installation script (install.sh).
 * [ ] Add start and stop helper scripts.
 * [ ] Implement persistent storage backing via secondary virtual disk.
 * [ ] Validate 256 MB low-spec profiles.
 * [ ] Add ADB USB-tethering passthrough guide.
🤝 Contributing
Contributions, issues, and feature requests are welcome!
When submitting an issue, please include:
 * Device model and Android version.
 * Termux version and installation source.
 * Terminal error messages or log traces.
🔒 Security
 * Set a strong root password immediately after boot via passwd.
 * Keep hostfwd bound to 127.0.0.1 unless external access from your local network is explicitly required.
 * Download OpenWrt images only from official upstream repositories.
📜 License
Project scripts and documentation are licensed under the MIT License.
Upstream dependencies:
 * OpenWrt (GPL-2.0)
 * QEMU (GPL-2.0)
 * Termux (GPL-3.0)
❤️ Acknowledgements
 * The OpenWrt Project for the modular embedded Linux router distribution.
 * The QEMU Project for multi-architecture machine emulation.
 * The Termux Team for bringing a powerful Linux environment to Android.
<p align="center">
<strong>📱 OpenWRT on Your Phone!</strong>


<em>A tiny virtual router. A whole lot of possibilities.</em>
</p>
