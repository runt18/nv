//
//  BookmarksController.m
//  Notation
//
//  Created by Zachary Schneirov on 1/21/07.

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


#import "BookmarksController.h"
#import "NoteObject.h"
#import "GlobalPrefs.h"
#import "AppController.h"
#import "NSString_NV.h"
#import "NSCollection_utils.h"
#import "CFUUID+NTVAdditions.h"

static NSString *BMSearchStringKey = @"SearchString";
static NSString *BMNoteUUIDStringKey = @"NoteUUIDString";

@implementation NoteBookmark

- (id)initWithDictionary:(NSDictionary*)aDict {
	if (!aDict) {
		NSLog(@"NoteBookmark init: supplied nil dictionary; couldn't init");
		[self release];
		return (self = nil);
	}

    self = [super init];
    if (!self) { return nil; }
    
    if (![aDict[BMNoteUUIDStringKey] ntv_getUUIDBytes:&uuidBytes]) {
        NSLog(@"NoteBookmark init: supplied bad uuidString");
		[self release];
		return (self = nil);
	}
    
    searchString = [aDict[BMSearchStringKey] copy];
    
    return self;
}

- (id)initWithNoteUUIDBytes:(CFUUIDBytes)bytes searchString:(NSString*)aString {
	self = [super init];
	if (!self) { return nil; }

	uuidBytes = bytes;
	searchString = [aString copy];
	
	return self;
}

- (id)initWithNoteObject:(NoteObject*)aNote searchString:(NSString*)aString {
	if (!aNote) {
		NSLog(@"NoteBookmark init: supplied nil note");
		[self release];
		return (self = nil);
	}

	self = [super init];
	if (!self) { return nil; }
    
    if (!NTVSynchronizedNoteGetUUIDBytes(aNote, &uuidBytes)) {
        NSLog(@"NoteBookmark init: no cfuuidbytes pointer from note %@", titleOfNote(aNote));
        [self release];
        return (self = nil);
    }
    
    searchString = [aString copy];
    noteObject = [aNote retain];

	return self;
}

- (void)dealloc {
	[searchString release];
	[noteObject release];
	
	[super dealloc];
}

- (NSString*)searchString {
	return searchString;
}

- (void)validateNoteObject {
	NoteObject *newNote = nil;
	
	//if we already had a valid note and our uuidBytes don't resolve to the same note
	//then use that new note from the delegate. in 100% of the cases newNote should be nil
	if (noteObject && (newNote = [delegate noteWithUUIDBytes:uuidBytes]) != noteObject) {
		[noteObject release];
		noteObject = [newNote retain];
	}
}

- (NoteObject*)noteObject {
	if (!noteObject) noteObject = [[delegate noteWithUUIDBytes:uuidBytes] retain];
	return noteObject;
}
- (NSDictionary*)dictionaryRep {
	return @{
		BMSearchStringKey: searchString,
        BMNoteUUIDStringKey: [NSString ntv_UUIDStringForBytes:&uuidBytes]
	};
}

- (NSString *)description {
	NoteObject *note = [self noteObject];
	if (note) {
		return [searchString length] ? [NSString stringWithFormat:@"%@ [%@]", note.title, searchString] : note.title;
	}
	return nil;
}

- (void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

- (id)delegate {
	return delegate;
}

- (BOOL)isEqual:(id)anObject {
    return noteObject == [anObject noteObject];
}
- (NSUInteger)hash {
    return (NSUInteger)noteObject;
}

@end


#define MovedBookmarksType @"NVMovedBookmarksType"

@implementation BookmarksController

- (id)init {
	self = [super init];
	if (!self) { return nil; }

	bookmarks = [[NSMutableArray alloc] init];
	isSelectingProgrammatically = isRestoringSearch = NO;
	
	prefsController = [GlobalPrefs defaultPrefs];

	return self;
}

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) 
												   name:NSTableViewSelectionDidChangeNotification object:bookmarksTableView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) 
												 name:NSTableViewSelectionIsChangingNotification object:bookmarksTableView];
//	[window setFloatingPanel:YES];
	[window setDelegate:self];
	[bookmarksTableView setDelegate:self];
	[bookmarksTableView setTarget:self];
	[bookmarksTableView setDoubleAction:@selector(doubleClicked:)];
	
	[bookmarksTableView registerForDraggedTypes:@[MovedBookmarksType]];
}

