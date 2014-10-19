/* LinkingEditor */

/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
  Redistribution and use in source and binary forms, with or without modification, are permitted 
  provided that the following conditions are met:
   - Redistributions of source code must retain the above copyright notice, this list of conditions 
     and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice, this list of 
	 conditions and the following disclaimer in the documentation and/or other materials provided with
     the distribution.
   - Neither the name of Notational Velocity nor the names of its contributors may be used to endorse 
     or promote products derived from this software without specific prior written permission. */


#import "GlobalPrefs.h"

@class NotesTableView;
@class NoteObject;

@interface LinkingEditor : NSTextView <NSLayoutManagerDelegate, NSTextFinderClient>
{	
    NSTextFinder *textFinder;
    IBOutlet NSTextField *controlField;
    IBOutlet NotesTableView *notesTableView;
	
	GlobalPrefs *prefsController;
	BOOL didRenderFully;
	
	BOOL didChangeIntoAutomaticRange;
	NSRange lastAutomaticallySelectedRange;
	NSRange changedRange;
	BOOL isAutocompleting, wasDeleting;
	
	BOOL backgroundIsDark, mouseInside;

	//ludicrous ivars used to hack NSTextFinder. just write your own, damnit!
    NSString *lastImportedFindString;
	
	NSCursor *(*defaultIBeamCursorIMP)(Class, SEL);
	NSCursor *(*whiteIBeamCursorIMP)(Class, SEL);

    BOOL managesTextWidth;
	NSString *beforeString;
	NSString *afterString;
//    BOOL clipboardHasLink;
}

@property (readonly) NSString *activeParagraphBeforeCursor;
@property (readonly) NSString *activeParagraphPastCursor;
@property (readonly) NSString *beforeString;
@property (readonly) NSString *afterString;
@property (readonly) NSString *activeParagraph;
@property (readwrite) BOOL managesTextWidth;
//@property (readonly) BOOL clipboardHasLink;


- (NSColor*)_insertionPointColorForForegroundColor:(NSColor*)fgColor backgroundColor:(NSColor*)bgColor;
- (NSColor*)_linkColorForForegroundColor:(NSColor*)fgColor backgroundColor:(NSColor*)bgColor;
- (NSColor*)_selectionColorForForegroundColor:(NSColor*)fgColor backgroundColor:(NSColor*)bgColor;
- (NSDictionary*)preferredLinkAttributes;
- (NSRange)selectedRangeWasAutomatic:(BOOL*)automatic;
- (void)setAutomaticallySelectedRange:(NSRange)newRange;
- (void)removeHighlightedTerms;
- (void)highlightRangesTemporarily:(CFArrayRef)ranges;
- (NSRange)highlightTermsTemporarilyReturningFirstRange:(NSString*)typedString avoidHighlight:(BOOL)noHighlight;
- (void)defaultStyle:(id)sender;
- (void)strikethroughNV:(id)sender;
- (void)bold:(id)sender;
- (void)italic:(id)sender;
- (void)applyStyleOfTrait:(NSFontTraitMask)trait alternateAttributeName:(NSString*)attrName alternateAttributeValue:(id)value;
- (id)highlightLinkAtIndex:(NSUInteger)givenIndex;

- (BOOL)jumpToRenaming;
- (void)indicateRange:(NSValue*)rangeValue;

- (void)fixTypingAttributesForSubstitutedFonts;
- (void)fixCursorForBackgroundUpdatingMouseInside:(BOOL)checkMouseLoc;

- (BOOL)_selectionAbutsBulletIndentRange;
- (BOOL)_rangeIsAutoIdentedBullet:(NSRange)aRange;

- (void)setupFontMenu;

- (BOOL)didRenderFully;

#pragma mark - nvALT additions
- (void)setMouseInside:(BOOL)inside;
- (BOOL)changeMarkdownAttribute:(NSString *)syntaxBit;
//- (BOOL)isAlreadyNearMarkdownLink;
- (BOOL)mouseIsHere;
- (void)resetInset;
- (void)updateInsetAndForceLayout:(BOOL)force;
- (void)updateInsetForFrame:(NSRect)frameRect andForceLayout:(BOOL)force;
- (BOOL)setInsetForFrame:(NSRect)frameRect alwaysSet:(BOOL)always;
- (BOOL)deleteEmptyPairsBetweenRange:(NSRange)charRange inLineRange:(NSRange)lineRange;
- (void)selectRangeAndRegisterUndo:(NSRange)selRange;
- (BOOL)cursorAtRange:(NSRange)charRange isBetweenEmptyPairsInLineRange:(NSRange)actRange;
- (NSRange)rangeOfActiveParagraph;
- (NSString *)activeParagraphTrimWS:(BOOL)shouldTrim;
- (NSUInteger)cursorIsInsidePair:(NSString *)closingCharacter;
- (BOOL)pairIsOnOwnParagraph:(NSString *)closingCharacter;
- (BOOL)cursorIsImmediatelyPastPair:(NSString *)closingCharacter;
- (IBAction)performFindPanelAction:(id)sender;
- (void)updateTextColors;
- (IBAction)insertLink:(id)sender;
- (void)prepareTextFinder;
- (BOOL)textFinderIsVisible;
- (IBAction)pasteMarkdownLink:(id)sender;
- (void)insertStringAtStartOfSelectedParagraphs:(NSString *)insertString;
- (void)removeStringAtStartOfSelectedParagraphs:(NSString *)removeString;
- (BOOL)clipboardHasLink;
- (BOOL)updateNumberedListFromRange:(NSRange)currentRange startingNum:(NSInteger)listNum;

@end
