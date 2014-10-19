
/*
 * You need to have the OpenSSL header files (as well as the location of their
 * include directory given to Project Builder) for this to compile.  For it
 * to link, add /usr/lib/libcrypto.dylib and /usr/lib/libssl.dylib to the linked
 * frameworks.
 */

/*
 * Compresses/decompresses data using zlib (see RFC 1950 and /usr/include/zlib.h)
 *
 * Be sure to add /usr/lib/libz.dylib to the linked frameworks, or add "-lz" to
 * 'Other Linker Flags' in the 'Linker Settings' section of the target's
 * 'Build Settings'
 *
 */

/* NSData_transformations.m */

#import "NSData_transformations.h"
#include <zlib.h>

#import <WebKit/WebKit.h>

@implementation NSData (NVUtilities)

/*
 * Compress the data, default level of compression
 */
- (NSMutableData *)compressedData {
	return [self compressedDataAtLevel:Z_DEFAULT_COMPRESSION];
}


/*
 * Compress the data at the given compression level; stores the original data
 * size at the end of the compressed data
 */
- (NSMutableData *)compressedDataAtLevel:(int)level {
	
	NSMutableData *newData;
	size_t bufferLength;
	int zlibError;
	
	/*
	 * zlib says to make sure the destination has 0.1% more + 12 bytes; last
	 * additional bytes to store the original size (needed for uncompress)
	 */
	bufferLength = (size_t)ceilf([self length] * 1.001 ) + 12 + sizeof(unsigned);
	newData = [NSMutableData dataWithLength:bufferLength];
	if( newData != nil ) {
		zlibError = compress2([newData mutableBytes], &bufferLength,
							   [self bytes], [self length], level);
		if (zlibError == Z_OK) {
			// Add original size to the end of the buffer, written big-endian
			*( (unsigned *) ([newData mutableBytes] + bufferLength) ) =
            NSSwapHostIntToBig((unsigned)[self length] );
			[newData setLength:bufferLength + sizeof(unsigned)];
		} else {
			NSLog(@"error compressing: %s", zError(zlibError));
			newData = nil;
		}
	} else
		NSLog(@"error compressing: couldn't allocate memory");
	
	return newData;
}


/*
 * Decompress data
 */
- (NSMutableData *) uncompressedData {
	
	NSMutableData *newData;
	unsigned originalSize;
	unsigned long outSize;
	int zlibError;
	
	newData = nil;
	if ( [self isCompressedFormat] ) {
		originalSize = NSSwapBigIntToHost(*((unsigned *) ([self bytes] + [self length] - sizeof(unsigned))));
		
		//catch the NSInvalidArgumentException that's thrown if originalSize is too large
		NS_DURING
			newData = [ NSMutableData dataWithLength:originalSize ];
		NS_HANDLER
			if ([[localException name] isEqualToString:NSInvalidArgumentException] ) {
				NSLog(@"error decompressing--bad size: %@", [localException reason]);
				NS_VALUERETURN( nil, NSMutableData * );
			} else
				[localException raise];   // This should NEVER happen...
		NS_ENDHANDLER
		
		if( newData != nil ) {
			outSize = originalSize;
			zlibError = uncompress([newData mutableBytes], &outSize, [self bytes], [self length] - sizeof(unsigned));
			if( zlibError != Z_OK ) {
				NSLog(@"decompression failed: %s", zError(zlibError));
				newData = nil;
			} else if (originalSize != outSize)
				NSLog(@"error decompressing: extracted size %lu does not match original of %u", outSize, originalSize);
		} else
			NSLog(@"error allocating memory while decompressing");
	} else
		NSLog(@"error decompressing: data does not seem to be compressed with zlib");
	
	return newData;
}


/*
 * Quick check of the data to avoid obviously-not-compressed data (see RFC)
 */
- (BOOL)isCompressedFormat {
	const unsigned char *bytes;
	
	bytes = [self bytes];
	/*
	 * The checks are:
	 *    ( *bytes & 0x0F ) == 8           : method is deflate (this is called CM compression method, in the RFC)
	 *    ( *bytes & 0x80 ) == 0           : info must be at most seven, this makes sure the MSB is not set, otherwise it
	 *                                       is at least 8 (this is called CINFO, compression info, in the RFC)
	 *    *( (short *) bytes ) ) % 31 == 0 : the two first bytes as a whole (big endian format) must be a multiple of 31
	 *                                       (this is discussed in the FCHECK in FLG, flags, section)
	 */
	if( ( *bytes & 0x0F ) == 8 && ( *bytes & 0x80 ) == 0 &&
		NSSwapBigShortToHost( *( (short *) bytes ) ) % 31 == 0 )
		return YES;
	
	return NO;
}

