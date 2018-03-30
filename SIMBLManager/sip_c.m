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
    [[self window] setBackgroundColor:[NSColor whiteColor]];
    [[self window] setMovableByWindowBackground:true];
    [[self window] setLevel:NSFloatingWindowLevel];
    [[self window] setTitle:@""];
    [[self confirm] setKeyEquivalent:@"\r"];
    
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"eng_sip" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:&err];
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
