#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/SMAppService.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// Constants for UserDefaults keys
static NSString *const kLastVideoPathKey = @"LastVideoPath";
static NSString *const kRecentVideosKey = @"RecentVideos";
static NSString *const kIsMutedKey = @"IsMuted";
static NSString *const kStartAtLoginKey = @"StartAtLogin";
static const NSInteger kMaxRecentVideos = 10;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSMutableArray<NSWindow *> *windows;
@property(strong) AVQueuePlayer *player;
@property(strong) AVPlayerLooper *playerLooper;
@property(strong) NSMutableArray<AVPlayerLayer *> *playerLayers;
@property(strong) NSStatusItem *statusItem;
@property(assign) BOOL isVisible;
@property(strong) NSURL *currentVideoURL;

- (void)setupPlayerWithURL:(NSURL *)videoURL;
- (void)setupWindows;
- (void)updateRecentVideos:(NSURL *)videoURL;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  self.windows = [NSMutableArray array];
  self.playerLayers = [NSMutableArray array];

  [self setupMenuBar];
  [self syncLoginItemWithPreference];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleScreenChange:)
             name:NSApplicationDidChangeScreenParametersNotification
           object:nil];

  NSString *lastPath =
      [[NSUserDefaults standardUserDefaults] stringForKey:kLastVideoPathKey];
  if (lastPath && [[NSFileManager defaultManager] fileExistsAtPath:lastPath]) {
    [self loadVideo:[NSURL fileURLWithPath:lastPath]];
  } else {
    [self changeVideo:nil];
  }
}

- (void)handleScreenChange:(NSNotification *)notification {
  NSLog(@"[DesktopVideo DevLog] Mudança nos parâmetros de tela detectada. "
        @"Atualizando janelas.");
  if (self.currentVideoURL) {
    [self setupWindows];
  }
}

- (void)setupMenuBar {
  if (!self.statusItem) {
    self.statusItem = [[NSStatusBar systemStatusBar]
        statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"🎬";
  }

  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle:NSLocalizedString(@"Change Video...",
                                           @"Menu item to change video")
                  action:@selector(changeVideo:)
           keyEquivalent:@"n"];

  NSMenuItem *recentItem =
      [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Recent Videos", @"")
                                 action:nil
                          keyEquivalent:@""];
  recentItem.submenu = [[NSMenu alloc] init];
  [self updateRecentMenu:recentItem.submenu];
  [menu addItem:recentItem];

  [menu addItem:[NSMenuItem separatorItem]];

  NSMenuItem *muteItem = [[NSMenuItem alloc]
      initWithTitle:NSLocalizedString(@"Mute", @"Menu item to mute video")
             action:@selector(toggleMute:)
      keyEquivalent:@"m"];
  muteItem.state =
      [[NSUserDefaults standardUserDefaults] boolForKey:kIsMutedKey]
          ? NSControlStateValueOn
          : NSControlStateValueOff;
  [menu addItem:muteItem];

  NSMenuItem *loginItem = [[NSMenuItem alloc]
      initWithTitle:NSLocalizedString(@"Start at Login",
                                      @"Menu item to toggle start at login")
             action:@selector(toggleLoginItem:)
      keyEquivalent:@""];
  BOOL shouldStartAtLogin =
      [[NSUserDefaults standardUserDefaults] boolForKey:kStartAtLoginKey];
  loginItem.state =
      shouldStartAtLogin ? NSControlStateValueOn : NSControlStateValueOff;
  [menu addItem:loginItem];

  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:NSLocalizedString(@"Quit", @"Menu item to quit app")
                  action:@selector(terminateApp:)
           keyEquivalent:@"q"];
  self.statusItem.menu = menu;
}

