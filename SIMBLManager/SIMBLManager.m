//
//  SIMBLManager.m
//  SIMBLManager
//
//  Created by Wolfgang Baird on 6/14/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIMBLManager.h>
#import <STPrivilegedTask.h>

@interface SIMBLManager ()
@end

@implementation SIMBLManager

SIMBLManager* si_SIMBLManager;

+ (SIMBLManager*) sharedInstance {
    static SIMBLManager* si_SIMBLManager = nil;
    if (si_SIMBLManager == nil) {
        si_SIMBLManager = [[SIMBLManager alloc] init];
    }
    return si_SIMBLManager;
}

- (Boolean)runSTPrivilegedTask:(NSString*)launchPath :(NSArray*)args {
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    NSMutableArray *components = [args mutableCopy];
    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:components];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    Boolean result = false;
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
        }
    } else {
        result = true;
    }
    
    return result;
}

- (Boolean)SIP_enabled {
    BOOL result = false;
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 11)
    {
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/sh";
        task.arguments = @[@"-c", @"touch /System/test 2>&1"];
        task.standardOutput = pipe;
        [task launch];
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        if ([output rangeOfString:@"Operation not permitted"].length)
            result = true;
    }
    return result;
}

- (Boolean)SIP_bypass {
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion != 11)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion > 4)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion == 0)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion == 4) {
        system("ln -s /S*/*/E*/A*Li*/*/I* /dev/diskX;fsck_cs /dev/diskX 1>&-;touch /Li*/Ex*/;reboot");
        return true;
    }
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion < 4)
    {
        if ([self SIP_enabled])
            return [self runSTPrivilegedTask:@"/bin/sh" :[NSArray arrayWithObjects:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"stfusip" ofType:nil], @"disable", nil]];
        else
            return [self runSTPrivilegedTask:@"/bin/sh" :[NSArray arrayWithObjects:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"stfusip" ofType:nil], @"enable", nil]];
        return true;
    }
    
    return false;
}

- (Boolean)SIMBL_install {
    BOOL success = false;
    if (![self SIP_enabled])
    {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installSIMBL" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL install failed!"];
            [alert setInformativeText:@"Something went wrong, probably System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBL install successful");
    }
    return success;
}

- (void)SIMBL_injectApp:(NSString *)appName :(Boolean)restart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (restart) {
            system([[NSString stringWithFormat:@"killall %@; sleep 1; osascript -e 'tell application \"%@\" to inject SIMBL into Snow Leopard'", appName, appName] UTF8String]);
        } else {
            system([[NSString stringWithFormat:@"osascript -e 'tell application \"%@\" to inject SIMBL into Snow Leopard'", appName] UTF8String]);
        }
    });
}

- (void)SIMBL_injectAll {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Boolean loadAll = false;
        NSMutableArray *injectList = [[NSMutableArray alloc] init];
        NSArray *SIMBLfolders = @[@"/Library/Application Support/SIMBL/Plugins"];
        for (NSString *path in SIMBLfolders)
        {
            for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil])
            {
                if (loadAll)
                    break;
                NSBundle *pluginBundle  = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", path, bundle]];
                NSArray *targetsArray   = [[pluginBundle infoDictionary] valueForKey:@"SIMBLTargetApplications"];
                for (NSDictionary *targetDict in targetsArray)
                {
                    if (loadAll)
                        break;
                    NSString *targetID = [targetDict objectForKey:@"BundleIdentifier"];
                    if ([targetID length])
                    {
                        if ([targetID isEqualToString:@"*"])
                            loadAll = true;
                        NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:targetID]];
                        if ([appName length])
                            if (![injectList containsObject:appName])
                                [injectList addObject:appName];
                    }
                }
            }
        }
        
        if (loadAll) {
            for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
                if ([app.bundleURL.pathExtension isEqualToString:@"app"])
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self SIMBL_injectApp:[app localizedName] :false]; });
        } else {
            for (NSString *appName in injectList)
                [self SIMBL_injectApp:appName :false];
        }
    });
}

- (Boolean)OSAX_installed {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax"];
}

- (Boolean)OSAX_install {
    BOOL success = false;
    if (![self SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installOSAX" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL.osax install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL.osax install failed!"];
            [alert setInformativeText:@"Something went wrong, probably System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBL.osax install successful");
    }
    return success;
}

- (NSDictionary*)OSAX_versions {
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBL.osax/Contents/Info" ofType:@"plist"]];
    NSString *locVer = [local objectForKey:@"CFBundleVersion"];
    NSString *curVer = [current objectForKey:@"CFBundleVersion"];
//    NSLog(@"-- SIMBL.osax --\nOld: %@\nNew: %@", locVer, curVer);
    NSDictionary *result = [[NSDictionary alloc]
                            initWithObjectsAndKeys:locVer,@"localVersion",
                            curVer,@"newestVersion",
                            nil];
    return result;
}

- (Boolean)OSAX_needsUpdate {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"])
        return true;
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBL.osax/Contents/Info" ofType:@"plist"]];
    NSString *actualVersion = [local objectForKey:@"CFBundleVersion"];
    NSString *requiredVersion = [current objectForKey:@"CFBundleVersion"];
    Boolean result = false;
    if ([requiredVersion compare:actualVersion options:NSNumericSearch] == NSOrderedDescending) result = true;
    return result;
}

- (Boolean)AGENT_installed {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app"];
}

- (Boolean)AGENT_install {
    BOOL success = false;
    success = [self runSTPrivilegedTask:@"/bin/sh" :@[[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installAgent" ofType:nil]]];
    if (!success) {
        NSLog(@"SIMBLAgent install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBLAgent install failed!"];
            [alert setInformativeText:@"Something went wrong..."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBLAgent install successful");
    }
    return success;
}

- (Boolean)AGENT_needsUpdate {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"])
        return true;
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBLAgent.app/Contents/Info" ofType:@"plist"]];
    NSString *actualVersion = [local objectForKey:@"CFBundleVersion"];
    NSString *requiredVersion = [current objectForKey:@"CFBundleVersion"];
    Boolean result = false;
    if ([requiredVersion compare:actualVersion options:NSNumericSearch] == NSOrderedDescending) result = true;
    return result;
}

- (NSDictionary*)AGENT_versions {
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBLAgent.app/Contents/Info" ofType:@"plist"]];
    NSString *locVer = [local objectForKey:@"CFBundleVersion"];
    NSString *curVer = [current objectForKey:@"CFBundleVersion"];
//    NSLog(@"-- SIMBLAgent --\nOld: %@\nNew: %@", locVer, curVer);
    NSDictionary *result = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:locVer,@"localVersion",
                                 curVer,@"newestVersion",
                                 nil];
    return result;
}

- (Boolean)SIMBL_remove {
    BOOL success = false;
    if (![self SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installSIMBL" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL removal failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL removal failed!"];
            [alert setInformativeText:@"Something went wrong, possibly System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBLAgent install successful");
    }
    return success;
}

- (Boolean)unsign_XCODE
{
    return true;
}

- (Boolean)restore_XCODE
{
    return true;
}

@end

