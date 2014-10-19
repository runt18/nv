//
//  NSCollection_utils.h
//  Notation
//
//  Created by Zachary Schneirov on 1/13/06.

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
@class NoteObject;

@interface NSDictionary (FontTraits)
- (BOOL)attributesHaveFontTrait:(NSFontTraitMask)desiredTrait orAttribute:(NSString*)attrName;
@end

@interface NSMutableDictionary (FontTraits)
- (void)addDesiredAttributesFromDictionary:(NSDictionary*)dict;
- (void)applyStyleInverted:(BOOL)opposite trait:(NSFontTraitMask)trait forFont:(NSFont*)font 
  alternateAttributeName:(NSString*)attrName alternateAttributeValue:(id)value;
@end

@interface NSDictionary (HTTP)

+ (NSDictionary*)optionsDictionaryWithTimeout:(float)timeout;
- (NSString*)URLEncodedString;
@end


@interface NSSet (Utilities)

- (NSMutableSet*)setIntersectedWithSet:(NSSet*)set;

@end

@interface NSSet (Private)
//in Foundation
- (void)getObjects:(id *)aBuffer;
@end

@interface NSArray (NoteUtilities)
- (NSArray*)objectsFromDictionariesForKey:(id)aKey;

@end
