//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "StylePreferences.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "DocumentController.h"
#import "TableView.h"
#import "TextFieldCell.h"
#import "GeneralPreferences.h"
#import "OverlayView.h"
#import "SyntaxHighlighter.h"

@interface StylePreferences ()

- (void)highlightSyntax;
- (void)selectMode:(DocumentMode *)aDocumentMode;

@end


@implementation StylePreferences

- (id) init {
    self = [super init];
    if (self) {
        I_undoManager=[NSUndoManager new];
    }
    return self;
}

- (void)dealloc {
    [I_undoManager release];
    [super dealloc];
}

- (NSImage *)icon {
    return [NSImage imageNamed:@"StylePrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"StylePrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.style";
}

- (NSString *)mainNibName {
    return @"StylePrefs";
}

- (void)updateStyleSheetLists {
	[O_styleSheetCustomPopUpButton removeAllItems];
	[O_styleSheetCustomPopUpButton addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
	NSPopUpButtonCell *styleSheetButtonCell = [[O_customStylesForLanguageContextsTableView tableColumnWithIdentifier:@"styleSheet"] dataCell];
	[styleSheetButtonCell removeAllItems];
	[styleSheetButtonCell addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    
}

- (void)documentModeListChanged:(NSNotification *)aNotification {
    [self performSelector:@selector(changeMode:) withObject:O_modePopUpButton afterDelay:.2];
}

- (void)takeFontFromMode:(DocumentMode *)aMode {
    NSDictionary *fontAttributes = [aMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
//    NSLog(@"%s %@",__FUNCTION__, fontAttributes);
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
}

- (IBAction)validateDefaultsState:(id)aSender {
	[O_styleSheetDefaultRadioButton   setState:NSOffState];
	[O_styleSheetCustomRadioButton    setState:NSOffState];
	[O_styleSheetCustomForLanguageContextsRadioButton setState:NSOffState];

	DocumentMode *currentMode = [O_modeController content];
	if ([[[currentMode defaults] objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey] boolValue]) {
		[O_styleSheetDefaultRadioButton   setState:NSOnState];
	} else {
		SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
		if (styleSheetSettings.usesMultipleStyleSheets) {
			[O_styleSheetCustomForLanguageContextsRadioButton setState:NSOnState];
		} else {
			[O_styleSheetCustomRadioButton   setState:NSOnState];
		}
	}


//    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
    DocumentMode *selectedMode=[O_modePopUpButton selectedMode];
    [O_fontController setContent:([O_fontDefaultButton state]==NSOnState)?baseMode:selectedMode];
//    [O_styleController setContent:useDefault?baseMode:selectedMode];
//    [O_defaultStyleButton setHidden:[[I_currentSyntaxStyle documentMode] isBaseMode]];
//    if (O_defaultStyleButton !=aSender) {
//        [O_defaultStyleButton setState:useDefault?NSOnState:NSOffState];
//    }
//
//    [O_stylesTableView setDisableFirstRow:useDefault];
//    
//    if (useDefault) {
//        [O_stylesTableView deselectRow:0];
//    }
//    NSDictionary *baseStyle=[[[O_styleController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
//    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
//    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
    [self takeFontFromMode:selectedMode];
//    [self updateBackgroundColor];
//    [O_lightBackgroundButton       setEnabled:!useDefault];
//    [O_darkBackgroundButton        setEnabled:!useDefault];
//    [O_backgroundColorWell         setEnabled:!useDefault];
//    [O_invertedBackgroundColorWell setEnabled:!useDefault];
}

- (IBAction)changeDefaultState:(id)aSender {
    BOOL useDefault = ([aSender state]==NSOnState);
    [[[O_modePopUpButton selectedMode] defaults] setObject:[NSNumber numberWithBool:useDefault] forKey:DocumentModeUseDefaultStylePreferenceKey];
    [self validateDefaultsState:aSender];
}

- (NSUndoManager *)undoManager {
    return I_undoManager;
}


//- (void)storeCurrentStyleForUndo {
//    [I_undoManager registerUndoWithTarget:self selector:@selector(setStyle:) object:[[I_currentSyntaxStyle copy] autorelease]];
//}

#pragma mark -
#pragma mark IBActions

- (void)selectMode:(DocumentMode *)aDocumentMode {
	[O_modeController setContent:aDocumentMode];
	[O_modePopUpButton setSelectedMode:aDocumentMode];
	[self updateStyleSheetLists];
	NSString *customStyleSheetName = [[aDocumentMode styleSheetSettings] singleStyleSheetName];
	[O_styleSheetCustomPopUpButton selectItemWithTitle:customStyleSheetName];
	[O_customStylesForLanguageContextsTableView reloadData];
	[O_styleSheetDefaultRadioButton setHidden:[aDocumentMode isBaseMode]];
	// TODO: resze the style settings box
	CGFloat heightChange = 0;
	BOOL shouldShow = ([[[aDocumentMode syntaxDefinition] allLanguageContexts] count] > 1);
	if (shouldShow && [O_customStyleSheetsContainerView isHidden]) {
		[O_customStyleSheetsContainerView setHidden:NO ];
		heightChange =  [O_customStyleSheetsContainerView frame].size.height;
	} else if (!shouldShow && ![O_customStyleSheetsContainerView isHidden]) {
		[O_customStyleSheetsContainerView setHidden:YES];
		heightChange = -[O_customStyleSheetsContainerView frame].size.height;
	}
	if (heightChange != 0) {
		NSBox *styleBox   = O_styleContainerBox;
		NSBox *previewBox = O_previewContainerBox;
		NSRect boxFrame = [styleBox frame];
		NSRect previewBoxFrame = [previewBox frame];
		boxFrame.size.height += heightChange;
		boxFrame.origin.y -= heightChange;
		previewBoxFrame.size.height -= heightChange;
		[styleBox setFrame:boxFrame];
		[previewBox setFrame:previewBoxFrame];
	}
	[self validateDefaultsState:nil];
	[[[O_syntaxSampleTextView textStorage] mutableString] setString:[aDocumentMode syntaxExampleString]];
	[self highlightSyntax];
}

- (IBAction)changeMode:(id)aSender {
	DocumentMode *newMode=[aSender selectedMode];
	if (newMode) {
		[self selectMode:newMode];
	}
}

- (IBAction)styleRadioButtonAction:(id)aSender {
	DocumentMode *currentMode = [O_modeController content];
	if (aSender == O_styleSheetDefaultRadioButton) {
		[[currentMode defaults] setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	} else {
		[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
		SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
		if (aSender == O_styleSheetCustomRadioButton) {
			styleSheetSettings.usesMultipleStyleSheets = NO;
		} else {
			styleSheetSettings.usesMultipleStyleSheets = YES;
		}
	}
    [self validateDefaultsState:aSender];
	[self highlightSyntax];
}


- (IBAction)changeCustomStyleSheet:(id)aSender {
	DocumentMode *currentMode = [O_modeController content];
	NSString *styleSheetName = [[O_styleSheetCustomPopUpButton selectedItem] title];
	[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];	
	styleSheetSettings.singleStyleSheetName = styleSheetName;
	styleSheetSettings.usesMultipleStyleSheets = NO;
    [self validateDefaultsState:aSender];
	[self highlightSyntax];
}


- (IBAction)applyToOpenDocuments:(id)aSender {
	[self highlightSyntax];
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:[O_modeController content]];
}


- (void)didUnselect {
    // Save preferences
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
}

- (IBAction)changeFontViaPanel:(id)sender {
    NSDictionary *fontAttributes=[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    [[NSFontManager sharedFontManager] 
        setSelectedFont:newFont 
             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager {
//	NSLog(@"%s",__FUNCTION__);
    if ([O_fontDefaultButton state] != NSOnState) {
        NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [dict setObject:[newFont fontName] 
                 forKey:NSFontNameAttribute];
        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] 
                 forKey:NSFontSizeAttribute];
        [[O_modePopUpButton selectedMode] setValue:dict forKeyPath:@"defaults.FontAttributes"];
        [self changeMode:O_modePopUpButton];
    }
}

- (void)setBaseFont:(NSFont *)aFont {
    [I_baseFont autorelease];
     I_baseFont = [aFont retain];
}

- (NSFont *)baseFont {
    return I_baseFont;
}

- (NSArray *)languageContexts {
	return [[[O_modeController content] syntaxDefinition] allLanguageContexts];
}

#pragma mark -
#pragma mark syntax highlighting callbacks

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope languageContext:(NSString *)aLanguageContext {
	DocumentMode *currentMode = [O_modeController content];
	SEEStyleSheet *styleSheet = [currentMode styleSheetForLanguageContext:aLanguageContext];
	return [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:aScope] font:I_baseFont];
}

- (void)highlightSyntax {
	DocumentMode *currentMode = [O_modeController content];
	SEEStyleSheetSettings *settings = [currentMode styleSheetSettings];
	[O_syntaxSampleTextView setBackgroundColor:settings.documentBackgroundColor];
	SyntaxHighlighter *highlighter = [currentMode syntaxHighlighter];
	NSTextStorage *textStorage = [O_syntaxSampleTextView textStorage];
	if (highlighter) {
		[highlighter cleanUpTextStorage:textStorage];
		while (![highlighter colorizeDirtyRanges:textStorage ofDocument:self]) {
			// go on until finished
		}
	} else {
		SEEStyleSheet *styleSheet = [currentMode styleSheetForLanguageContext:currentMode.scriptedName];
		NSDictionary *attributes = [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] font:I_baseFont];
		[textStorage setAttributes:attributes range:NSMakeRange(0,textStorage.length)];
		NSLog(@"%s no highlighter",__FUNCTION__);
	}
}

#pragma mark -
#pragma mark TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[[[O_modeController content] syntaxDefinition] allLanguageContexts] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRow {
	NSArray *languageContexts = [self languageContexts];
	NSString *languageContext = [languageContexts objectAtIndex:aRow];
	if ([[aTableColumn identifier] isEqualToString:@"languageContext"]) {
		return languageContext;
	} else {
		SEEStyleSheetSettings *styleSheetSettings = [[O_modeController content] styleSheetSettings];
		NSString *styleSheetName = [styleSheetSettings styleSheetNameForLanguageContext:[languageContexts objectAtIndex:aRow]];
		if (!styleSheetName) {
			styleSheetName = [styleSheetSettings singleStyleSheetName];
		}
		return [NSNumber numberWithInteger:[[aTableColumn dataCell] indexOfItemWithTitle:styleSheetName]];
	}
}

- (void)takeStyleSheetChoice:(id)aSender {
	NSLog(@"%s %@ %d:%d",__FUNCTION__, aSender, [aSender clickedRow], [aSender clickedColumn]);
	

}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSArray *languageContexts = [self languageContexts];
	NSString *languageContext = [languageContexts objectAtIndex:rowIndex];
	NSString *styleSheetName = [[[aTableColumn dataCell] itemTitles] objectAtIndex:[anObject integerValue]];
	DocumentMode *currentMode = [O_modeController content];
	SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
	[styleSheetSettings setStyleSheetName:styleSheetName forLanguageContext:languageContext];
	[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	styleSheetSettings.usesMultipleStyleSheets = YES;
	[self highlightSyntax];
}

#pragma mark Pref Module methods

- (void)didSelect {
	PlainTextDocument *frontmostDocument = [[DocumentController sharedInstance] frontmostPlainTextDocument];
	if (frontmostDocument) {
		[self selectMode:[frontmostDocument documentMode]];
	} else {
		[self highlightSyntax];
	}
	[super didSelect];
}

#pragma mark TableView Delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return YES;
}

@end