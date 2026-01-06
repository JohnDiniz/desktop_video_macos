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
@property(strong) NSStatusItem *statusItem; // Item da Barra de Menus
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // NSApplicationActivationPolicyAccessory: Oculta o ícone do Dock e permite
  // rodar como app de fundo
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

  [self setupMenuBar];

  // Pergunta o primeiro vídeo ao iniciar
  [self changeVideo:nil];
}

- (void)setupMenuBar {
  // Cria o item na barra de menus (Status Bar)
  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  // Ícone simples (emoji ou símbolo de vídeo)
  self.statusItem.button.title = @"🎬";

  // Menu suspenso
  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle:@"Trocar Vídeo"
                  action:@selector(changeVideo:)
           keyEquivalent:@"n"];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Sair"
                  action:@selector(terminateApp:)
           keyEquivalent:@"q"];

  self.statusItem.menu = menu;
}

- (void)changeVideo:(id)sender {
  // Garante que o app possa mostrar o seletor (necessário para apps Accessory)
  [NSApp activateIgnoringOtherApps:YES];

  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setTitle:@"Selecione um vídeo para o fundo de tela"];
  [panel setCanChooseFiles:YES];
  [panel setCanChooseDirectories:NO];
  [panel setAllowsMultipleSelection:NO];
  [panel setAllowedFileTypes:@[ @"mp4", @"mov", @"m4v" ]];

  if ([panel runModal] == NSModalResponseOK) {
    NSURL *videoURL = [[panel URLs] firstObject];
    [self setupWindowAndPlayer:videoURL];
  } else if (!self.window) {
    // Se cancelou na primeira vez e não tem janela ativa, fecha o app
    NSLog(@"Nenhum vídeo selecionado ao iniciar. Encerrando.");
    [NSApp terminate:self];
  }
}

- (void)terminateApp:(id)sender {
  [NSApp terminate:self];
}

- (void)setupWindowAndPlayer:(NSURL *)videoURL {
  NSRect screenRect = [[NSScreen mainScreen] frame];

  // Se a janela ainda não existe, cria ela
  if (!self.window) {
    self.window =
        [[NSWindow alloc] initWithContentRect:screenRect
                                    styleMask:NSWindowStyleMaskBorderless
                                      backing:NSBackingStoreBuffered
                                        defer:NO];

    [self.window setBackgroundColor:[NSColor blackColor]];
    [self.window setLevel:kCGDesktopWindowLevel];
    [self.window
        setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces |
                              NSWindowCollectionBehaviorStationary];
    [self.window setIgnoresMouseEvents:YES];
    [[self.window contentView] setWantsLayer:YES];
  }

  // Para o vídeo anterior se houver
  if (self.player) {
    [self.player pause];
  }

  // Configuração do Player de Vídeo (AVFoundation)
  AVAsset *asset = [AVAsset assetWithURL:videoURL];
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];

  self.player = [AVQueuePlayer queuePlayerWithItems:@[ playerItem ]];
  self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:self.player
                                                templateItem:playerItem];

  // Se a layer já existe, remove ela antes de criar uma nova
  if (self.playerLayer) {
    [self.playerLayer removeFromSuperlayer];
  }

  self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  [self.playerLayer setFrame:screenRect];
  [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

  [[[self.window contentView] layer] addSublayer:self.playerLayer];

  [self.window makeKeyAndOrderFront:nil];
  [self.player play];
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