- (void)dealloc {
	[window setDelegate:nil];
	[bookmarksTableView setDelegate:nil];
	[bookmarks makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
	
	[bookmarks release];
	[super dealloc];
}

- (id)initWithBookmarks:(NSArray*)array {
	self = [self init];
	if (!self) { return nil; }

	for (NSDictionary *dict in array) {
		NoteBookmark *bookmark = [[NoteBookmark alloc] initWithDictionary:dict];
		[bookmark setDelegate:self];
		[bookmarks addObject:bookmark];
		[bookmark release];
	}

	return self;
}

- (NSArray *)dictionaryReps {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[bookmarks count]];
	for (NoteBookmark *bookmark in bookmarks) {
		NSDictionary *dict = [bookmark dictionaryRep];
		if (dict) [array addObject:dict];
	}
	return array;
}

- (id)dataSource {
	return dataSource;
}
- (void)setDataSource:(id)aDataSource {
	dataSource = aDataSource;
	
	[bookmarks makeObjectsPerformSelector:@selector(validateNoteObject)];
}

- (NoteObject*)noteWithUUIDBytes:(CFUUIDBytes)bytes {

	return [dataSource noteForUUIDBytes:&bytes];	
}

- (void)removeBookmarkForNote:(NoteObject*)aNote {
	NSUInteger index = [bookmarks indexOfObjectPassingTest:^BOOL(NoteBookmark *bookmark, NSUInteger idx, BOOL *stop) {
		return [[bookmark noteObject] isEqual:aNote];
	}];

	if (index == NSNotFound) { return; }

	[bookmarks removeObjectAtIndex:index];

	[self updateBookmarksUI];
}


- (void)regenerateBookmarksMenu {
	
	NSMenu *menu = [NSApp mainMenu];
	NSMenu *bookmarksMenu = [[menu itemWithTag:103] submenu];
	while ([bookmarksMenu numberOfItems]) {
		[bookmarksMenu removeItemAtIndex:0];
	}
	
	
	NSMenu *menu2 = [appController statBarMenu];
	NSMenu *bkSubMenu = [[menu2  itemWithTag:901] submenu];
	while ([bkSubMenu numberOfItems]) {
		[bkSubMenu removeItemAtIndex:0];
	}
		
	NSMenuItem *theMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show Bookmarks",@"menu item title for showing bookmarks")
														  action:@selector(showBookmarks:) keyEquivalent:@"0"] autorelease];
	[theMenuItem setTarget:self];
	[bookmarksMenu addItem:theMenuItem];
	theMenuItem = [theMenuItem copy];
	[bkSubMenu addItem:theMenuItem];
	[theMenuItem release];
	[bookmarksMenu addItem:[NSMenuItem separatorItem]];
	[bkSubMenu addItem:[NSMenuItem separatorItem]];
		
	theMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add to Bookmarks",@"menu item title for bookmarking a note") 
											  action:@selector(addBookmark:) keyEquivalent:@"D"] autorelease];
	[theMenuItem setTarget:self];
	[bookmarksMenu addItem:theMenuItem];
	theMenuItem = [theMenuItem copy];
	[bkSubMenu addItem:theMenuItem];
	[theMenuItem release];
	
	if ([bookmarks count] > 0) {
		[bookmarksMenu addItem:[NSMenuItem separatorItem]];
		[bkSubMenu addItem:[NSMenuItem separatorItem]];
	}

	[bookmarks enumerateObjectsUsingBlock:^(NoteBookmark *bookmark, NSUInteger i, BOOL *stop) {
		NSString *description = [bookmark description];
		if (!description.length) { return; }

		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:description action:@selector(restoreBookmark:)
													keyEquivalent:[NSString stringWithFormat:@"%lu", (unsigned long)((i % 9) + 1)]] autorelease];
		if (i > 8) [menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
		if (i > 17) [menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask | NSControlKeyMask];
		[menuItem setRepresentedObject:bookmark];
		[menuItem setTarget:self];
		[bookmarksMenu addItem:menuItem];
		[bkSubMenu addItem:[[menuItem copy] autorelease]];
		[menuItem release];
	}];
}

- (void)updateBookmarksUI {
	
	[prefsController saveCurrentBookmarksFromSender:self];
	
	[self regenerateBookmarksMenu];
	
	[bookmarksTableView reloadData];
}

