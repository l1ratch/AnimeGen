![AnimeGen Banner](https://raw.githubusercontent.com/cranci1/AnimeGen/a1ea2503e6ea63c47130f89e027cda18f7d28c0a/Images/banner.jpeg)

<div align="center">

[![Build and Release IPA](https://github.com/cranci1/AnimeGen/actions/workflows/build%20copy.yml/badge.svg)](https://github.com/cranci1/AnimeGen/actions/workflows/build%20copy.yml)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%2016.0%2B-orange?logo=apple&logoColor=white)](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%2016.0%2B-red?logo=apple&logoColor=white)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Swift](https://img.shields.io/badge/Swift-5.0%20%7C%20SwiftUI-F05138?logo=swift&logoColor=white)](https://swift.org)

</div>

# AnimeGen

**AnimeGen** is a modern, fast, and feature-packed iOS & iPadOS application to discover, generate, view, and save high-resolution anime art and animated GIFs from public APIs.

---

## ✨ Features (v3.0+)

- 🎨 **Modern Liquid Glass UI**: Clean SwiftUI interface with dynamic ambient background glow, interactive gestures (swipe navigation, pinch-to-zoom up to 4x, double-tap to favorite).
- 🎬 **Hardware-Accelerated GIF Support**: Smooth 60 FPS playback for animated reaction GIFs and clips via Kingfisher.
- 📐 **Aspect Ratio & Scale Modes**:
  - Filter images by orientation: **Vertical (9:16)**, **Horizontal (16:9)**, or **Any (Mix)**.
  - Seamless toggle between **Fill Screen** (immersive wallpaper look) and **Fit Screen** (full uncropped illustration).
- 🔌 **Custom API Engine**: Easily connect any custom REST / JSON image API by providing an endpoint URL and JSON key path (`url`, `file_url`, `message`, `link`, etc.).
- 🌐 **Built-in Proxy Support**:
  - Full support for **HTTP, HTTPS, and SOCKS5** proxies.
  - Optional username & password authentication.
  - Live connection diagnostic tool (measures ping latency and resolves external IP).
- 🔞 **Optional 18+ (NSFW) Content Mode**:
  - Securely hidden by default with an age verification prompt (18+).
  - Unlocks Danbooru R-18, NekoBot Hentai, and PurrBot Adult GIFs.
- ❤️ **Favorites & Session History**: Save favorite artworks persistently to local storage and browse through your current session history with a grid gallery.
- 💾 **Photos & GIF Export**: Save high-res images and animated GIF files directly to your iOS Photos library or share via the native iOS Share Sheet.
- 🐞 **Debug Console & Diagnostics**: Built-in terminal with live API health checks (ping tests) and one-tap anonymous log sharing via Pastebin.

---

## 📸 Screenshots

*(Screenshots coming soon)*

---

## 📥 Download & Installation

You can install the compiled `.ipa` using **TrollStore**, **AltStore**, **SideStore**, **LiveContainer**, **Feather**, **Scarlet**, **ESign**, or **Sideloadly**.

- Download the latest IPA build from the [GitHub Actions Artifacts](https://github.com/cranci1/AnimeGen/actions) or Releases tab.

---

## 📡 Supported APIs

Special thanks to all the developers and communities providing these public APIs:

| API | Type | Format | Status |
| :--- | :---: | :---: | :---: |
| [nekos.best](https://nekos.best) | SFW | Image / GIF | ✅ Active |
| [pic.re](https://doc.pic.re/) | SFW | HD Image | ✅ Active |
| [waifu.pics](https://waifu.pics) | SFW | Animated GIF | ✅ Active |
| [nekobot.xyz](https://nekobot.xyz/) | SFW & 18+ | Image / GIF | ✅ Active |
| [nekosapi.com](https://nekosapi.com/) | SFW | HD Image | ✅ Active |
| [nekos.life](https://waifu.life) | SFW | Image / GIF | ✅ Active |
| [nekos.moe](https://nekos.moe/) | SFW | Image | ✅ Active |
| [purrbot.site](https://purrbot.site) | SFW & 18+ | Animated GIF | ✅ Active |
| [danbooru.donmai.us](https://danbooru.donmai.us) | SFW & 18+ | Image / GIF | ✅ Active |
| [waifu.im](https://docs.waifu.im/) | SFW | Image | ⚠️ Maintenance |

---

## 🛠️ Building from Source

1. Ensure you have **macOS** with **Xcode 14.0+** installed.
2. Clone the repository:
   ```bash
   git clone https://github.com/cranci1/AnimeGen.git
   cd AnimeGen
   ```
3. Build the project using Xcode or the automated shell script:
   ```bash
   chmod +x ./ipabuild.sh
   ./ipabuild.sh
   ```
   The compiled `.ipa` will be located inside the `AnimeGen/build` directory.

---

## 👥 Authors & Credits

- **[cranci](https://github.com/cranci1)** — Original creator and project maintainer (v1.x / v2.x).
- **[l1ratch](https://github.com/l1ratch)** — Modernized v3.x rewrite (SwiftUI architecture, Custom JSON API engine, Proxy & SOCKS5 support, NSFW mode, 60 FPS GIF renderer).

### Third-Party Dependencies
- **[Kingfisher](https://github.com/onevcat/Kingfisher)** — Used for asynchronous image downloading, caching, and animated GIF decoding (MIT License).

---

## 📄 License

```text
Copyright © 2023-2025 cranci
Copyright © 2026 l1ratch (v3.0+ contributions)

AnimeGen is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

AnimeGen is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with AnimeGen. If not, see <https://www.gnu.org/licenses/>.
```
