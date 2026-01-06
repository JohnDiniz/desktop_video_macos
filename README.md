# MyDesktopVideo

[Português (Brasil)](#português-brasil) | [English (US)](#english-us)

---

## Português (Brasil)

Um aplicativo macOS leve que transforma qualquer vídeo em um papel de parede animado, funcionando diretamente da barra de menus.

### Funcionalidades

- **Papel de Parede Animado**: Reproduz vídeos em loop atrás dos ícones do desktop.
- **Persistência**: Lembra automaticamente do último vídeo selecionado ao reiniciar.
- **Multimonitor**: Suporte nativo para múltiplos monitores, sincronizando o vídeo em todas as telas.
- **Mudo/Som**: Opção para silenciar o vídeo com persistência de estado.
- **Auto-start**: Opção no menu para iniciar automaticamente ao fazer login no macOS.
- **Barra de Menus**: Controle total via ícone 🎬 na barra de menus, sem ícone no Dock.
- **Performance Otimizada**: Reuso de player, buffer curto e pausa automática para economizar CPU/GPU.

### Demonstração

[readme.mp4"](https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986)

> *Vídeo de demonstração.*

### Requisitos

- macOS 13.0 ou superior (para suporte ao `SMAppService`).
- `clang++` instalado (via Xcode Command Line Tools).

### Como Compilar

Para compilar o projeto e gerar o executável dentro do bundle `.app`, execute o seguinte comando no terminal:

```bash
clang++ -O3 -framework Cocoa -framework AVFoundation -framework AVKit -framework ServiceManagement -framework QuartzCore -o MyDesktopVideo.app/Contents/MacOS/MyDesktopVideo main.mm && codesign -s - MyDesktopVideo.app
```

### Como Rodar

Basta abrir o arquivo `MyDesktopVideo.app` ou executar diretamente via terminal:

```bash
open MyDesktopVideo.app
```

---

## English (US)

A lightweight macOS application that turns any video into an animated wallpaper, operating directly from the menu bar.

### Features

- **Animated Wallpaper**: Plays videos in a loop behind desktop icons.
- **Persistence**: Automatically remembers the last selected video on restart.
- **Multi-monitor**: Native support for multiple monitors, syncing video across all screens.
- **Mute/Sound**: Option to mute the video with state persistence.
- **Auto-start**: Menu option to automatically start upon macOS login.
- **Menu Bar**: Full control via the 🎬 icon in the menu bar, no Dock icon.
- **Optimized Performance**: Player reuse, short buffering, and auto-pause to save CPU/GPU.

### Demonstration

[readme.mp4"](https://github.com/user-attachments/assets/cb7cfe6b-78cc-41d0-b109-49e325934986)

> *Demonstration video.*

### Requirements

- macOS 13.0 or higher (for `SMAppService` support).
- `clang++` installed (via Xcode Command Line Tools).

### How to Compile

To compile the project and generate the executable inside the `.app` bundle, run the following command in the terminal:

```bash
clang++ -O3 -framework Cocoa -framework AVFoundation -framework AVKit -framework ServiceManagement -framework QuartzCore -o MyDesktopVideo.app/Contents/MacOS/MyDesktopVideo main.mm && codesign -s - MyDesktopVideo.app
```

### How to Run

Simply open the `MyDesktopVideo.app` file or run directly via terminal:

```bash
open MyDesktopVideo.app
```

### Project Structure

- `main.mm`: Main source code in Objective-C++.
- `MyDesktopVideo.app/`: macOS application bundle structure.
- `README.md`: This guide.
