//
//  SEEPlainTextEditorTopBarViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEPlainTextEditorTopBarViewController.h"
#import "PopUpButton.h"
#import "PlainTextDocument.h"
#import "DocumentMode.h"
#import "BorderedTextField.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@interface SEEPlainTextEditorTopBarViewController () <PopUpButtonDelegate>
@property (nonatomic, strong) IBOutlet BorderedTextField *writtenByTextField;
@property (nonatomic, strong) IBOutlet BorderedTextField *positionTextField;
@property (nonatomic, strong) IBOutlet NSButton *splitButton;
@property (nonatomic, strong) IBOutlet NSImageView *waitPipeIconImageView;
@property (nonatomic, strong) IBOutlet NSView *bottomBarLayerBackedView;
@property (nonatomic, strong) NSMutableSet *registeredNotifications;

@property (nonatomic) BOOL symbolPopUpIsSorted;
@end

@implementation SEEPlainTextEditorTopBarViewController

- (instancetype)initWithPlainTextEditor:(PlainTextEditor *)anEditor {
	self = [self initWithNibName:nil bundle:nil];
	if (self) {
		self.editor = anEditor;
		
		self.registeredNotifications = ({
			NSMutableSet *set = [NSMutableSet new];
		
			PlainTextDocument *document = anEditor.document;
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			__weak __typeof__(self) weakSelf = self;
			NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
			
			// register for all interesting notifications
			[set addObject:[center addObserverForName:PlainTextDocumentUserDidChangeSelectionNotification
											   object:document queue:mainQueue
										   usingBlock:^(NSNotification *aNotification) {
											   [weakSelf updateForSelectionDidChange];
			}]];

			[set addObject:[center addObserverForName:PlainTextDocumentDidChangeSymbolsNotification
											   object:document queue:mainQueue
										   usingBlock:^(NSNotification *aNotification) {
											   [weakSelf updateSymbolPopUpContent];
											   [weakSelf adjustLayout];
										   }]];

			set;
		});
		
	}
	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"SEEPlainTextEditorTopBarViewController" bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	self.symbolPopUpButton.delegate = nil;
	for (id notificationReference in self.registeredNotifications) {
		[[NSNotificationCenter defaultCenter] removeObserver:notificationReference];
	}
	
}

- (void)updateColorsForIsDarkBackground:(BOOL)isDark {
	self.view.layer.backgroundColor = [[NSColor darkOverlayBackgroundColorBackgroundIsDark:isDark] CGColor];
	self.bottomBarLayerBackedView.layer.backgroundColor = [[NSColor darkOverlaySeparatorColorBackgroundIsDark:isDark] CGColor];
	[self.symbolPopUpButton setLineColor:[NSColor darkOverlaySeparatorColorBackgroundIsDark:isDark]];
	[self.positionTextField setBorderColor:[NSColor darkOverlaySeparatorColorBackgroundIsDark:isDark]];
}

- (void)loadView {
	[super loadView];

	[self.symbolPopUpButton setDelegate:self];
	[self.writtenByTextField setHasRightBorder:NO];
	[self updateColorsForIsDarkBackground:NO];
	[self updateSymbolPopUpContent];
}

- (void)setVisible:(BOOL)visible {
	self.view.hidden = !(visible);
	[self adjustLayout];
}

- (BOOL)isVisible {
	BOOL result = !(self.view.isHidden);
	return result;
}

- (void)setSplitButtonVisible:(BOOL)splitButtonVisible {
	[self view];
	self.splitButton.hidden = !splitButtonVisible;
	[self adjustLayout];
}

- (BOOL)isSplitButtonVisible {
	[self view];
	BOOL result = !(self.splitButton.isHidden);
	return result;
}

- (void)setWaitPipeImageVisible:(BOOL)pipeWaitImageVisible {
	[self view];
	self.waitPipeIconImageView.hidden = !pipeWaitImageVisible;
	[self adjustLayout];
}

- (BOOL)isWaitPipeImageVisible {
	BOOL result = !(self.waitPipeIconImageView.isHidden);
	return result;
}

- (void)setSplitButtonShowsClose:(BOOL)splitButtonShowsClose {
	_splitButtonShowsClose = splitButtonShowsClose;
	[self view];
	[self.splitButton setImage:[NSImage imageNamed:splitButtonShowsClose?@"ToolbarSplitOnePane":@"ToolbarSplitTwoPanes"]];
}

