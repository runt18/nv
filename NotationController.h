//
//  NotationController.h
//  Notation
//
//  Created by Zachary Schneirov on 12/19/05.

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


#import <Cocoa/Cocoa.h>
#import "FastListDataSource.h"
#import "LabelsListController.h"
#import "WALController.h"

#import <CoreServices/CoreServices.h>

//enum { kUISearch, kUINewNote, kUIDeleteNote, kUIRenameNote, kUILabelOperation };

typedef struct _NoteCatalogEntry {
    UTCDateTime lastModified;
	UTCDateTime lastAttrModified;
    UInt32 logicalSize;
    OSType fileType;
    UInt32 nodeID;
    CFMutableStringRef filename;
    UniChar *filenameChars;
    UniCharCount filenameCharCount;
} NoteCatalogEntry;

@class NoteObject;
@class DeletedNoteObject;
@class SyncSessionController;
@class NotationPrefs;
@class NoteAttributeColumn;
@class NoteBookmark;
@class DeletionManager;
@class GlobalPrefs;

@interface NotationController : NSObject {
    NSMutableArray *allNotes;
    FastListDataSource *notesListDataSource;
    LabelsListController *labelsListController;
	GlobalPrefs *prefsController;
	SyncSessionController *syncSessionController;
	DeletionManager *deletionManager;
	id delegate;
	
	CGFloat titleColumnWidth;
	NoteAttributeColumn* sortColumn;
	
    NoteObject **allNotesBuffer;
	unsigned int allNotesBufferSize;
    
    NSUInteger selectedNoteIndex;
    char *currentFilterStr, *manglingString;
    NSInteger lastWordInFilterStr;
    
	BOOL directoryChangesFound;
    
    NotationPrefs *notationPrefs;
	
	NSMutableSet *deletedNotes;
    
	int volumeSupportsExchangeObjects;
    FSCatalogInfo *fsCatInfoArray;
    HFSUniStr255 *HFSUniNameArray;

	FSEventStreamRef noteDirEventStreamRef;
	BOOL eventStreamStarted;
	    
    size_t catEntriesCount, totalCatEntriesCount;
    NoteCatalogEntry *catalogEntries, **sortedCatalogEntries;
    
	unsigned int lastCheckedDateInHours;
	int lastLayoutStyleGenerated;
    long blockSize;
	struct statfs *statfsInfo;
	NSUInteger diskUUIDIndex;
	CFUUIDRef diskUUID;
    FSRef noteDirectoryRef, noteDatabaseRef;
    AliasHandle aliasHandle;
    BOOL aliasNeedsUpdating;
    OSStatus lastWriteError;
    
    WALStorageController *walWriter;
    NSMutableSet *unwrittenNotes;
	BOOL notesChanged;
	NSTimer *changeWritingTimer;
	NSUndoManager *undoManager;
}

- (id)init;
- (id)initWithAliasData:(NSData*)data error:(OSStatus*)err;
- (id)initWithDefaultDirectoryReturningError:(OSStatus*)err;
- (id)initWithDirectoryRef:(FSRef*)directoryRef error:(OSStatus*)err;
- (void)setAliasNeedsUpdating:(BOOL)needsUpdate;
- (BOOL)aliasNeedsUpdating;
- (NSData*)aliasDataForNoteDirectory;
- (OSStatus)_readAndInitializeSerializedNotes;
- (void)processRecoveredNotes:(NSDictionary*)dict;
- (BOOL)initializeJournaling;
- (void)handleJournalError;
- (void)checkJournalExistence;
- (void)closeJournal;
- (BOOL)flushAllNoteChanges;
- (void)flushEverything;

- (void)mirrorAllOMToFinderTags;

- (void)upgradeDatabaseIfNecessary;

- (id)delegate;
- (void)setDelegate:(id)theDelegate;

- (void)databaseEncryptionSettingsChanged;
- (void)databaseSettingsChangedFromOldFormat:(NSInteger)oldFormat;

- (NSInteger)currentNoteStorageFormat;
- (void)synchronizeNoteChanges:(NSTimer*)timer;

