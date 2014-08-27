//
//  NTVMacros.h
//  Notation
//
//  Created by Zachary Waldowski on 8/23/14.
//  Copyright (c) 2014 ElasticThreads. All rights reserved.
//

#ifndef NTV_MACROS
#define NTV_MACROS

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

NS_INLINE NSComparator NTVReverseComparator(NSComparator ctor) {
    if (!ctor) { return NULL; };
    return [[^(id one, id two){
        NSComparisonResult result = ctor(one, two);
        if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    } copy] autorelease ];
}

#if !defined(NTVCompare)
#define __NTVCompare__(A,B,L) ({ \
    __typeof__(A) __NSX_PASTE__(__a,L) = (A); \
    __typeof__(B) __NSX_PASTE__(__b,L) = (B); \
    ((__NSX_PASTE__(__a,L) < __NSX_PASTE__(__b,L)) ? NSOrderedAscending : \
    ((__NSX_PASTE__(__a,L) > __NSX_PASTE__(__b,L)) ? NSOrderedDescending : \
    NSOrderedSame)); })
#define NTVCompare(A,B) __NTVCompare__(A,B,__COUNTER__)
#endif

#endif /* !NTV_MACROS */
