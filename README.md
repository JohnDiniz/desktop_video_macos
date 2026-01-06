# MyDesktopVideo

Um aplicativo macOS leve que transforma qualquer vídeo em um papel de parede animado, funcionando diretamente da barra de menus.

## Funcionalidades

- **Papel de Parede Animado**: Reproduz vídeos em loop atrás dos ícones do desktop.
- **Persistência**: Lembra automaticamente do último vídeo selecionado ao reiniciar.
- **Multimonitor**: Suporte nativo para múltiplos monitores, sincronizando o vídeo em todas as telas.
- **Mudo/Som**: Opção para silenciar o vídeo com persistência de estado.
- **Auto-start**: Opção no menu para iniciar automaticamente ao fazer login no macOS.
- **Barra de Menus**: Controle total via ícone 🎬 na barra de menus, sem ícone no Dock.

## Requisitos

- macOS 13.0 ou superior (para suporte ao `SMAppService`).
- `clang++` instalado (via Xcode Command Line Tools).

## Como Compilar

Para compilar o projeto e gerar o executável dentro do bundle `.app`, execute o seguinte comando no terminal:

```bash
clang++ -O3 -framework Cocoa -framework AVFoundation -framework AVKit -framework ServiceManagement -o MyDesktopVideo.app/Contents/MacOS/MyDesktopVideo main.mm
```

## Como Rodar

Basta abrir o arquivo `MyDesktopVideo.app` ou executar diretamente via terminal:

```bash
open MyDesktopVideo.app
```

## Estrutura do Projeto

- `main.mm`: Código fonte principal em Objective-C++.
- `MyDesktopVideo.app/`: Estrutura do bundle da aplicação macOS.
- `README.md`: Este guia.
