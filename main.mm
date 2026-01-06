#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Cocoa/Cocoa.h>

/**
 * DesktopVideoApp: Um exemplo de papel de parede animado para macOS.
 * Este aplicativo demonstra como criar uma janela em tela cheia que fica
 * atrás de todos os ícones e janelas, reproduzindo um vídeo em loop.
 */

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSWindow *window;
@property(strong) AVQueuePlayer *player;
@property(strong) AVPlayerLooper *playerLooper;
@property(strong) AVPlayerLayer *playerLayer;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Garante que o app tenha foco e possa exibir janelas de interface (como o
  // seletor de arquivos)
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSApp activateIgnoringOtherApps:YES];

  // 1. Seleção do arquivo de vídeo usando NSOpenPanel
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setTitle:@"Selecione um vídeo para o fundo de tela"];
  [panel setCanChooseFiles:YES];
  [panel setCanChooseDirectories:NO];
  [panel setAllowsMultipleSelection:NO];
  [panel setAllowedFileTypes:@[ @"mp4", @"mov", @"m4v" ]];

  if ([panel runModal] == NSModalResponseOK) {
    NSURL *videoURL = [[panel URLs] firstObject];
    [self setupWindowAndPlayer:videoURL];
  } else {
    NSLog(@"Nenhum vídeo selecionado. O aplicativo será encerrado.");
    [NSApp terminate:self];
  }
}

- (void)setupWindowAndPlayer:(NSURL *)videoURL {
  // 2. Configuração da Janela
  NSRect screenRect = [[NSScreen mainScreen] frame];

  // NSWindowStyleMaskBorderless: Janela sem bordas ou botões de controle
  self.window =
      [[NSWindow alloc] initWithContentRect:screenRect
                                  styleMask:NSWindowStyleMaskBorderless
                                    backing:NSBackingStoreBuffered
                                      defer:NO];

  [self.window setBackgroundColor:[NSColor blackColor]];

  // kCGDesktopWindowLevel: Coloca a janela no nível do desktop (atrás de tudo)
  [self.window setLevel:kCGDesktopWindowLevel];

  // NSWindowCollectionBehaviorCanJoinAllSpaces: Garante que apareça em todos os
  // Spaces/Desktops
  [self.window
      setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces |
                            NSWindowCollectionBehaviorStationary];

  // Ignorar eventos de mouse (cliques passam através da janela)
  [self.window setIgnoresMouseEvents:YES];

  // 3. Configuração do Player de Vídeo (AVFoundation)
  AVAsset *asset = [AVAsset assetWithURL:videoURL];
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];

  // AVQueuePlayer + AVPlayerLooper para um loop perfeito e performático
  self.player = [AVQueuePlayer queuePlayerWithItems:@[ playerItem ]];
  self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:self.player
                                                templateItem:playerItem];

  // AVPlayerLayer: A camada que renderiza o vídeo
  self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  [self.playerLayer setFrame:screenRect];
  [self.playerLayer
      setVideoGravity:AVLayerVideoGravityResizeAspectFill]; // Preenche a tela

  // Adiciona a camada de vídeo à view da janela
  [[self.window contentView] setWantsLayer:YES];
  [[[self.window contentView] layer] addSublayer:self.playerLayer];

  // Mostra a janela e inicia a reprodução
  [self.window makeKeyAndOrderFront:nil];
  [self.player play];

  // Após selecionar o vídeo, podemos voltar para o modo "Accessory" se
  // quisermos que ele não apareça no Dock/Cmd+Tab, mas como o foco é o papel de
  // parede, vamos manter simples.
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  return YES;
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [app setDelegate:delegate];
    [app run];
  }
  return 0;
}
