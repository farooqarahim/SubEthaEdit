//
//  FindReplaceController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "OgreKit/OgreKit.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "TextStorage.h"
#import "FindAllController.h"

static FindReplaceController *sharedInstance=nil;


@implementation FindReplaceController

+ (FindReplaceController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if (sharedInstance) {
        [super dealloc];
        return sharedInstance;
    }
    
    self = [super init];
    if (self) {
        sharedInstance = self;
    }
    return self;
}

- (void)loadUI {
    if (!O_findPanel) {
        if (![NSBundle loadNibNamed:@"FindReplace" owner:self]) {
            NSLog(@"Failed to load FindReplace.nib");
            NSBeep();
        }
    } else {
        [O_findPanel setFloatingPanel:NO];
        [O_findPanel setHidesOnDeactivate:NO];
    }
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
}

- (NSPanel *)findPanel {
    if (!O_findPanel) [self loadUI];

    return O_findPanel;
}

- (NSPanel *)gotoPanel {
    if (!O_findPanel) [self loadUI];
    return O_gotoPanel;
}

- (NSTextView *)textViewToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (IBAction)orderFrontGotoPanel:(id)aSender {
    NSPanel *panel = [self gotoPanel];
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:NO];
    [O_gotoLineTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];    
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:YES];
}