#define SPACING 5.0

- (void)adjustLayout {
	PlainTextDocument *document = self.editor.document;
	if (self.visible) {
		NSRect bounds = self.view.bounds;
		CGFloat xPosition = NSMinX(bounds);
		BOOL isWaiting = [document isWaiting];
		BOOL hasSymbols = [[document documentMode] hasSymbols];
		
		BorderedTextField *positionTextField = self.positionTextField;
		PopUpButton *symbolPopUpButton = self.symbolPopUpButton;
		// document is waiting for some input from a pipe so show an indicator for that
		self.waitPipeIconImageView.hidden = !isWaiting;
        [positionTextField setHasLeftBorder:isWaiting];
		if (isWaiting) {
			xPosition += 19.;
		}
		
		// if there are no symbols hide the symbols popup
		[symbolPopUpButton setHidden:!hasSymbols];
		
		// calculate optimal size for position text field
		NSSize positionTextSize = positionTextField.intrinsicContentSize;
        NSRect positionTextFrame = [positionTextField frame];
		positionTextFrame.origin.x = xPosition;
        positionTextFrame.size.width = positionTextSize.width;
		
		xPosition += NSWidth(positionTextFrame);
		
		// calculate optimal width for symbol popup
        NSRect symbolPopUpFrame = [symbolPopUpButton frame];
        symbolPopUpFrame.origin.x = xPosition;
		symbolPopUpFrame.size.width = symbolPopUpButton.intrinsicContentSize.width;
		
		// xPosition += NSWidth(symbolPopUpFrame);
		
		// calculate optimal size of writtenBy text field
		NSTextField *writtenByTextField = self.writtenByTextField;
        NSRect writtenByTextFrame = writtenByTextField.frame;
        writtenByTextFrame.size.width = writtenByTextField.intrinsicContentSize.width + SPACING;
		
		// split view button, just needed for size here
		NSRect splitToggleButtonFrame = [self.splitButton frame];
		CGFloat splitButtonWidth = self.splitButtonVisible ? NSWidth(splitToggleButtonFrame) : 0;
		
		// the writtenBy text field has priorty over the symbol popup so give it all space it wants if possible
        CGFloat remainingWidth = bounds.size.width - symbolPopUpFrame.origin.x - SPACING - SPACING - splitButtonWidth;
		if (writtenByTextFrame.size.width + symbolPopUpFrame.size.width > remainingWidth) {
			// make sure symbol popup does not get smaller than 20 px.
            if (remainingWidth - writtenByTextFrame.size.width > 20.) {
                symbolPopUpFrame.size.width = remainingWidth - writtenByTextFrame.size.width;
            } else {
                // To small for both views, split space equaly and give the popup 20px more space
                CGFloat remainingSpace = (remainingWidth - 20.) / 2.;
                symbolPopUpFrame.size.width = remainingSpace + 20.;
                writtenByTextFrame.size.width = remainingSpace;
            }
        }
		
		// finally we can calulate the origin of the writtenBy text field
        writtenByTextFrame.origin.x = bounds.origin.x + bounds.size.width - writtenByTextFrame.size.width - SPACING - splitButtonWidth;
		
		// adjust all frames to backing grid
		/* not doing that for now as we made sure we use integral point values all over the place
		positionTextFrame = [positionTextField centerScanRect:positionTextFrame];
		symbolPopUpFrame = [symbolPopUpButton centerScanRect:symbolPopUpFrame];
		writtenByTextFrame = [writtenByTextField centerScanRect:writtenByTextFrame];
		 */
		
		// set frames
		[positionTextField setFrame:positionTextFrame];
        [symbolPopUpButton setFrame:symbolPopUpFrame];
		[writtenByTextField setFrame:writtenByTextFrame];
		
		[self.view setNeedsDisplay:YES];
	}
}

- (IBAction)positionButtonAction:(id)sender {
	[self.editor positionButtonAction:(id)sender];
}

- (IBAction)splitToggleButtonAction:(id)sender {
	[self.editor.windowControllerTabContext toggleEditorSplit];
}

- (IBAction)keyboardActivateSymbolPopUp {
	[self.symbolPopUpButton performClick:self.editor];
}
#pragma mark - Symbol Popup

- (void)updateSymbolPopUpContent {
	[self updateSymbolPopUpSorted:self.symbolPopUpIsSorted];
}

