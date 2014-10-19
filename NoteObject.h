//
//  NoteObject.h
//  Notation
//
//  Created by Zachary Schneirov on 12/19/05.

/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
    This file is part of Notational Velocity.

    Notational Velocity is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Notational Velocity is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Notational Velocity.  If not, see <http://www.gnu.org/licenses/>. */


#import <Cocoa/Cocoa.h>
#import "NotationController.h"
#import "BufferUtils.h"
#import "SynchronizedNoteProtocol.h"
#import "NoteAttributeColumn.h"

@class LabelObject;
@class WALStorageController;
@class NotesTableView;
@class ExternalEditor;

typedef struct _NoteFilterContext {
	char* needle;
	BOOL useCachedPositions;
} NoteFilterContext;

@interface NoteObject : NSObject <NSCoding, SynchronizedNote> {
	NSAttributedString *tableTitleString;
	NSMutableAttributedString *contentString;
	
	//caching/searching purposes only -- created at runtime
	char *cTitle, *cContents, *cLabels, *cTitleFoundPtr, *cContentsFoundPtr, *cLabelsFoundPtr;
	NSMutableSet *labelSet;
	BOOL contentsWere7Bit, contentCacheNeedsUpdate;
	//if this note's title is "Chicken Shack menu listing", its prefix parent might have the title "Chicken Shack"
	
//	NSString *wordCountString;
	NSString *dateModifiedString, *dateCreatedString;
	
	id delegate; //the notes controller
	
	//for syncing to text file
	UInt32 nodeID;
	PerDiskInfo *perDiskInfoGroups;
	size_t perDiskInfoGroupCount;
	BOOL shouldWriteToFile, didUnarchive;
	
	//for storing in write-ahead-log
	unsigned int logSequenceNumber;
	
	//not determined until it's time to read to or write from a text file
	FSRef *noteFileRef;
	
	NSMutableDictionary *syncServicesMD;
	
	//more metadata
	NSRange selectedRange;
	
	//each note has its own undo manager--isn't that nice?
	NSUndoManager *undoManager;
@public

	//the first for syncing w/ NV server, as the ID cannot be encrypted
	CFUUIDBytes uniqueNoteIDBytes;
	NSMutableArray *prefixParentNotes;
	NSString *filename;
	NSString *titleString, *labelString;
	UInt32 logicalSize;
	UTCDateTime fileModifiedDate, *attrsModifiedDate;
	NSStringEncoding fileEncoding;
	NSInteger currentFormatID;
	CFAbsoluteTime modifiedDate, createdDate;
}

extern NSComparator const NTVNoteCompareDateModified;
extern NSComparator const NTVNoteCompareDateCreated;
extern NSComparator const NTVNoteCompareLabelString;
extern NSComparator const NTVNoteCompareUniqueIDs;
extern NSComparator const NTVNoteCompareTitle;

extern NSComparator const NTVNoteCompareFilename;
extern NSComparator const NTVNoteCompareNodeID;
extern NSComparator const NTVNoteCompareFileSize;

