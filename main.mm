#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

/**
 * DesktopVideoApp: Papel de parede animado com suporte a persistência,
 * múltiplos monitores e login automático.
 */

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSMutableArray<NSWindow *> *windows;
@property(strong) AVQueuePlayer *player;
@property(strong) AVPlayerLooper *playerLooper;
@property(strong) NSMutableArray<AVPlayerLayer *> *playerLayers;
@property(strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  self.windows = [NSMutableArray array];
  self.playerLayers = [NSMutableArray array];

  [self setupMenuBar];

  // Sincroniza o estado do Login Item com a preferência salva
  [self syncLoginItemWithPreference];

  // Tenta carregar o último vídeo salvo
  NSString *lastPath =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"LastVideoPath"];
  if (lastPath && [[NSFileManager defaultManager] fileExistsAtPath:lastPath]) {
    [self setupWindowsAndPlayer:[NSURL fileURLWithPath:lastPath]];
  } else {
    [self changeVideo:nil];
  }
}

- (void)setupMenuBar {
  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  // Ícone de sistema (emoji)
  self.statusItem.button.title = @"🎬";

  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle:@"Trocar Vídeo"
                  action:@selector(changeVideo:)
           keyEquivalent:@"n"];

  // Item para Mutar
  NSMenuItem *muteItem =
      [[NSMenuItem alloc] initWithTitle:@"Mudo"
                                 action:@selector(toggleMute:)
                          keyEquivalent:@"m"];
  muteItem.state = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsMuted"]
                       ? NSControlStateValueOn
                       : NSControlStateValueOff;
  [menu addItem:muteItem];

  // Item para Iniciar no Login (usa preferência salva como fonte da verdade)
  NSMenuItem *loginItem =
      [[NSMenuItem alloc] initWithTitle:@"Iniciar no Login"
                                 action:@selector(toggleLoginItem:)
                          keyEquivalent:@""];
  BOOL shouldStartAtLogin =
      [[NSUserDefaults standardUserDefaults] boolForKey:@"StartAtLogin"];
  loginItem.state =
      shouldStartAtLogin ? NSControlStateValueOn : NSControlStateValueOff;
  [menu addItem:loginItem];

  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Sair"
                  action:@selector(terminateApp:)
           keyEquivalent:@"q"];
  self.statusItem.menu = menu;
}

- (void)changeVideo:(id)sender {
  [NSApp activateIgnoringOtherApps:YES];
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setTitle:@"Selecione um vídeo"];
  [panel setAllowedFileTypes:@[ @"mp4", @"mov", @"m4v" ]];

  if ([panel runModal] == NSModalResponseOK) {
    NSURL *videoURL = [[panel URLs] firstObject];
    // Persiste a escolha
    [[NSUserDefaults standardUserDefaults] setObject:videoURL.path
                                              forKey:@"LastVideoPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setupWindowsAndPlayer:videoURL];
  } else if (self.windows.count == 0) {
    [NSApp terminate:self];
  }
}

- (void)toggleMute:(NSMenuItem *)sender {
  BOOL mute = (sender.state == NSControlStateValueOff);
  sender.state = mute ? NSControlStateValueOn : NSControlStateValueOff;
  self.player.muted = mute;
  [[NSUserDefaults standardUserDefaults] setBool:mute forKey:@"IsMuted"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupWindowsAndPlayer:(NSURL *)videoURL {
  // Limpa janelas e camadas antigas
  for (NSWindow *win in self.windows)
    [win close];
  [self.windows removeAllObjects];
  [self.playerLayers removeAllObjects];

  AVPlayerItem *playerItem =
      [AVPlayerItem playerItemWithAsset:[AVAsset assetWithURL:videoURL]];
  self.player = [AVQueuePlayer queuePlayerWithItems:@[ playerItem ]];
  self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:self.player
                                                templateItem:playerItem];

  // Aplica estado de mudo persistido
  self.player.muted =
      [[NSUserDefaults standardUserDefaults] boolForKey:@"IsMuted"];

  // Cria uma janela para cada monitor
  for (NSScreen *screen in [NSScreen screens]) {
    NSWindow *window =
        [[NSWindow alloc] initWithContentRect:screen.frame
                                    styleMask:NSWindowStyleMaskBorderless
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    [window setBackgroundColor:[NSColor blackColor]];
    [window setLevel:kCGDesktopWindowLevel];
    [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces |
                                  NSWindowCollectionBehaviorStationary];
    [window setIgnoresMouseEvents:YES];
    [[window contentView] setWantsLayer:YES];

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [layer setFrame:[[window contentView] bounds]];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [[[window contentView] layer] addSublayer:layer];

    [window makeKeyAndOrderFront:nil];
    [self.windows addObject:window];
    [self.playerLayers addObject:layer];
  }
  [self.player play];
}

- (void)syncLoginItemWithPreference {
  if (@available(macOS 13.0, *)) {
    BOOL shouldBeEnabled =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"StartAtLogin"];
    SMAppService *service = [SMAppService mainAppService];

    // Só tenta registrar se o status atual for diferente da preferência
    BOOL isCurrentlyEnabled = (service.status == SMAppServiceStatusEnabled);
    if (shouldBeEnabled != isCurrentlyEnabled) {
      if (shouldBeEnabled) {
        [service registerAndReturnError:nil];
      } else {
        [service unregisterAndReturnError:nil];
      }
    }
  }
}

- (void)toggleLoginItem:(NSMenuItem *)sender {
  BOOL enable = (sender.state == NSControlStateValueOff);

  // Salva a intenção do usuário imediatamente
  [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"StartAtLogin"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // Atualiza a UI imediatamente para parecer responsivo
  sender.state = enable ? NSControlStateValueOn : NSControlStateValueOff;

  // Tenta sincronizar com o sistema
  if (@available(macOS 13.0, *)) {
    SMAppService *service = [SMAppService mainAppService];
    NSError *error = nil;
    if (enable) {
      if (![service registerAndReturnError:&error]) {
        NSLog(@"Erro ao registrar login item: %@", error.localizedDescription);
      }
    } else {
      if (![service unregisterAndReturnError:&error]) {
        NSLog(@"Erro ao desregistrar login item: %@",
              error.localizedDescription);
      }
    }
  }
}

- (void)terminateApp:(id)sender {
  [NSApp terminate:self];
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