- (IBAction)orderFrontFindPanel:(id)aSender {
    NSPanel *panel = [self findPanel];
    [O_findComboBox selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}

- (IBAction)gotoLine:(id)aSender {
    NSTextView *textView = [self textViewToSearchIn];
    [(PlainTextWindowController *)[[textView window] windowController] gotoLine:[O_gotoLineTextField intValue]];

}

- (IBAction)gotoLineAndClosePanel:(id)aSender {
    [self gotoLine:aSender];
    [[self gotoPanel] orderOut:self];   
}


- (IBAction)updateRegexDrawer:(id)aSender
{
    if ([O_regexCheckbox state]==NSOnState) {
        [O_regexDrawer openOnEdge:NSMinYEdge];
    } else {
        [O_regexDrawer close];
    }

}

- (unsigned) currentOgreOptions 
{
    unsigned options = OgreNoneOption;
    if ([O_regexSinglelineCheckbox state]==NSOnState) options |= OgreSingleLineOption;
    if ([O_regexMultilineCheckbox state]==NSOnState) options |= OgreMultilineOption;
    if ([O_ignoreCaseCheckbox state]==NSOnState) options |= OgreIgnoreCaseOption;
    if ([O_regexExtendedCheckbox state]==NSOnState) options |= OgreExtendOption;
    if ([O_regexFindLongestCheckbox state]==NSOnState) options |= OgreFindLongestOption;
    if ([O_regexIgnoreEmptyCheckbox state]==NSOnState) options |= OgreFindNotEmptyOption;
    if ([O_regexNegateSinglelineCheckbox state]==NSOnState) options |= OgreNegateSingleLineOption;
    if ([O_regexDontCaptureCheckbox state]==NSOnState) options |= OgreDontCaptureGroupOption;
    if ([O_regexCaptureGroupsCheckbox state]==NSOnState) options |= OgreCaptureGroupOption;
    return options;
}

- (OgreSyntax) currentOgreSyntax
{
    int syntax = [O_regexSyntaxPopup tag];
    if([O_regexCheckbox state]==NSOffState) return OgreSimpleMatchingSyntax;
    else if(syntax==1) return OgrePOSIXBasicSyntax;
    else if(syntax==2) return OgrePOSIXExtendedSyntax;
    else if(syntax==3) return OgreEmacsSyntax;
    else if(syntax==4) return OgreGrepSyntax;
    else if(syntax==5) return OgreGNURegexSyntax;
    else if(syntax==6) return OgreJavaSyntax;
    else if(syntax==7) return OgrePerlSyntax;
    else return OgreRubySyntax;
}

- (NSString*)currentOgreEscapeCharacter
{
    if ([O_regexSyntaxPopup tag]==1) return OgreGUIYenCharacter;
    else return OgreBackslashCharacter;
}

- (void)performFindPanelAction:(id)sender forTextView:(NSTextView *)aTextView {
    [self performFindPanelAction:sender];
}

- (id)targetToFindIn
{
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}


- (void)performFindPanelAction:(id)sender 
{
    [O_statusTextField setHidden:YES];
    NSString *findString = [O_findComboBox stringValue];
    if ([sender tag]==NSFindPanelActionShowFindPanel) {
        [self orderFrontFindPanel:self];
    } else if ([sender tag]==NSFindPanelActionNext) {
        if (![findString isEqualToString:@""]) [self find:findString forward:YES];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionPrevious) {
        if (![findString isEqualToString:@""]) [self find:findString forward:NO];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionReplaceAll) {
        NSLog(@"ReplaceAll");
    } else if ([sender tag]==NSFindPanelActionReplace) {
        NSLog(@"Replace");
    } else if ([sender tag]==NSFindPanelActionReplaceAndFind) {
        NSLog(@"ReplaceAndFind");
    } else if ([sender tag]==NSFindPanelActionSetFindString) {
        NSLog(@"SetFindString");
        [self findPanel];
        NSTextView *target = [self targetToFindIn];
        if (target) {
            [O_findComboBox setStringValue:[[target string] substringWithRange:[target selectedRange]]];
        } else NSBeep();
    } else if ([sender tag]==TCMFindPanelActionFindAll) {
        if ([findString isEqualToString:@""]) {
            NSBeep();
            return;
        }
        if ((![OGRegularExpression isValidExpressionString:findString])&&(![self currentOgreSyntax]==OgreSimpleMatchingSyntax)) {
            [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
            [O_statusTextField setHidden:NO];
            NSBeep();
            return;
        }
        NSTextView *target = [self targetToFindIn];
        if (target) {
            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:[O_findComboBox stringValue]
                                         options:[self currentOgreOptions]
                                         syntax:[self currentOgreSyntax]
                                         escapeCharacter:[self currentOgreEscapeCharacter]];
            FindAllController *findall = [[[FindAllController alloc] initWithRegex:regex andOptions:[self currentOgreOptions]] autorelease];
            [(PlainTextDocument *)[[[target window] windowController] document] addFindAllController:findall];
            [findall findAll:self];
        } else NSBeep();
    }
}

- (void) findNextAndOrderOut:(id)sender 
{
    if([self find:[O_findComboBox stringValue] forward:YES]) [[self findPanel] orderOut:self];
    else [O_findComboBox selectText:nil];
}

- (BOOL) find:(NSString*)findString forward:(BOOL)forward
{
    BOOL found = NO;
    NSAutoreleasePool *findPool = [NSAutoreleasePool new];     
    [O_progressIndicator setHidden:NO];
    [O_progressIndicator startAnimation:nil];
        
    if ((![OGRegularExpression isValidExpressionString:findString])&&(![self currentOgreSyntax]==OgreSimpleMatchingSyntax)) {
        [O_progressIndicator stopAnimation:nil];
        [O_progressIndicator setHidden:YES];
        [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
        [O_statusTextField setHidden:NO];
        NSBeep();
        return NO;
    }
    
    OGRegularExpression *regex;
    regex = [OGRegularExpression regularExpressionWithString:findString
                                 options:[self currentOgreOptions]
                                 syntax:[self currentOgreSyntax]
                                 escapeCharacter:[self currentOgreEscapeCharacter]];

    NSTextView *target = [self targetToFindIn];
    if (target) {
        NSString *text = [target string];
        NSRange selection = [target selectedRange];
        
        //if ([O_scopePopup tag]==0)  !!!
        
        OGRegularExpressionMatch *aMatch = nil;
        NSEnumerator *enumerator;
        
        if (forward) {
            enumerator=[regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection))];
            aMatch = [enumerator nextObject];
            if (aMatch != nil) {
                found = YES;
                NSRange foundRange = [aMatch rangeOfMatchedString];
                [target setSelectedRange:foundRange];
                [target scrollRangeToVisible:foundRange];
                [target display];
            } else if ([O_wrapAroundCheckbox state] == NSOnState){
                enumerator = [regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(0,selection.location)];
                aMatch = [enumerator nextObject];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else {NSBeep();}
            } else {NSBeep();}
        } else { // backwards
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
                // If we are just simple searching, use NSBackwardsSearch because Regex Searching is sloooow backwards.
                unsigned options = NSLiteralSearch|NSBackwardsSearch;
                if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
                BOOL wrap = ([O_wrapAroundCheckbox state]==NSOnState); 
                NSRange foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];
                if (foundRange.length) {
                    found = YES;
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else {NSBeep();}
            } else {
                NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(0, selection.location)];
                if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else if ([O_wrapAroundCheckbox state] == NSOnState){
                    NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection))];
                    if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                    if (aMatch != nil) {
                        found = YES;
                        NSRange foundRange = [aMatch rangeOfMatchedString];
                        [target setSelectedRange:foundRange];
                        [target scrollRangeToVisible:foundRange];
                        [target display];
                    } else {NSBeep();}
                } else {NSBeep();}
            }
        }
    } else {
        NSBeep(); // No target
    }
                                 
    [O_progressIndicator stopAnimation:nil];
    [O_progressIndicator setHidden:YES];
    [findPool release];
    return found;
}

#pragma mark -
#pragma mark ### Notification handling ###

- (void)applicationDidActivate:(NSNotification *)aNotification {
    // take string from find pasteboard
}

@end 

@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap {
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
	    searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}    

@end

