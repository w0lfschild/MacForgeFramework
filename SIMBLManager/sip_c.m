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

@interface sip_c ()

@end

@implementation sip_c

@synthesize confirm;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
//        NSURL* videoURL = [[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"sipvid" withExtension:@"mp4"];
//        self.video.player = [AVPlayer playerWithURL:videoURL];
    }
    return self;
}

- (void)awakeFromNib {
    NSURL* videoURL = [[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"sipvid" withExtension:@"mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    AVPlayerView *playerView = [[AVPlayerView alloc] initWithFrame:CGRectMake(50, 70, 500, 250)];
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

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (IBAction)iconfirm:(id)sender {
    NSLog(@"%@", NSStringFromRect(self.window.frame));
    [self close];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}
@end