- (void)updateRecentMenu:(NSMenu *)menu {
  [menu removeAllItems];
  NSArray *recents = [[NSUserDefaults standardUserDefaults]
      stringArrayForKey:kRecentVideosKey];
  if (!recents || recents.count == 0) {
    NSMenuItem *none =
        [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"None", @"")
                                   action:nil
                            keyEquivalent:@""];
    [none setEnabled:NO];
    [menu addItem:none];
    return;
  }

  for (NSString *path in recents) {
    NSString *name = [path lastPathComponent];
    NSMenuItem *item =
        [[NSMenuItem alloc] initWithTitle:name
                                   action:@selector(selectRecentVideo:)
                            keyEquivalent:@""];
    item.representedObject = path;
    [menu addItem:item];
  }
}

- (void)selectRecentVideo:(NSMenuItem *)sender {
  NSString *path = sender.representedObject;
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    [self loadVideo:[NSURL fileURLWithPath:path]];
  } else {
    NSLog(@"[DesktopVideo DevLog] Vídeo recente não encontrado: %@", path);
    [self removeRecentVideoPath:path];
  }
}

- (void)removeRecentVideoPath:(NSString *)path {
  NSMutableArray *recents = [[[NSUserDefaults standardUserDefaults]
      stringArrayForKey:kRecentVideosKey] mutableCopy];
  if (recents) {
    [recents removeObject:path];
    [[NSUserDefaults standardUserDefaults] setObject:recents
                                              forKey:kRecentVideosKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setupMenuBar]; // Refresh menu
  }
}

- (void)changeVideo:(id)sender {
  [NSApp activateIgnoringOtherApps:YES];
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.title =
      NSLocalizedString(@"Select a video", @"Title for the open panel");

  panel.allowedContentTypes = @[ UTTypeMovie ];

  if ([panel runModal] == NSModalResponseOK) {
    NSURL *videoURL = [[panel URLs] firstObject];
    [self loadVideo:videoURL];
  } else if (self.windows.count == 0) {
    [NSApp terminate:self];
  }
}

- (void)loadVideo:(NSURL *)videoURL {
  self.currentVideoURL = videoURL;
  [[NSUserDefaults standardUserDefaults] setObject:videoURL.path
                                            forKey:kLastVideoPathKey];
  [self updateRecentVideos:videoURL];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self setupPlayerWithURL:videoURL];

  // Refresh menu
  [self setupMenuBar];
}

- (void)updateRecentVideos:(NSURL *)videoURL {
  NSString *path = videoURL.path;
  NSMutableArray *recents = [[[NSUserDefaults standardUserDefaults]
      stringArrayForKey:kRecentVideosKey] mutableCopy];
  if (!recents)
    recents = [NSMutableArray array];

  [recents removeObject:path];
  [recents insertObject:path atIndex:0];

  if (recents.count > kMaxRecentVideos) {
    [recents removeLastObject];
  }

  [[NSUserDefaults standardUserDefaults] setObject:recents
                                            forKey:kRecentVideosKey];
}