- (void)selectBookmarkInTableView:(NoteBookmark*)bookmark {
	if (bookmarksTableView && bookmark) {
		//find bookmark index and select
		NSUInteger bmIndex = [bookmarks indexOfObjectIdenticalTo:bookmark];
		if (bmIndex != NSNotFound) {
			isSelectingProgrammatically = YES;
			[bookmarksTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:bmIndex] byExtendingSelection:NO];
			isSelectingProgrammatically = NO;
			[removeBookmarkButton setEnabled:YES];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
	//need to fix this for better style detection
	
	SEL action = [menuItem action];
	if (action == @selector(addBookmark:)) {
		
		return ([bookmarks count] < 27 && [appController selectedNoteObject]);
	}
	
	return YES;
}

- (BOOL)restoreNoteBookmark:(NoteBookmark*)bookmark inBackground:(BOOL)inBG{
	if (bookmark) {

		if (currentBookmark != bookmark) {
			[currentBookmark autorelease];
			currentBookmark = [bookmark retain];
		}
		
		//communicate with revealer here--tell it to search for this string and highlight note
		isRestoringSearch = YES;
		
		//BOOL inBG = ([[window currentEvent] modifierFlags] & NSCommandKeyMask) == 0;
		[appController bookmarksController:self restoreNoteBookmark:bookmark inBackground:inBG];
		[self selectBookmarkInTableView:bookmark];
		
		isRestoringSearch = NO;

		return YES;
	}
	return NO;
}

- (void)restoreBookmark:(id)sender {
	[self restoreNoteBookmark:[sender representedObject] inBackground:NO];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"description"]) {
		NSString *description = [bookmarks[rowIndex] description];
		if (description) 
			return description;
		return [NSString stringWithFormat:NSLocalizedString(@"(Unknown Note) [%@]",nil), [bookmarks[rowIndex] searchString]];
	}
	
	static NSString *shiftCharStr = nil, *cmdCharStr = nil, *ctrlCharStr = nil;
	if (!cmdCharStr) {
		unichar ch = 0x2318;
		cmdCharStr = [[NSString stringWithCharacters:&ch length:1] retain];
		ch = 0x21E7;
		shiftCharStr = [[NSString stringWithCharacters:&ch length:1] retain];
		ch = 0x2303;
		ctrlCharStr = [[NSString stringWithCharacters:&ch length:1] retain];
	}
	
	return [NSString stringWithFormat:@"%@%@%@ %ld", rowIndex > 17 ? ctrlCharStr : @"", rowIndex > 8 ? shiftCharStr : @"", cmdCharStr, (rowIndex % 9) + 1];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return dataSource ? [bookmarks count] : 0;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

- (void)doubleClicked:(id)sender {
	NSInteger row = [bookmarksTableView selectedRow];
	if (row > -1) [self restoreNoteBookmark:bookmarks[row] inBackground:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (!isRestoringSearch && !isSelectingProgrammatically) {
		NSInteger row = [bookmarksTableView selectedRow];
		if (row > -1) {
			if (bookmarks[row] != currentBookmark) {
				[self restoreNoteBookmark:bookmarks[row] inBackground:YES];
			}
		}
		
		[removeBookmarkButton setEnabled: row > -1];
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	NSArray *typesArray = @[MovedBookmarksType];

	[pboard declareTypes:typesArray owner:self];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:MovedBookmarksType];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op {
    
    NSDragOperation dragOp = ([info draggingSource] == bookmarksTableView) ? NSDragOperationMove : NSDragOperationCopy;
	
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    if (row < 0)
		row = 0;
    
    if ([info draggingSource] == bookmarksTableView) {
		NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:MovedBookmarksType]];
		NSInteger theRow = [indexes firstIndex];
		
		id object = [bookmarks[theRow] retain];
		
		if (row != theRow + 1 && row != theRow) {
			NoteBookmark* selectedBookmark = nil;
			NSInteger selRow = [bookmarksTableView selectedRow];
			if (selRow > -1) selectedBookmark = bookmarks[selRow];
			
			if (row < theRow)
				[bookmarks removeObjectAtIndex:theRow];
			
			if (row <= (int)[bookmarks count])
				[bookmarks insertObject:object atIndex:row];
			else
				[bookmarks addObject:object];
			
			if (row > theRow)
				[bookmarks removeObjectAtIndex:theRow];
			
			[object release];
			
			[self updateBookmarksUI];
			[self selectBookmarkInTableView:selectedBookmark];
			
			return YES;
		}
		[object release];
		return NO;
    }
	
	return NO;
}