- (uint32_t)CRC32 {
	uLong crc = crc32(0L, Z_NULL, 0);
    return (uint32_t)crc32(crc, [self bytes], (uInt)[self length]);
}

- (NSString*)pathURLFromWebArchive {

	WebResource *resource = [[[[WebArchive alloc] initWithData:self] autorelease] mainResource];
	NSURL *url = [resource URL];
	
	//it's not any kind of URL we want to keep
	//this is probably text from another app's internal WebKit view
	if ([[url scheme] isEqualToString:@"applewebdata"] || [[url scheme] isEqualToString:@"x-msg"])
		return nil;
	
	return [url absoluteString];
}

- (BOOL)fsRefAsAlias:(FSRef*)fsRef {
    AliasHandle aliasHandle;
    Boolean changedThrownAway;
    
    if (self && PtrToHand([self bytes], (Handle*)&aliasHandle, [self length]) == noErr) {
		
		if (FSResolveAliasWithMountFlags(NULL, aliasHandle, fsRef, &changedThrownAway, kResolveAliasFileNoUI) == noErr)
			return YES;
    }
	
    return NO;
}

+ (NSData*)uncachedDataFromFile:(NSString*)filename {
			
	return [NSData dataWithContentsOfFile:filename options:NSUncachedRead error:NULL];
}

+ (NSData*)aliasDataForFSRef:(FSRef*)fsRef {
    
    FSRef userHomeFoundRef, *relativeRef = &userHomeFoundRef;
    
    OSErr err = FSFindFolder(kUserDomain, kCurrentUserFolderType, kCreateFolder, &userHomeFoundRef);
    if (err != noErr) {
		relativeRef = NULL;
		NSLog(@"FSFindFolder error: %d", err);
    }
    
    AliasHandle aliasHandle;
    NSData *theData = nil;
    
    //fill handle from fsref, storing path relative to user directory
    if (FSNewAlias(relativeRef, fsRef, &aliasHandle) == noErr && aliasHandle != NULL) {
		HLock((Handle)aliasHandle);
		theData = [NSData dataWithBytes:*aliasHandle length:GetHandleSize((Handle) aliasHandle)];
		HUnlock((Handle)aliasHandle);
    }
    
    return theData;
}

// yes, to do the same encoding detection we could use something like initWithContentsOfFile: or
// initWithContentsOfFile:(NSString *)path usedEncoding:(NSStringEncoding *)enc error:(NSError **)error
// but those require file paths.

- (NSMutableString*)newStringUsingBOMReturningEncoding:(NSStringEncoding*)encoding {
	NSUInteger len = [self length];
	NSMutableString *string = nil;
	
	if (len % 2 != 0 || !len) {
		return nil;
	}
	const unichar byteOrderMark = 0xFEFF;
	const unichar byteOrderMarkSwapped = 0xFFFE;
	
	BOOL foundBOM = NO;
	BOOL swapped = NO;
	unsigned char *b = (unsigned char*)[self bytes];
	unichar *uptr = (unichar*)b;
	
	if (*uptr == byteOrderMark) {
		b = (unsigned char*)++uptr;
		len -= sizeof(unichar);
		foundBOM = YES;
	} else if (*uptr == byteOrderMarkSwapped) {
		b = (unsigned char*)++uptr;
		len -= sizeof(unichar);
		swapped = YES;
		foundBOM = YES;
	} else if (len > 2 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
		len -= 3;
		b += 3;
		
		//false because we just fixed the BOM right up there
		//string = (NSString*)CFStringCreateWithBytes(kCFAllocatorDefault, b, len, kCFStringEncodingUTF8, false);
		string = [[NSMutableString alloc] initWithBytes:b length:len encoding:NSUTF8StringEncoding];
		if (string)
			*encoding = NSUTF8StringEncoding;
		
		return string;
	}
	
	if (foundBOM) {
		unsigned char *u = (unsigned char*)malloc(len);
		if (swapped) {
			unsigned i;
			
			for (i = 0; i < len; i += 2) {
				u[i] = b[i + 1];
				u[i + 1] = b[i];
			}
		} else {
			memcpy(u, b, len);
		}
		
		
		string = (NSMutableString*)CFStringCreateMutableWithExternalCharactersNoCopy(NULL, (UniChar *)u, (CFIndex)len/2, (CFIndex)len/2, kCFAllocatorDefault);
		if (string)
			*encoding = NSUnicodeStringEncoding;
		return string;
	}
	
	return nil;
}

@end
