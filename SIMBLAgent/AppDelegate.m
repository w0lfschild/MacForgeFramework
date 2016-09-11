//
//  AppDelegate.m
//  SIMBLAgent
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "SIMBL.h"
#import "AppDelegate.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import <Carbon/Carbon.h>

AppDelegate* this;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    this = self;
    NSProcessInfo* procInfo = [NSProcessInfo processInfo];
    if ([(NSString*)procInfo.arguments.lastObject hasPrefix:@"-psn"])
    {
        // if we were started interactively, load in launchd and terminate
        SIMBLLogNotice(@"installing into launchd");
        [self loadInLaunchd];
        [NSApp terminate:nil];
    }
    else
    {
        SIMBLLogInfo(@"agent started");
        
        /* Start watching for application launches */
        [self watchForApplications];
        
        /* Load into apps that existed before we started looking launches */
        [self injectIntoAnchients];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)injectIntoAnchients {
    /* Do this async because it's bound to be slow */
    /* Lets only try apps because that seems smart */
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
        if ([app.bundleURL.pathExtension isEqualToString:@"app"])
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self injectSIMBL:app]; });
}

- (void)applescriptInject:(NSRunningApplication*)runningApp {
    // Using applescript seems to work even though it's slow
    if ([runningApp.localizedName isEqualToString:@"Google Chrome Helper"])
        return;
    
    NSDictionary* errorDict;
    NSString *applescript =  [NSString stringWithFormat:@"\
                              set doesExist to false\n\
                              set appname to \"nill\"\n\
                              try\n\
                                tell application \"Finder\"\n\
                                    set appname to name of application file id \"%@\"\n\
                                    set doesExist to true\n\
                                end tell\n\
                              on error err_msg number err_num\n\
                                return 0\n\
                              end try\n\
                              if doesExist then\n\
                                tell application appname to inject SIMBL into Snow Leopard\n\
                                return appname\n\
                              end if", runningApp.bundleIdentifier];
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:applescript];
    if ([[[NSWorkspace sharedWorkspace] runningApplications] containsObject:runningApp])
        [scriptObject executeAndReturnError:&errorDict];
}

- (void)injectSIMBL:(NSRunningApplication*)runningApp {
    // Don't inject into self, osascript, jank
    if ([runningApp.localizedName isEqualToString:@"SIMBLAgent"]) return;
    if ([runningApp.localizedName isEqualToString:@"osascript"]) return;
    if (!runningApp.executableURL.path.length) return;
    
    // NOTE: if you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString* appName = runningApp.localizedName;
    SIMBLLogInfo(@"%@ started", appName);
    SIMBLLogDebug(@"app start notification: %@", runningApp);
    
    // Check to see if there are plugins to load
    if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return;
    
    // Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil &&
        [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return;
    }
    
    SIMBLLogDebug(@"send inject event");
    
    // Abort you're running something other than macOS 10.X.X
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion);
        return;
    }
    
    // System item Inject!
    if ([[runningApp.executableURL.path pathComponents] count] > 0)
    {
        if ([[[runningApp.executableURL.path pathComponents] objectAtIndex:1] isEqualToString:@"System"])
        {
            [self applescriptInject:runningApp];
            return;
        }
    }
    
    int pid = [runningApp processIdentifier];
    NSAppleEventDescriptor *app = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
//    NSAppleEventDescriptor *app = [NSAppleEventDescriptor descriptorWithBundleIdentifier:runningApp.bundleIdentifier];
    NSAppleEventDescriptor *ae;
    OSStatus err;
    
    ae = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
                                                  eventID:kGetAEUT
                                         targetDescriptor:app
                                                 returnID:kAutoGenerateReturnID
                                            transactionID:kAnyTransactionID];
    err = AESendMessage([ae aeDesc], NULL, kAEWaitReply | kAENeverInteract, kAEDontRecord);
    
    ae = [NSAppleEventDescriptor appleEventWithEventClass:'SIMe'
                                                  eventID:'load'
                                         targetDescriptor:app
                                                 returnID:kAutoGenerateReturnID
                                            transactionID:kAnyTransactionID];
    err = AESendMessage([ae aeDesc], NULL, kAENoReply | kAENeverInteract, kAEDontRecord);
    
    if ((int)err != 0)
    {
        // We've failed 🤔
        [self applescriptInject:runningApp];
    }
}

- (void)watchForApplications {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated }
    };
    
    if (sCarbonEventsRef == NULL) {
        (void) InstallEventHandler(GetApplicationEventTarget(), (EventHandlerUPP) CarbonEventHandler, GetEventTypeCount(kEvents),
                                   kEvents, (__bridge void *)(self), &sCarbonEventsRef);
    }
}

static OSStatus CarbonEventHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void* inUserData) {
    pid_t pid;
    (void) GetEventParameter(inEvent, kEventParamProcessID, typeKernelProcessID, NULL, sizeof(pid), NULL, &pid);
    switch ( GetEventKind(inEvent) )
    {
        case kEventAppLaunched:
            // App lauched!
            [this injectSIMBL:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]];
            break;
        case kEventAppTerminated:
            // App terminated!
            break;
        default:
            assert(false);
    }
    return noErr;
}

- (void)loadInLaunchd {
    NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:@[@"load", @"-F", @"-S", @"Aqua", @"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Resources/net.culater.SIMBL.Agent.plist"]];
    [task waitUntilExit];
    if (task.terminationStatus != 0)
        SIMBLLogNotice(@"launchctl returned %d", [task terminationStatus]);
}

- (void)eventDidFail:(const AppleEvent*)event withError:(NSError*)error {
    NSDictionary* userInfo = error.userInfo;
    NSNumber* errorNumber = userInfo[@"ErrorNumber"];
    
    // this error seems more common on Leopard
    if (errorNumber && errorNumber.intValue == errAEEventNotHandled)
    {
        SIMBLLogDebug(@"eventDidFail:'%4.4s' error:%@ userInfo:%@", (char*)&(event->descriptorType), error, [error userInfo]);
    }
    else
    {
        SIMBLLogDebug(@"eventDidFail:'%4.4s' error:%@ userInfo:%@", (char*)&(event->descriptorType), error, [error userInfo]);
    }
}

@end
