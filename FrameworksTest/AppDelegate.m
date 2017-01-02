//
//  AppDelegate.m
//  SIMBLManagerTeast
//
//  Created by Wolfgang Baird on 6/16/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import SIMBLManager;
#import "AppDelegate.h"

@interface AppDelegate ()
{
}

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSImageView *status_SIM;
@property (weak) IBOutlet NSImageView *status_SIP;

@property (weak) IBOutlet NSButton *btn_SIMLoad;
@property (weak) IBOutlet NSButton *btn_SIPInject;

@property (weak) IBOutlet NSButton *btn_SIPToggle;
@property (weak) IBOutlet NSButton *btn_SIMToggle;

@end

@implementation AppDelegate

SIMBLManager *simMan;
sim_c *simc;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    simMan = [SIMBLManager sharedInstance];
    [self setupWindow];
    
    if (!simc) {
        simc = [[sim_c alloc] initWithWindowNibName:@"sim_c"];
    }
//    [simc showWindow:self];
    
//    CGRect dlframe = [[simc window] frame];
//    CGRect apframe = [self.window frame];
//    
//    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
//    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
//    
//    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
//    
//    [[simc cancel] setTarget:self];
//    [[simc cancel] setAction:@selector(cancelstuff)];
//    
//    [[simc accept] setTarget:self];
//    [[simc accept] setAction:@selector(toggleSIMBL:)];
//    
//    [[simc window] setFrame:dlframe display:true];
//    [self.window setLevel:NSFloatingWindowLevel];
//    [self.window addChildWindow:[simc window] ordered:NSWindowAbove];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)cancelstuff {
    [simc close];
//    [NSApp terminate:self];
}

- (void)setupWindow {
    if (![simMan OSAX_installed]) {
        [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    } else {
        if (false) {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        } else {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        }
    }
    
    if ([simMan SIP_enabled])
    {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
}

- (IBAction)installSIMBL:(id)sender {
    [simMan SIMBL_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)installOSAX:(id)sender {
    [simMan OSAX_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)installAgent:(id)sender {
    [simMan AGENT_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)removeSIMBL:(id)sender {
    [simMan SIMBL_remove];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}


@end
