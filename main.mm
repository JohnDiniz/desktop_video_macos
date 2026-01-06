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

  // Item para Iniciar no Login
  NSMenuItem *loginItem =
      [[NSMenuItem alloc] initWithTitle:@"Iniciar no Login"
                                 action:@selector(toggleLoginItem:)
                          keyEquivalent:@""];
  loginItem.state = [self isLoginItemEnabled] ? NSControlStateValueOn
                                              : NSControlStateValueOff;
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

- (void)toggleLoginItem:(NSMenuItem *)sender {
  BOOL enable = (sender.state == NSControlStateValueOff);
  if (@available(macOS 13.0, *)) {
    SMAppService *service = [SMAppService mainAppService];
    NSError *error = nil;
    if (enable) {
      [service registerAndReturnError:&error];
    } else {
      [service unregisterAndReturnError:&error];
    }
  }
  sender.state = enable ? NSControlStateValueOn : NSControlStateValueOff;
}

- (BOOL)isLoginItemEnabled {
  if (@available(macOS 13.0, *)) {
    return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
  }
  return NO;
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
