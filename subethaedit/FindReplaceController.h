//
//  FindReplaceController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

typedef enum {
    TCMFindPanelActionFindAll = 1001,
} TCMFindPanelAction;

@interface NSString (NSStringTextFinding)
- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap;
@end

@interface FindReplaceController : NSObject {
    IBOutlet NSPanel *O_findPanel;
    IBOutlet NSPanel *O_gotoPanel;
    IBOutlet NSPanel *O_tabWidthPanel;
    IBOutlet NSTextField *O_tabWidthTextField;
    IBOutlet NSTextField *O_gotoLineTextField;
    IBOutlet NSComboBox *O_findComboBox;
    IBOutlet NSComboBox *O_replaceComboBox;
    IBOutlet NSButton *O_ignoreCaseCheckbox;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSDrawer *O_regexDrawer;
    IBOutlet NSButton *O_regexCheckbox;
    IBOutlet NSButton *O_regexCaptureGroupsCheckbox;
    IBOutlet NSButton *O_regexDontCaptureCheckbox;
    IBOutlet NSPopUpButton *O_regexEscapeCharacter;
    IBOutlet NSButton *O_regexExtendedCheckbox;
    IBOutlet NSButton *O_regexFindLongestCheckbox;
    IBOutlet NSButton *O_regexIgnoreEmptyCheckbox;
    IBOutlet NSButton *O_regexMultilineCheckbox;
    IBOutlet NSButton *O_regexNegateSinglelineCheckbox;
    IBOutlet NSView *O_regexOptionsView;
    IBOutlet NSButton *O_regexSinglelineCheckbox;
    IBOutlet NSPopUpButton *O_regexSyntaxPopup;
    IBOutlet NSPopUpButton *O_scopePopup;
    IBOutlet NSTextField *O_statusTextField;
    IBOutlet NSButton *O_wrapAroundCheckbox;
    NSMutableArray *I_findHistory;
    NSMutableArray *I_replaceHistory;   
    //BOOL ignoreNextComboBoxEvent;
    //NSArray *I_replaceAllMatchArray;
   // NSData *I_replaceAllMatchArrayData;
    //NSMutableString *I_replaceAllText;
    //OGReplaceExpression *I_replaceAllRepex;
    //OGRegularExpression *I_replaceAllRegex;
    //int I_replaceAllReplaced;
    //int I_replaceAllArrayIndex;
}
+ (FindReplaceController *)sharedInstance;

- (NSPanel *)findPanel;
- (NSPanel *)gotoPanel;
- (NSPanel *)tabWidthPanel;

- (NSTextView *)textViewToSearchIn;

- (IBAction)orderFrontTabWidthPanel:(id)aSender;
- (IBAction)chooseTabWidth:(id)aSender;
- (IBAction)orderFrontGotoPanel:(id)aSender;
- (IBAction)orderFrontFindPanel:(id)aSender;
- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;
- (unsigned) currentOgreOptions;
- (OgreSyntax) currentOgreSyntax;
- (NSString*)currentOgreEscapeCharacter;
- (void)performFindPanelAction:(id)sender forTextView:(NSTextView *)aTextView;
- (void)performFindPanelAction:(id)sender;
- (IBAction)updateRegexDrawer:(id)aSender;
- (BOOL) find:(NSString*)findString forward:(BOOL)forward;
- (void) findNextAndOrderOut:(id)sender;
- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;
- (void) addString:(NSString*)aString toHistory:(NSMutableArray *)anArray;
- (void) replaceSelection;
- (void) replaceAllInRange:(NSRange)aRange;

@end


