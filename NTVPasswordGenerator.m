//
//  NTVPasswordGenerator.h
//  Notation
//
//  Created by Brian Bergstrand on 9/27/2009.
//  Copyright 2009 Brian Bergstrand. All rights reserved.
//

#import "NTVPasswordGenerator.h"
#import "NSArray+NTVFunctional.h"

static const char nvDecimalSet[] = "0123456789";
static const size_t nvDecimalSetLength = sizeof(nvDecimalSet) / sizeof(char);

static const char nvLowerCaseSet[] = "abcdefghijklmnopqrstuvwxyz";
static const size_t nvLowerCaseSetLength = sizeof(nvLowerCaseSet) / sizeof(char);

static const char nvUpperCaseSet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static const size_t nvUpperCaseSetLength = sizeof(nvUpperCaseSet) / sizeof(char);

static const char nvSymbolSet[] = "!@#$%^&*()-+=?/<>";
static const size_t nvSymbolSetLength = sizeof(nvSymbolSet) / sizeof(char);

static const struct {
	const char *const set;
	const size_t length;
} setInfos[] = {
	[NTVPasswordSetNumeric] = { nvDecimalSet, nvDecimalSetLength },
	[NTVPasswordSetAlpha] = { nvLowerCaseSet, nvLowerCaseSetLength },
	[NTVPasswordSetMixedCase] = { nvUpperCaseSet, nvUpperCaseSetLength },
	[NTVPasswordSetSymbol] = { nvSymbolSet, nvSymbolSetLength },
};

@implementation NTVPasswordGenerator

+ (NSString *)passwordWithLength:(NSUInteger)length options:(NTVPasswordOptions)options
{
	size_t srcLen = 0;
	for (NTVPasswordSet i = 0; i < NTVPasswordSetCount; i++) {
		NTVPasswordOptions mask = (1 << i);
		if (!(options & mask)) { continue; }
		srcLen += setInfos[i].length;
	}
	if (!srcLen) return @"";

	char src[srcLen+1];
	src[0] = '\0';

	for (NTVPasswordSet i = 0; i < NTVPasswordSetCount; i++) {
		NTVPasswordOptions mask = (1 << i);
		if (!(options & mask)) { continue; }
		strlcat(src, setInfos[i].set, srcLen+1);
	}

	src[srcLen] = '\0';

	NSLog(@"%@", @(src));

	BOOL dupes = !!(options & NTVPasswordAllowDuplicates);
	char(^nextchar)(char *, const char *, size_t) = ^(char *gen, const char *source, size_t sourceLen){
		char c = '\0';
		do {
			size_t idx = arc4random() % sourceLen;
			c = source[idx];
		} while (!dupes && NULL != strchr(gen, c));
		return c;
	};

	char gen[length+1];
	for (size_t i = 0; i < length; ++i) {
		gen[i] = nextchar(gen, src, srcLen);
	}
	gen[length] = '\0';

	return @(gen);
}

+ (NSString *)passwordWithOptions:(NTVPasswordOptions)options length:(NSUInteger)len
{
	return [self passwordWithLength:len options:options];
}

+ (NSString *)numericPasswordWithLength:(NSUInteger)len
{
	return [NTVPasswordGenerator passwordWithLength:len options:NTVPasswordNumeric];
}

+ (NSString *)alphaNumericPasswordWithLength:(NSUInteger)len
{
	return [NTVPasswordGenerator passwordWithLength:len options:NTVPasswordNumeric|NTVPasswordAlpha|NTVPasswordMixedCase];
}

static NSString *(^const copyLightNumericPassword)(void) = ^{
	return [NTVPasswordGenerator numericPasswordWithLength:6];
};

static NSString *(^const copyLightPassword)(void) = ^{
	return [NTVPasswordGenerator passwordWithLength:6 options:NTVPasswordNumeric|NTVPasswordAlpha|NTVPasswordAllowDuplicates];
};

static NSString *(^const copyMediumPassword)(void) = ^{
	return [NTVPasswordGenerator passwordWithLength:8 options:NTVPasswordNumeric|NTVPasswordAlpha|NTVPasswordMixedCase];
};

static NSString *(^const copyStrongPassword)(void) = ^{
	return [NTVPasswordGenerator passwordWithLength:10 options:NTVPasswordNumeric|NTVPasswordAlpha|NTVPasswordMixedCase|NTVPasswordSymbol];
};

+ (NSString *)lightNumeric
{
	return copyLightNumericPassword();
}

+ (NSString *)light
{
	return copyLightPassword();
}

+ (NSString *)medium
{
	return copyMediumPassword();
}

+ (NSString *)strong
{
	return copyStrongPassword();
}

+ (NSArray *)suggestions
{
	NSArray *blocks = @[ copyStrongPassword, copyMediumPassword, copyLightPassword, copyLightNumericPassword ];
	return [NSArray ntv_arrayWithCount:blocks.count block:^(NSUInteger idx) {
		NSString *(^block)(void) = blocks[idx];
		return block();
	}];
}

@end
