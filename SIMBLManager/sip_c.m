//
//  sip_c.m
//  Frameworks
//
//  Created by Wolfgang Baird on 6/29/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

//#import "sip_c.h"
#import "SIMBLManager.h"
@import AVKit;
@import AVFoundation;
@import AppKit;

@interface sip_c ()
@property IBOutlet NSTextField *tv;
@property IBOutlet NSButton *confirmQuit;
@property IBOutlet NSButton *confirmReboot;
@end

@interface NoInteractPlayer : AVPlayerView

@end

@implementation NoInteractPlayer

- (void)scrollWheel:(NSEvent *)event {
    // Do nothing...
}

- (void)keyDown:(NSEvent *)event {
    // Do nothing...
}

@end

@implementation sip_c

@synthesize confirm;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib {
//    [[self window] setBackgroundColor:[NSColor whiteColor]];
    [[self window] setMovableByWindowBackground:true];
    [[self window] setLevel:NSFloatingWindowLevel];
    [[self window] setTitle:@""];
    [[self confirm] setKeyEquivalentModifierMask:0];
    [[self confirm] setKeyEquivalent:@"\r"];
    
    NSWindow *_window = [self window];
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_window setBackgroundColor:[NSColor whiteColor]];
    }
    [_window.contentView setWantsLayer:YES];
    
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    
    NSString *sipFile = @"eng_sip";
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion > 13) sipFile = @"eng_sip_mojave";
        
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[SIMBLManager class]]
                                        URLForResource:sipFile withExtension:@"txt"]
                                              encoding:NSUTF8StringEncoding
                                                 error:&err];
    text = [text stringByReplacingOccurrencesOfString:@"<appname>" withString:app];
    [_tv setStringValue:text];
    
    NSURL* videoURL = [[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"sipvid" withExtension:@"mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    player setresp
    
    NoInteractPlayer *playerView = [[NoInteractPlayer alloc] initWithFrame:CGRectMake(50, 70, 500, 250)];
    [[self.window contentView] addSubview:playerView];
    
    [playerView setControlsStyle:AVPlayerViewControlsStyleNone];
    
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    
    playerLayer.frame = playerView.bounds;
    [playerView.layer addSublayer:playerLayer];
    
    [player play];
}

- (void)addtoView:(NSView*)parentView {
    NSView *t = self.window.contentView;
    [t setFrameOrigin:NSMakePoint(
                                        (NSWidth([parentView bounds]) - NSWidth([t frame])) / 2,
                                        (NSHeight([parentView bounds]) - NSHeight([t frame])) / 2
                                        )];
    [t setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
    [parentView addSubview:t];
    [self close];
}

- (void)displayInWindow:(NSWindow*)window {
    NSWindow *simblWindow = self.window;
    NSPoint childOrigin = window.frame.origin;
    childOrigin.y += window.frame.size.height/2 - simblWindow.frame.size.height/2;
    childOrigin.x += window.frame.size.width/2 - simblWindow.frame.size.width/2;
    [window addChildWindow:simblWindow ordered:NSWindowAbove];
    [simblWindow setFrameOrigin:childOrigin];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:CMTimeMake(0, p.asset.duration.timescale)];
}

- (IBAction)reboot:(id)sender {
    system("osascript -e 'tell application \"Finder\" to restart'");
}

- (IBAction)iconfirm:(id)sender {
    [self close];
}
    
- (IBAction)confirmQuit:(id)sender {
    [self close];
    [NSApp terminate:nil];
}
    
- (void)windowDidLoad {
    [super windowDidLoad];
}
    
@end
