//#import "sim_c.h"
#import "SIMBLManager.h"
#import "NSString+Size.h"

@implementation sim_c

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
    [_tv setStringValue:[self getText]];
    if (_tv.stringValue.length > 0) {
        NSFont* f = [NSFont userFontOfSize:13];
        //        NSFont* f = [NSFont fontWithName:@"AppleSystemUIFont" size:13];
        NSSize size = [_tv.stringValue sizeWithWidth:304.0 andFont:f];
        [_tv setFrameSize:NSMakeSize(size.width, size.height)];
    }
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
    
    NSString *text = [self getText];
    if (text.length > 0) {
        NSFont* f = [NSFont userFontOfSize:13];
        //        NSFont* f = [NSFont fontWithName:@"AppleSystemUIFont" size:13];
        NSSize size = [text sizeWithWidth:304.0 andFont:f];
        NSRect newFrame = self.window.frame;
        newFrame.size.height = size.height + 72;
        [self.window setFrame:newFrame display:true];
    }
}

- (NSString*)getText {
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[SIMBLManager class]] URLForResource:@"eng_sim" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:&err];
    text = [text stringByReplacingOccurrencesOfString:@"<appname>" withString:app];
    return text;
}

- (IBAction)install:(id)sender {
    SIMBLManager *m = [SIMBLManager sharedInstance];
    Boolean agentUpdate = [m AGENT_needsUpdate];
    Boolean systemUpdate = [m OSAX_needsUpdate];
    Boolean SIP = [m SIP_enabled];
    Boolean weTried = false;

    if (systemUpdate && agentUpdate) {
        if (SIP) {
            sip_c *sipc = [[sip_c alloc] initWithWindowNibName:@"sip_c"];
            [sipc showWindow:nil];
        } else {
            [m SIMBL_install];
            weTried = true;
        }
    }

    if (systemUpdate && agentUpdate) {
        if (SIP) {
            sip_c *sipc = [[sip_c alloc] initWithWindowNibName:@"sip_c"];
            [sipc showWindow:nil];
        } else {
            [m OSAX_install];
            weTried = true;
        }
    }

    if (systemUpdate && agentUpdate) {
        [m AGENT_install];
        weTried = true;
    }
    
    if (weTried == false)
        [m SIMBL_install];
    
    [self close];
}

- (IBAction)cancel:(id)sender {
    [self close];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