- (void)updateSelectedSymbolInPopUp:(PopUpButton *)aPopUp {
    PlainTextDocument *document = self.editor.document;
	
    if ([[document documentMode] hasSymbols]) {
        int symbolTag = [document selectedSymbolForRange:[document.textStorage fullRangeForFoldedRange:[self.editor.textView selectedRange]]];
		
        if (symbolTag == -1) {
            [aPopUp selectItemAtIndex:0];
        } else {
            [aPopUp selectItem:[aPopUp.menu itemWithTag:symbolTag]];
        }
    }
}

- (void)updateSymbolPopUp:(PopUpButton *)aPopUp sorted:(BOOL)isSorted {
    NSMenu *popUpMenu = [self.editor.document symbolPopUpMenuForView:self.editor.textView sorted:isSorted];
    NSPopUpButtonCell *cell = [aPopUp cell];
		
    if ([[popUpMenu itemArray] count]) {
        NSMenu *copiedMenu = [popUpMenu copyWithZone:[NSMenu menuZone]];
        [cell setMenu:copiedMenu];
        [self updateSelectedSymbolInPopUp:aPopUp];
    }
}

- (void)updateSymbolPopUpSorted:(BOOL)aSorted {
	[self updateSymbolPopUp:self.symbolPopUpButton sorted:aSorted];
	self.symbolPopUpIsSorted = aSorted;
}

- (void)popUpWillShowMenu:(PopUpButton *)aButton {
    NSEvent *currentEvent = [NSApp currentEvent];
    BOOL sorted = ([currentEvent type] == NSLeftMouseDown && ([currentEvent modifierFlags] & NSAlternateKeyMask));
	
    if (sorted != self.symbolPopUpIsSorted) {
        [self updateSymbolPopUpSorted:sorted];
    }
}


#pragma mark -

- (void)updateForSelectionDidChange {
	PlainTextEditor *editor = self.editor;
	if (editor) {		
		NSRange selection = [editor.textView selectedRange];
		FoldableTextStorage *textStorage = (FoldableTextStorage *)editor.textView.textStorage;
		NSString *positionString = [textStorage positionStringForRange:selection];
		
		if (selection.location < [textStorage length]) {
			id blockAttribute = [textStorage attribute:BlockeditAttributeName
											   atIndex:selection.location
										effectiveRange:nil];
			
			if (blockAttribute) positionString = [positionString stringByAppendingFormat:@" %@", NSLocalizedString(@"[Blockediting]", nil)];
		}
		
		[self.positionTextField setStringValue:positionString];
		
		
		NSString *writtenByValue = @"";
		
		NSString *followUserID = [editor followUserID];
		
		if (followUserID) {
			NSString *userName = [[[TCMMMUserManager sharedInstance] userForUserID:followUserID] name];
			
			if (userName) {
				writtenByValue = [NSString stringWithFormat:NSLocalizedString(@"Following %@", "Status bar text when following"), userName];
			}
		} else {
			if (selection.location < textStorage.length) {
				NSRange range;
				NSString *userId = [textStorage attribute:WrittenByUserIDAttributeName
												  atIndex:selection.location
									longestEffectiveRange:&range
												  inRange:selection];
				
				if (!userId &&
					selection.length > range.length) {
					
					userId = [textStorage attribute:WrittenByUserIDAttributeName
											atIndex:NSMaxRange(range)
							  longestEffectiveRange:&range
											inRange:selection];
				}
				
				if (userId) {
					NSString *userName = nil;
					
					if ([userId isEqualToString:[TCMMMUserManager myUserID]]) {
						userName = NSLocalizedString(@"me", nil);
					} else {
						userName = [[[TCMMMUserManager sharedInstance] userForUserID:userId] name];
						if (!userName) userName = @"";
					}
					
					if (selection.length > range.length) {
						writtenByValue = [NSMutableString stringWithFormat:NSLocalizedString(@"Written by %@ et al", nil), userName];
					} else {
						writtenByValue = [NSMutableString stringWithFormat:NSLocalizedString(@"Written by %@", nil), userName];
					}
				}
			}
		}
		
		[self.writtenByTextField setStringValue:writtenByValue];
		
		[self updateSelectedSymbolInPopUp:self.symbolPopUpButton];
		
		[self adjustLayout];
	}
}


@end
