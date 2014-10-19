//
//  NSFileManager_NV.h
//  Notation
//
//  Created by Zachary Schneirov on 12/31/10.

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


@interface NSFileManager (NV)


- (id)getTagsAtFSPath:(const char*)path;
- (BOOL)setTags:(id)plistObject atFSPath:(const char*)path;

- (NSString*)pathCopiedFromAliasData:(NSData*)aliasData;
- (BOOL)setTextEncodingAttribute:(NSStringEncoding)encoding atFSPath:(const char*)path;
- (NSStringEncoding)textEncodingAttributeOfFSPath:(const char*)path;
- (NSString*)pathFromFSPath:(char*)path;
- (NSString*)pathWithFSRef:(FSRef*)fsRef;
- (BOOL)createFolderAtPath:(NSString *)path;
- (BOOL)createFolderAtPath:(NSString *)path withAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesAtPath:(NSString *)path followLink:(BOOL)follow;
- (NSArray *)folderContentsAtPath:(NSString *)path;
- (NSArray *)mergedTagsForFileAtPath:(const char*)path;
- (BOOL)deleteFileAtPath:(NSString *)path;

@end
