# swcursor-autoset

Small helper to automatically enable or remove a software cursor X11 config on
Raspberry Pi devices that use certain Waveshare displays. The script inspects
the device boot config and writes or removes an X11 snippet (`20-swcursor.conf`)
in `/etc/X11/xorg.conf.d/` to enable `SWcursor` when a rotation/overlay match is
detected.

---

## 📌 Purpose

- Detect compatible Waveshare panel + rotation in the boot `config.txt` and
  included configs then enable a software cursor in the X server when required.
- Remove the generated X11 config when the matching overlay/rotation is not
  present or when explicitly requested.

---

## 📌 Features

- Auto-detects `dtoverlay=vc4-kms-dsi-waveshare-panel` together with
  `rotation=180` in the boot config and writes an X11 Device section enabling
  `Option "SWcursor" "on"`.
- Removes the X11 snippet when no matching overlay/rotation is found.

---

## 🧰 Dependencies

The script expects a Debian/Raspbian-style environment and checks for these
runtime packages (declared in the script's `aptpaks` array):

- `xserver-xorg-core`
- `xserver-xorg-input-all`

It also expects a boot config at `/boot/config.txt` or `/boot/firmware/config.txt`.

---

## 📁 Installation

### Install via package (.deb)

Install the provided package if available. The package should place
the script into a system path and optionally provide packaging hooks.

```bash
wget https://github.com/aragon25/swcursor-autoset/releases/download/v1.0-1/swcursor-autoset_1.0-1_all.deb
sudo apt install ./swcursor-autoset_1.0-1_all.deb
```

---

## 📂 Files of interest

- `src/swcursor-autoset.sh` — main script implementing detection and write/remove behavior.
- `/etc/X11/xorg.conf.d/20-swcursor.conf` — target file written when a match
  is detected (created by the script).

---

## ⚠️ Safety & recommendations

- The script requires `root` privileges and writes to `/etc/X11/`; test on a
  disposable device or VM before running on production systems.
- Back up your current X11 configuration before using the script:

```bash
sudo cp -a /etc/X11/xorg.conf.d /etc/X11/xorg.conf.d.bak
```

- If your system uses a different display stack or Wayland, this script may not
  have any effect — verify your environment.

