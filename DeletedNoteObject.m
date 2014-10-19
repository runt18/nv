//
//  DeletedNoteObject.m
//  Notation
//
//  Created by Zachary Schneirov on 4/16/06.

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


#import "DeletedNoteObject.h"
#import "NSString_NV.h"
#import "CFUUID+NTVAdditions.h"

@implementation DeletedNoteObject {
    CFUUIDBytes uniqueNoteIDBytes;
    NSMutableDictionary *syncServicesMD;
}

@synthesize originalNote = originalNote;
@synthesize logSequenceNumber = logSequenceNumber;
@synthesize syncServicesMD = syncServicesMD;

- (instancetype)initWithOriginalNote:(id<SynchronizedNote>)note {
	self = [super init];
	if (!self) { return nil; }

    NTVSynchronizedNoteGetUUIDBytes(note, &uniqueNoteIDBytes);
	syncServicesMD = [[note syncServicesMD] mutableCopy];
	logSequenceNumber = [note logSequenceNumber];
	//not serialized: for runtime lookup purposes only
	originalNote = [note retain];

	return self;
}

- (id)initWithCoder:(NSCoder*)decoder {
	self = [super init];
	if (!self) { return nil; }

	if ([decoder allowsKeyedCoding]) {
		NSUInteger decodedByteCount;
		const uint8_t *decodedBytes = [decoder decodeBytesForKey:VAR_STR(uniqueNoteIDBytes) returnedLength:&decodedByteCount];
		memcpy(&uniqueNoteIDBytes, decodedBytes, MIN(decodedByteCount, sizeof(CFUUIDBytes)));
		syncServicesMD = [[decoder decodeObjectForKey:VAR_STR(syncServicesMD)] retain];
		logSequenceNumber = [decoder decodeInt32ForKey:VAR_STR(logSequenceNumber)];
	} else {
		[decoder decodeValueOfObjCType:@encode(CFUUIDBytes) at:&uniqueNoteIDBytes];
		syncServicesMD = [[decoder decodeObject] retain];
		[decoder decodeValueOfObjCType:@encode(unsigned int) at:&logSequenceNumber];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	
	if ([coder allowsKeyedCoding]) {
		[coder encodeBytes:(const uint8_t *)&uniqueNoteIDBytes length:sizeof(CFUUIDBytes) forKey:VAR_STR(uniqueNoteIDBytes)];
		[coder encodeObject:syncServicesMD forKey:VAR_STR(syncServicesMD)];
		[coder encodeInt32:logSequenceNumber forKey:VAR_STR(logSequenceNumber)];
	} else {
		[coder encodeValueOfObjCType:@encode(CFUUIDBytes) at:&uniqueNoteIDBytes];
		[coder encodeObject:syncServicesMD];
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&logSequenceNumber];
	}
}

- (NSString*)description {
	return [NSString stringWithFormat:@"DeletedNoteObj(%@) %@", [NSString ntv_UUIDStringForBytes:&uniqueNoteIDBytes], syncServicesMD];
}

- (void)setSyncObjectAndKeyMD:(NSDictionary*)aDict forService:(NSString*)serviceName {
    NSMutableDictionary *dict = syncServicesMD[serviceName];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] initWithDictionary:aDict];
        if (!syncServicesMD) syncServicesMD = [[NSMutableDictionary alloc] init];
        syncServicesMD[serviceName] = dict;
        [dict release];
    } else {
        [dict addEntriesFromDictionary:aDict];
    }
}
- (void)removeAllSyncMDForService:(NSString*)serviceName {
    [syncServicesMD removeObjectForKey:serviceName];
}
- (const CFUUIDBytes *)uniqueNoteIDBytes {
    return &uniqueNoteIDBytes;
}

- (void)incrementLSN {
    logSequenceNumber++;
}

- (NSUInteger)hash {
    return NTVUUIDBytesGetHash(&uniqueNoteIDBytes);
}

- (BOOL)isEqual:(id <SynchronizedNote>)otherNote {
    return NTVSynchronizedNoteIsEqual(self, otherNote);
}

- (void)dealloc {
	[syncServicesMD release];
	[originalNote release];
	[super dealloc];
}

@end