- (void)toggleMute:(NSMenuItem *)sender {
  BOOL mute = (sender.state == NSControlStateValueOff);
  sender.state = mute ? NSControlStateValueOn : NSControlStateValueOff;
  self.player.muted = mute;
  [[NSUserDefaults standardUserDefaults] setBool:mute forKey:kIsMutedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupPlayerWithURL:(NSURL *)videoURL {
  AVAsset *asset = [AVAsset assetWithURL:videoURL];
  NSArray *keys = @[ @"playable", @"hasProtectedContent" ];

  [asset
      loadValuesAsynchronouslyForKeys:keys
                    completionHandler:^{
                      dispatch_async(dispatch_get_main_queue(), ^{
                        NSError *error = nil;
                        AVKeyValueStatus status =
                            [asset statusOfValueForKey:@"playable"
                                                 error:&error];

                        if (status == AVKeyValueStatusLoaded &&
                            asset.playable) {
                          [self finalizePlayerSetupWithAsset:asset
                                                    videoURL:videoURL];
                        } else {
                          NSLog(@"[DesktopVideo DevLog] Erro ao carregar "
                                @"vídeo: %@",
                                error.localizedDescription);
                          NSAlert *alert = [[NSAlert alloc] init];
                          alert.messageText =
                              NSLocalizedString(@"Video Error", @"");
                          alert.informativeText = [NSString
                              stringWithFormat:NSLocalizedString(
                                                   @"Could not play video: %@",
                                                   @""),
                                               videoURL.lastPathComponent];
                          [alert runModal];
                        }
                      });
                    }];
}

- (void)finalizePlayerSetupWithAsset:(AVAsset *)asset
                            videoURL:(NSURL *)videoURL {
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
  playerItem.preferredForwardBufferDuration = 1.0;
  playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = NO;

  if (!self.player) {
    self.player = [AVQueuePlayer queuePlayerWithItems:@[ playerItem ]];
    self.player.automaticallyWaitsToMinimizeStalling = NO;
  } else {
    [self.player removeAllItems];
    [self.player insertItem:playerItem afterItem:nil];
  }

  self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:self.player
                                                templateItem:playerItem];
  self.player.muted =
      [[NSUserDefaults standardUserDefaults] boolForKey:kIsMutedKey];
  [self.player play];
  self.isVisible = YES;
  [self setupWindows];
  NSLog(@"[DesktopVideo DevLog] Reprodução confirmada: %@",
        videoURL.lastPathComponent);
}

- (void)setupWindows {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  if (self.windows.count != [NSScreen screens].count) {
    for (NSWindow *win in self.windows)
      [win close];
    [self.windows removeAllObjects];
    [self.playerLayers removeAllObjects];

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
      [window setAnimationBehavior:NSWindowAnimationBehaviorNone];

      [[window contentView] setWantsLayer:YES];
      AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
      layer.actions = @{
        @"position" : [NSNull null],
        @"bounds" : [NSNull null],
        @"contents" : [NSNull null],
        @"sublayers" : [NSNull null]
      };

      [layer setFrame:[[window contentView] bounds]];
      [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
      [[[window contentView] layer] addSublayer:layer];

      [window makeKeyAndOrderFront:nil];
      [self.windows addObject:window];
      [self.playerLayers addObject:layer];

      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(checkVisibility)
                 name:NSWindowDidChangeOcclusionStateNotification
               object:window];
    }

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
           selector:@selector(handleSpaceChange)
               name:NSWorkspaceActiveSpaceDidChangeNotification
             object:nil];
  } else {
    NSArray *screens = [NSScreen screens];
    for (NSUInteger i = 0; i < screens.count; i++) {
      NSScreen *screen = screens[i];
      NSWindow *window = self.windows[i];
      AVPlayerLayer *layer = self.playerLayers[i];

      [window setFrame:screen.frame display:YES];
      [layer setFrame:[[window contentView] bounds]];
      layer.player = self.player;
    }
  }

  [CATransaction commit];
  NSLog(@"[DesktopVideo DevLog] Janelas atualizadas para %lu tela(s).",
        (unsigned long)self.windows.count);
}

- (void)handleSpaceChange {
  NSLog(@"[DesktopVideo DevLog] Espaço alterado (Space Change). Mantendo "
        @"reprodução.");
  if (!self.isVisible) {
    [self.player play];
    self.isVisible = YES;
  }
}

- (void)handleAppActivation:(NSNotification *)notification {
  NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
  NSLog(@"[DesktopVideo DevLog] App ativado: %@", app.localizedName);
}

