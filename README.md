# MyDesktopVideo

🌐 **Language / Idioma**:
[🇧🇷 Português (Brasil)](#-português-brasil) • [🇺🇸 English (US)](#-english-us)

---

## 🎬 Overview

A lightweight, performance-focused macOS application that plays videos as animated desktop wallpapers, running behind all windows and controlled entirely from the menu bar.

---

## 🌐 Português (Brasil)

<details open>
<summary><strong>Descrição</strong></summary>

Um aplicativo macOS leve que transforma qualquer vídeo em um papel de parede animado, funcionando diretamente da barra de menus. Projetado com foco total em desempenho, simplicidade e integração nativa com o sistema.

</details>

### ✨ Funcionalidades

* **Papel de Parede Animado**: Reproduz vídeos em loop atrás dos ícones do desktop
* **Persistência**: Lembra automaticamente do último vídeo selecionado
* **Multimonitor**: Sincronização do vídeo em todas as telas
* **Mudo / Som**: Controle de áudio com persistência de estado
* **Auto-start**: Inicia automaticamente ao fazer login no macOS
* **Barra de Menus**: Controle total via ícone 🎬, sem aparecer no Dock
* **Performance Otimizada**:

  * Reuso de player
  * Buffer curto
  * Codec adequado
  * Pausa inteligente para economia de CPU/GPU

### ▶ Demonstração

[https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986](https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986)

> *Vídeo de demonstração.*

### 📦 Requisitos

* macOS 13.0 ou superior (`SMAppService`)
* `clang++` (Xcode Command Line Tools)

### 🛠 Como Compilar

```bash
clang++ -O3 \
  -framework Cocoa \
  -framework AVFoundation \
  -framework AVKit \
  -framework ServiceManagement \
  -framework QuartzCore \
  -o MyDesktopVideo.app/Contents/MacOS/MyDesktopVideo \
  main.mm && codesign -s - MyDesktopVideo.app
```

### ▶ Como Rodar

```bash
open MyDesktopVideo.app
```

---

## 🌐 English (US)

<details>
<summary><strong>Description</strong></summary>

A lightweight macOS application that turns any video into an animated desktop wallpaper, running behind all windows and fully controlled from the menu bar. Built with a strong focus on performance and native system integration.

</details>

### ✨ Features

* **Animated Wallpaper**: Looped video playback behind desktop icons
* **Persistence**: Remembers the last selected video on restart
* **Multi-monitor**: Native multi-display synchronization
* **Mute / Sound**: Audio toggle with state persistence
* **Auto-start**: Launches automatically on macOS login
* **Menu Bar Control**: 🎬 icon only, no Dock presence
* **Optimized Performance**:

  * Player reuse
  * Short buffering
  * Proper codec usage
  * Smart pause to reduce CPU/GPU usage

### ▶ Demonstration

[https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986](https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986)

> *Demonstration video.*

### 📦 Requirements

* macOS 13.0 or newer (`SMAppService` support)
* `clang++` (Xcode Command Line Tools)

### 🛠 How to Build

```bash
clang++ -O3 \
  -framework Cocoa \
  -framework AVFoundation \
  -framework AVKit \
  -framework ServiceManagement \
  -framework QuartzCore \
  -o MyDesktopVideo.app/Contents/MacOS/MyDesktopVideo \
  main.mm && codesign -s - MyDesktopVideo.app
```

### ▶ How to Run

```bash
open MyDesktopVideo.app
```

---

## 📁 Project Structure

* `main.mm` — Objective-C++ source code
* `MyDesktopVideo.app/` — macOS application bundle
* `README.md` — Project documentation

---

## 📜 License

MIT License
