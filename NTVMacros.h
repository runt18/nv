//
//  NTVMacros.h
//  Notation
//
//  Created by Zachary Waldowski on 8/23/14.
//  Copyright (c) 2014 ElasticThreads. All rights reserved.
//

#ifndef NTV_MACROS
#define NTV_MACROS

#import <Foundation/Foundation.h>

@class AppController;

NS_INLINE AppController *NTVAppDelegate(void) {
	return (AppController *)[NSApp delegate];
}

NS_INLINE BOOL NTVFloatsEqual(CGFloat a, CGFloat b) {
#if CGFLOAT_IS_DOUBLE
    return fabs(a - b) < DBL_EPSILON;
#else
    return fabsf(a - b) < FLT_EPSILON;
#endif
}

#endif /* !NTV_MACROS */