- (void)updateDateStringsIfNecessary;
- (void)makeForegroundTextColorMatchGlobalPrefs;
- (void)setForegroundTextColor:(NSColor*)aColor;
- (void)restyleAllNotes;
- (void)setUndoManager:(NSUndoManager*)anUndoManager;
- (NSUndoManager*)undoManager;
- (void)noteDidNotWrite:(NoteObject*)note errorCode:(OSStatus)error;
- (void)scheduleWriteForNote:(NoteObject*)note;
- (void)closeAllResources;
- (void)trashRemainingNoteFilesInDirectory;
- (void)checkIfNotationIsTrashed;
- (void)updateLinksToNote:(NoteObject*)aNoteObject fromOldName:(NSString*)oldname;
- (void)updateTitlePrefixConnections;
- (void)addNotes:(NSArray*)noteArray;
- (void)addNotesFromSync:(NSArray*)noteArray;
- (void)addNewNote:(NoteObject*)aNoteObject;
- (void)_addNote:(NoteObject*)aNoteObject;
- (void)removeNote:(NoteObject*)aNoteObject;
- (void)removeNotes:(NSArray*)noteArray;
- (void)_purgeAlreadyDistributedDeletedNotes;
- (void)removeSyncMDFromDeletedNotesInSet:(NSSet*)notesToOrphan forService:(NSString*)serviceName;
- (DeletedNoteObject*)_addDeletedNote:(id<SynchronizedNote>)aNote;
- (void)_registerDeletionUndoForNote:(NoteObject*)aNote;
- (NoteObject*)addNoteFromCatalogEntry:(NoteCatalogEntry*)catEntry;

- (BOOL)openFiles:(NSArray*)filenames;

- (void)note:(NoteObject*)note didAddLabelSet:(NSSet*)labelSet;
- (void)note:(NoteObject*)note didRemoveLabelSet:(NSSet*)labelSet;

- (void)filterNotesFromLabelAtIndex:(int)labelIndex;
- (void)filterNotesFromLabelIndexSet:(NSIndexSet*)indexSet;
- (void)updateLabelConnectionsAfterDecoding;

- (void)refilterNotes;
- (BOOL)filterNotesFromString:(NSString*)string;
- (BOOL)filterNotesFromUTF8String:(const char*)searchString forceUncached:(BOOL)forceUncached;
- (NSUInteger)preferredSelectedNoteIndex;
- (NSArray*)noteTitlesPrefixedByString:(NSString*)prefixString indexOfSelectedItem:(NSInteger *)anIndex;
- (NoteObject*)noteObjectAtFilteredIndex:(NSUInteger)noteIndex;
- (NSArray*)notesAtIndexes:(NSIndexSet*)indexSet;
- (NSIndexSet*)indexesOfNotes:(NSArray*)noteSet;
- (NSUInteger)indexInFilteredListForNoteIdenticalTo:(NoteObject*)note;
- (NSUInteger)totalNoteCount;

- (void)scheduleUpdateListForAttribute:(NSString*)attribute;
- (NoteAttributeColumn*)sortColumn;
- (void)setSortColumn:(NoteAttributeColumn*)col;
- (void)resortAllNotes;
- (void)sortAndRedisplayNotes;

- (CGFloat)titleColumnWidth;
- (void)regeneratePreviewsForColumn:(NSTableColumn*)col visibleFilteredRows:(NSRange)rows forceUpdate:(BOOL)force;
- (void)regenerateAllPreviews;

//for setting up the nstableviews
- (id)labelsListDataSource;
- (id)notesListDataSource;

- (NotationPrefs*)notationPrefs;
- (SyncSessionController*)syncSessionController;

- (void)dealloc;

#pragma mark nvALT stuff

- (void)removeNotesAtIndexes:(NSIndexSet *)indexes;
- (NSString *)createCachesFolder;

@end


enum { NVDefaultReveal = 0, NVDoNotChangeScrollPosition = 1, NVOrderFrontWindow = 2, NVEditNoteToReveal = 4 };

@interface NSObject (NotationControllerDelegate)
- (BOOL)notationListShouldChange:(NotationController*)someNotation;
- (void)notationListMightChange:(NotationController*)someNotation;
- (void)notationListDidChange:(NotationController*)someNotation;
- (void)notation:(NotationController*)notation revealNote:(NoteObject*)note options:(NSUInteger)opts;
- (void)notation:(NotationController*)notation revealNotes:(NSArray*)notes;

- (void)contentsUpdatedForNote:(NoteObject*)aNoteObject;
- (void)titleUpdatedForNote:(NoteObject*)aNoteObject;
- (void)rowShouldUpdate:(NSInteger)affectedRow;

@end
