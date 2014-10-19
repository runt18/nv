//
//  NotationSyncServiceManager.h
//  Notation
//
//  Created by Zachary Schneirov on 11/29/09.

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


@import Cocoa;

#import "NotationController.h"
#import "SyncServiceSessionProtocol.h"

@interface NotationController (NotationSyncServiceManager)

- (NSDictionary*)invertedDictionaryOfEntries:(NSArray*)entries keyedBy:(NSString*)keyName;
- (NSDictionary*)invertedDictionaryOfNotes:(NSArray*)someNotes forSession:(id<SyncServiceSession>)aSession;

- (NoteObject*)noteForKey:(NSString*)key ofServiceClass:(Class<SyncServiceSession>)serviceClass;

- (void)processPartialNotesList:(NSArray*)entries withRemovedList:(NSArray*)removedEntries fromSyncSession:(id <SyncServiceSession>)syncSession;
- (void)makeNotesMatchList:(NSArray*)MDEntries fromSyncSession:(id <SyncServiceSession>)syncSession;

- (void)schedulePushToAllSyncServicesForNote:(id <SynchronizedNote>)aNote;

- (void)startSyncServices;
- (void)stopSyncServices;

- (BOOL)handleSyncingWithAllMissingAndRemoteNoteCount:(NSUInteger)foundNotes fromSession:(id <SyncServiceSession>)aSession;

@end