- (CGRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(CGRect)defaultFrame {
	
	CGFloat oldHeight = 0.0;
	CGFloat newHeight = 0.0;
	NSRect newFrame = [sender frame];
	NSSize intercellSpacing = [bookmarksTableView intercellSpacing];
	
	newHeight = MAX(1, [bookmarksTableView numberOfRows]) * ([bookmarksTableView rowHeight] + intercellSpacing.height);
	oldHeight = [[[bookmarksTableView enclosingScrollView] contentView] frame].size.height;
	newHeight = [sender frame].size.height - oldHeight + newHeight;
	
	//adjust origin so the window sticks to the upper left
	newFrame.origin.y = newFrame.origin.y + newFrame.size.height - newHeight;
	
	newFrame.size.height = newHeight;
	return newFrame;
}

- (void)windowWillClose:(NSNotification *)notification {
	[showHideBookmarksItem setAction:@selector(showBookmarks:)];
	[showHideBookmarksItem setTitle:NSLocalizedString(@"Show Bookmarks",@"menu item title")];
}

- (BOOL)isVisible {
	return [window isVisible];
}

- (void)hideBookmarks:(id)sender {
	
	[window close];	
}

- (void)restoreWindowFromSave {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BookmarksVisible"]) {
		[self loadWindowIfNecessary];
		[window orderBack:nil];
	}
}

- (void)loadWindowIfNecessary {
	if (!window) {
		if (![NSBundle loadNibNamed:@"SavedSearches" owner:self])  {
			NSLog(@"Failed to load SavedSearches.nib");
			NSBeep();
			return;
		}
		[bookmarksTableView setDataSource:self];
		[bookmarksTableView reloadData];
	}	
}

- (void)showBookmarks:(id)sender {
	[self loadWindowIfNecessary];
	
	[bookmarksTableView reloadData];
	[window makeKeyAndOrderFront:self];
	
	[showHideBookmarksItem release];
	showHideBookmarksItem = [sender retain];
	[sender setAction:@selector(hideBookmarks:)];
	[sender setTitle:NSLocalizedString(@"Hide Bookmarks",@"menu item title")];

	//highlight searches as appropriate while the window is open
	//selecting a search restores it
}

- (void)clearAllBookmarks:(id)sender {
	if (NSRunAlertPanel(NSLocalizedString(@"Remove all bookmarks?",@"alert title when clearing bookmarks"), 
						NSLocalizedString(@"You cannot undo this action.",nil), 
						NSLocalizedString(@"Remove All Bookmarks",nil), NSLocalizedString(@"Cancel",nil), NULL) == NSAlertDefaultReturn) {

		[bookmarks removeAllObjects];
	
		[self updateBookmarksUI];
	}
}

- (void)addBookmark:(id)sender {
	
	if (![appController selectedNoteObject]) {
		
		NSRunAlertPanel(NSLocalizedString(@"No note selected.",@"alert title when bookmarking no note"), NSLocalizedString(@"You must select a note before it can be added as a bookmark.",nil), NSLocalizedString(@"OK",nil), nil, NULL);
		
	} else if ([bookmarks count] < 27) {
		NSString *newString = [[appController fieldSearchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];		
		
		NoteBookmark *bookmark = [[NoteBookmark alloc] initWithNoteObject:[appController selectedNoteObject] searchString:newString];
		if (bookmark!=nil) {
			NSUInteger existingIndex = [bookmarks indexOfObject:bookmark];
			if (existingIndex != NSNotFound) {
				//show them what they've already got
                
				NoteBookmark *existingBookmark = bookmarks[existingIndex];
				if ([window isVisible]) [self selectBookmarkInTableView:existingBookmark];
			} else {
				[bookmark setDelegate:self];
				[bookmarks addObject:bookmark];
				[self updateBookmarksUI];
				if ([window isVisible]) [self selectBookmarkInTableView:bookmark];
			}
        }
        [bookmark release];
	} else {
		//there are only so many numbers and modifiers
		NSRunAlertPanel(NSLocalizedString(@"Too many bookmarks.",nil), NSLocalizedString(@"You cannot create more than 26 bookmarks. Try removing some first.",nil), NSLocalizedString(@"OK",nil), nil, NULL);
	}
}

- (void)removeBookmark:(id)sender {
	
	NoteBookmark *bookmark = nil;
	NSInteger row = [bookmarksTableView selectedRow];
	if (row > -1) {
		bookmark = bookmarks[row];
		[bookmarks removeObjectIdenticalTo:bookmark];
		[self updateBookmarksUI];
	}
}

- (AppController*)appController {
	return appController;
}
- (void)setAppController:(id)aDelegate {
	appController = aDelegate;
}

@end
