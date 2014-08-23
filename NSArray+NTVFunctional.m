//
//  NSArray+NTVFunctional.m
//  Notation
//
//  Created by Zachary Waldowski on 8/23/14.
//  Copyright (c) 2014 elasticthreads. All rights reserved.
//

#import "NSArray+NTVFunctional.h"

@implementation NSArray (NTVFunctional)

+ (instancetype)ntv_arrayWithCount:(NSUInteger)count block:(id(^)(NSUInteger idx))block
{
	__strong id *collected = (__strong id *)calloc(count, sizeof(id));
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	dispatch_apply(count, queue, ^(size_t i) {
		collected[i] = [block(i) retain];
	});

	NSArray *array = [self arrayWithObjects:collected count:count];

	dispatch_async(queue, ^{
		dispatch_apply(count, queue, ^(size_t i) {
			[collected[i] release];
			collected[i] = nil;
		});

		free(collected);
	});

	return array;
}

@end