DEPRECATED_ATTRIBUTE NSInteger compareDateModified(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareDateCreated(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareLabelString(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareTitleString(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareUniqueNoteIDBytes(id *a, id *b);

DEPRECATED_ATTRIBUTE NSInteger compareDateModifiedReverse(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareDateCreatedReverse(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareLabelStringReverse(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareTitleStringReverse(id *a, id *b);

DEPRECATED_ATTRIBUTE NSInteger compareFilename(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareNodeID(id *a, id *b);
DEPRECATED_ATTRIBUTE NSInteger compareFileSize(id *a, id *b);

//syncing w/ server and from journal
- (CFUUIDBytes *)uniqueNoteIDBytes;
- (NSDictionary*)syncServicesMD;
- (unsigned int)logSequenceNumber;
- (void)incrementLSN;

- (BOOL)youngerThanLogObject:(id<SynchronizedNote>)obj;

	//syncing w/ files in directory
	NSInteger storageFormatOfNote(NoteObject *note);
	NSString* filenameOfNote(NoteObject *note);
	UInt32 fileNodeIDOfNote(NoteObject *note);
	UInt32 fileSizeOfNote(NoteObject *note);
	UTCDateTime fileModifiedDateOfNote(NoteObject *note);
	UTCDateTime *attrsModifiedDateOfNote(NoteObject *note);
	CFAbsoluteTime modifiedDateOfNote(NoteObject *note);
	CFAbsoluteTime createdDateOfNote(NoteObject *note);

	NSStringEncoding fileEncodingOfNote(NoteObject *note);
	
	NSString* titleOfNote(NoteObject *note);
	NSString* labelsOfNote(NoteObject *note);

	NSMutableArray* prefixParentsOfNote(NoteObject *note);

#define DefColAttrAccessor(__FName, __IVar) force_inline id __FName(NotesTableView *tv, NoteObject *note, NSInteger row) { return note->__IVar; }
#define DefModelAttrAccessor(__FName, __IVar) force_inline typeof (((NoteObject *)0)->__IVar) __FName(NoteObject *note) { return note->__IVar; }

	//return types are NSString or NSAttributedString, satisifying NSTableDataSource protocol otherwise
	id titleOfNote2(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id tableTitleOfNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id properlyHighlightingTableTitleOfNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id unifiedCellSingleLineForNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id unifiedCellForNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id labelColumnCellForNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id dateCreatedStringOfNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id dateModifiedStringOfNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;
	id wordCountOfNote(NotesTableView *tv, NoteObject *note, NSInteger row) DEPRECATED_ATTRIBUTE;

extern NTVNoteAttributeGetter const NTVNoteUnifiedCellGetter;
extern NTVNoteAttributeGetter const NTVNoteUnifiedCellSingleLineGetter;
extern NTVNoteAttributeGetter const NTVNoteTableTitleGetter;
extern NTVNoteAttributeGetter const NTVNoteHighlightedTableTitleGetter;
extern NTVNoteAttributeGetter const NTVNoteTitleGetter;

extern NTVNoteAttributeGetter const NTVNoteLabelCellGetter;
extern NTVNoteAttributeGetter const NTVNoteDateModifiedStringGetter;
extern NTVNoteAttributeGetter const NTVNoteDateCreatedStringGetter;

	void resetFoundPtrsForNote(NoteObject *note);
	BOOL noteContainsUTF8String(NoteObject *note, NoteFilterContext *context);
	BOOL noteTitleHasPrefixOfUTF8String(NoteObject *note, const char* fullString, size_t stringLen);
	BOOL noteTitleIsAPrefixOfOtherNoteTitle(NoteObject *longerNote, NoteObject *shorterNote);

- (id)delegate;
- (void)setDelegate:(id)theDelegate;
- (id)initWithNoteBody:(NSAttributedString*)bodyText title:(NSString*)aNoteTitle 
			  delegate:(id)aDelegate format:(NSInteger)formatID labels:(NSString*)aLabelString;
- (id)initWithCatalogEntry:(NoteCatalogEntry*)entry delegate:(id)aDelegate;

- (NSSet*)labelSet;
- (void)replaceMatchingLabelSet:(NSSet*)aLabelSet;
- (void)replaceMatchingLabel:(LabelObject*)label;
- (void)updateLabelConnectionsAfterDecoding;
- (void)updateLabelConnections;
- (void)disconnectLabels;
- (BOOL)_setLabelString:(NSString*)newLabelString;
- (void)setLabelString:(NSString*)newLabels;
- (NSMutableSet*)labelSetFromCurrentString;
- (NSArray*)orderedLabelTitles;
- (NSSize)sizeOfLabelBlocks;
- (void)_drawLabelBlocksInRect:(NSRect)aRect rightAlign:(BOOL)onRight highlighted:(BOOL)isHighlighted getSizeOnly:(NSSize*)reqSize;
- (void)drawLabelBlocksInRect:(NSRect)aRect rightAlign:(BOOL)onRight highlighted:(BOOL)isHighlighted;

- (void)setSyncObjectAndKeyMD:(NSDictionary*)aDict forService:(NSString*)serviceName;
- (void)removeAllSyncMDForService:(NSString*)serviceName;
//- (void)removeKey:(NSString*)aKey forService:(NSString*)serviceName;
- (void)updateWithSyncBody:(NSString*)newBody andTitle:(NSString*)newTitle;
- (void)registerModificationWithOwnedServices;

- (OSStatus)writeCurrentFileEncodingToFSRef:(FSRef*)fsRef;
- (void)_setFileEncoding:(NSStringEncoding)encoding;
- (BOOL)setFileEncodingAndReinterpret:(NSStringEncoding)encoding;
- (BOOL)upgradeToUTF8IfUsingSystemEncoding;
- (BOOL)upgradeEncodingToUTF8;
- (BOOL)updateFromFile;
- (BOOL)updateFromCatalogEntry:(NoteCatalogEntry*)catEntry;
- (BOOL)updateFromData:(NSMutableData*)data inFormat:(NSInteger)fmt;

- (OSStatus)writeFileDatesAndUpdateTrackingInfo;

- (void)mirrorTags;

- (NSURL*)uniqueNoteLink;
- (NSString*)noteFilePath;
- (void)invalidateFSRef;

- (BOOL)writeUsingJournal:(WALStorageController*)wal;

- (BOOL)writeUsingCurrentFileFormatIfNecessary;
- (BOOL)writeUsingCurrentFileFormatIfNonExistingOrChanged;
- (BOOL)writeUsingCurrentFileFormat;
- (void)makeNoteDirtyUpdateTime:(BOOL)updateTime updateFile:(BOOL)updateFile;

- (void)moveFileToTrash;
- (void)removeFileFromDirectory;
- (BOOL)removeUsingJournal:(WALStorageController*)wal;

- (OSStatus)exportToDirectoryRef:(FSRef*)directoryRef withFilename:(NSString*)userFilename usingFormat:(NSInteger)storageFormat overwrite:(BOOL)overwrite;
- (NSRange)nextRangeForWords:(NSArray*)words options:(unsigned)opts range:(NSRange)inRange;
- (void)editExternallyUsingEditor:(ExternalEditor*)ed;
- (void)abortEditingInExternalEditor;

- (void)setFilenameFromTitle;
- (void)setFilename:(NSString*)aString withExternalTrigger:(BOOL)externalTrigger;
- (BOOL)_setTitleString:(NSString*)aNewTitle;
- (void)setTitleString:(NSString*)aNewTitle;
- (void)updateTablePreviewString;
- (void)initContentCacheCString;
- (void)updateContentCacheCStringIfNecessary;
- (void)setContentString:(NSAttributedString*)attributedString;
- (NSAttributedString*)contentString;
- (NSAttributedString*)printableStringRelativeToBodyFont:(NSFont*)bodyFont;
- (NSString*)combinedContentWithContextSeparator:(NSString*)sepWContext;
- (void)setForegroundTextColorOnly:(NSColor*)aColor;
- (void)_resanitizeContent;
- (void)updateUnstyledTextWithBaseFont:(NSFont*)baseFont;
- (void)updateDateStrings;
- (void)setDateModified:(CFAbsoluteTime)newTime;
- (void)setDateAdded:(CFAbsoluteTime)newTime;
- (void)setSelectedRange:(NSRange)newRange;
- (NSRange)lastSelectedRange;
- (BOOL)contentsWere7Bit;
- (void)addPrefixParentNote:(NoteObject*)aNote;
- (void)removeAllPrefixParentNotes;
- (void)previewUsingMarked;

- (NSUndoManager*)undoManager;
- (void)_undoManagerDidChange:(NSNotification *)notification;

@end

@interface NSObject (NoteObjectDelegate)
- (void)note:(NoteObject*)note didAddLabelSet:(NSSet*)labelSet;
- (void)note:(NoteObject*)note didRemoveLabelSet:(NSSet*)labelSet;
- (void)note:(NoteObject*)note attributeChanged:(NSString*)attribute;
@end

