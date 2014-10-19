//
//  NSString_NV.h
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

#import <Cocoa/Cocoa.h>
@class NoteObject;

@interface NSString (NV)

unsigned int hoursFromAbsoluteTime(CFAbsoluteTime absTime);
void resetCurrentDayTime();
+ (NSString*)relativeTimeStringWithDate:(CFDateRef)date relativeDay:(int)day;
+ (NSString*)relativeDateStringWithAbsoluteTime:(CFAbsoluteTime)absTime;
CFDateFormatterRef simplenoteDateFormatter(int lowPrecision);
+ (NSString*)simplenoteDateWithAbsoluteTime:(CFAbsoluteTime)absTime;
- (CFAbsoluteTime)absoluteTimeFromSimplenoteDate;
- (CFArrayRef)copyRangesOfWordsInString:(NSString*)findString inRange:(NSRange)limitRange;
+ (NSString*)customPasteboardTypeOfCode:(int)code;
- (NSString*)stringAsSafePathExtension;
- (NSString*)filenameExpectingAdditionalCharCount:(NSUInteger)charCount;

- (NSString*)fourCharTypeString;
- (BOOL)isAMachineDirective;
- (void)copyItemToPasteboard:(id)sender;
- (NSString*)syntheticTitleAndSeparatorWithContext:(NSString**)sepStr bodyLoc:(NSUInteger*)bodyLoc maxTitleLen:(NSUInteger)maxTitleLen;
- (NSString*)syntheticTitleAndSeparatorWithContext:(NSString**)sepStr bodyLoc:(NSUInteger*)bodyLoc 
										  oldTitle:(NSString*)oldTitle maxTitleLen:(NSUInteger)maxTitleLen;
- (NSString*)syntheticTitleAndTrimmedBody:(NSString**)newBody;
+ (NSString *)tabbifiedStringWithNumberOfSpaces:(NSInteger)origNumSpaces tabWidth:(NSInteger)tabWidth usesTabs:(BOOL)usesTabs;
- (NSInteger)numberOfLeadingSpacesFromRange:(NSRange *)range tabWidth:(NSInteger)tabWidth;

	BOOL IsHardLineBreakUnichar(unichar uchar, NSString *str, unsigned charIndex);

- (char*)copyLowercaseASCIIString;
- (const char*)lowercaseUTF8String;
- (NSString*)stringWithPercentEscapes;
- (NSString *)stringByReplacingPercentEscapes;
- (BOOL)superficiallyResemblesAnHTTPURL;
+ (NSString*)reasonStringFromCarbonFSError:(OSStatus)err;

- (NSArray*)labelCompatibleWords;

- (BOOL)UTIOfFileConformsToType:(NSString*)type;

- (CFUUIDBytes)uuidBytes;
+ (NSString*)uuidStringWithBytes:(CFUUIDBytes)bytes;

- (NSString *)firstNumberFromStringWithinRange:(NSRange)subRange isInRange:(NSRange *)foundRange;
- (NSInteger)isPairedCharacterWithMatchString:(NSString **)matchString;
//- (NSTextView*)textViewWithFrame:(NSRect*)theFrame;

@end

@interface NSMutableString (NV)
- (void)replaceTabsWithSpacesOfWidth:(NSInteger)tabWidth;
+ (NSMutableString*)newShortLivedStringFromFile:(NSString*)filename;
+ (NSMutableString*)newShortLivedStringFromData:(NSMutableData*)data ofGuessedEncoding:(NSStringEncoding*)encoding 
									   withPath:(const char*)aPath orWithFSRef:(const FSRef*)fsRef;
@end

@interface NSScanner (NV)
- (void)scanContextualSeparator:(NSString**)sepStr withPrecedingString:(NSString*)firstLine;
@end

@interface NSCharacterSet (NV)
+ (NSCharacterSet*)labelSeparatorCharacterSet;
+ (NSCharacterSet*)listBulletsCharacterSet;

@end


@interface NSEvent (NV)
- (unichar)firstCharacter;
- (unichar)firstCharacterIgnoringModifiers;
@end