- (void)checkVisibility {
  BOOL anyVisible = NO;
  for (NSWindow *win in self.windows) {
    if (win.occlusionState & NSWindowOcclusionStateVisible) {
      anyVisible = YES;
      break;
    }
  }

  if (anyVisible && !self.isVisible) {
    [self.player play];
    self.isVisible = YES;
    NSLog(@"[DesktopVideo DevLog] Vídeo retomado: Desktop visível.");
  } else if (!anyVisible && self.isVisible) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          BOOL stillHidden = YES;
          for (NSWindow *win in self.windows) {
            if (win.occlusionState & NSWindowOcclusionStateVisible) {
              stillHidden = NO;
              break;
            }
          }
          if (stillHidden && self.isVisible) {
            [self.player pause];
            self.isVisible = NO;
            NSLog(@"[DesktopVideo DevLog] Vídeo pausado: Desktop oculto "
                  @"(possível App em Tela Cheia).");
          }
        });
  }
}

- (void)addLegacyLoginItem {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *appPath = [[NSBundle mainBundle] bundlePath];
        NSString *bundleName =
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
                ?: @"MyDesktopVideo";
        NSString *source = [NSString
            stringWithFormat:@"tell application \"System Events\"\n"
                              "  if not (exists (login item \"%@\")) then\n"
                              "    make login item at end with properties "
                              "{path:\"%@\", hidden:false}\n"
                              "  end if\n"
                              "end tell",
                             bundleName, appPath];
        NSAppleScript *appleScript =
            [[NSAppleScript alloc] initWithSource:source];
        NSDictionary *error = nil;
        [appleScript executeAndReturnError:&error];
        if (error) {
          NSLog(@"[LoginItem] Erro ao adicionar item legado: %@", error);
        } else {
          NSLog(@"[LoginItem] Item legado adicionado com sucesso.");
        }
      });
}

- (void)removeLegacyLoginItem {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *bundleName =
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
                ?: @"MyDesktopVideo";
        NSString *source = [NSString
            stringWithFormat:@"tell application \"System Events\" to delete "
                             @"(every login item whose name is \"%@\")",
                             bundleName];
        NSAppleScript *appleScript =
            [[NSAppleScript alloc] initWithSource:source];
        [appleScript executeAndReturnError:nil];
      });
}

- (void)syncLoginItemWithPreference {
  BOOL shouldBeEnabled =
      [[NSUserDefaults standardUserDefaults] boolForKey:kStartAtLoginKey];

  if (@available(macOS 13.0, *)) {
    SMAppService *service = [SMAppService mainAppService];
    if (shouldBeEnabled) {
      if (service.status != SMAppServiceStatusEnabled) {
        NSError *error = nil;
        if (![service registerAndReturnError:&error]) {
          NSLog(@"[LoginItem] SMAppService falhou: %@",
                error.localizedDescription);
        }
      }
      [self addLegacyLoginItem];
    } else {
      if (service.status != SMAppServiceStatusNotRegistered) {
        NSError *error = nil;
        [service unregisterAndReturnError:&error];
      }
      [self removeLegacyLoginItem];
    }
  } else {
    if (shouldBeEnabled) {
      [self addLegacyLoginItem];
    } else {
      [self removeLegacyLoginItem];
    }
  }
}

- (void)toggleLoginItem:(NSMenuItem *)sender {
  BOOL enable = (sender.state == NSControlStateValueOff);

  [[NSUserDefaults standardUserDefaults] setBool:enable
                                          forKey:kStartAtLoginKey];
  [[NSUserDefaults standardUserDefaults] synchronize];

  sender.state = enable ? NSControlStateValueOn : NSControlStateValueOff;

  if (@available(macOS 13.0, *)) {
    SMAppService *service = [SMAppService mainAppService];
    if (enable) {
      NSError *error = nil;
      if (![service registerAndReturnError:&error]) {
        NSLog(@"[LoginItem] SMAppService falhou no toggle: %@",
              error.localizedDescription);
      }
      [self addLegacyLoginItem];
    } else {
      NSError *error = nil;
      [service unregisterAndReturnError:&error];
      [self removeLegacyLoginItem];
    }
  } else {
    if (enable) {
      [self addLegacyLoginItem];
    } else {
      [self removeLegacyLoginItem];
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
