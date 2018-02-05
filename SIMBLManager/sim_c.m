//#import "sim_c.h"
#import <SIMBLManager/SIMBLManager.h>

@interface sim_c ()

@property IBOutlet NSTextField *tv;

@end

@implementation sim_c

@synthesize accept;
@synthesize cancel;

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
    [[self accept] setKeyEquivalent:@"\r"];
    
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"eng_sim" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:&err];
    text = [text stringByReplacingOccurrencesOfString:@"<appname>" withString:app];
    [_tv setStringValue:text];
}

- (IBAction)install:(id)sender {
    if (![[SIMBLManager sharedInstance] SIP_enabled]) {
        [[SIMBLManager sharedInstance] AGENT_install];
        [[SIMBLManager sharedInstance] OSAX_install];
        [self close];
    } else {
        NSLog(@"Oh no!");
        [self close];
    }
}

- (IBAction)cancel:(id)sender {
    [self close];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end
