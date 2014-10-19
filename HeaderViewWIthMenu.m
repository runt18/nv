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


#import "HeaderViewWIthMenu.h"
#import "NoteAttributeColumn.h"


@interface HeaderViewWithMenu (Private)
- (void)_resizeColumn:(NSInteger)resizedColIdx withEvent:(id)event;
@end

@implementation HeaderViewWithMenu

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (!self) { return nil; }
	
	isReloading = NO;

	return self;
}

- (void)setIsReloading:(BOOL)reloading {
	isReloading = reloading;
}

- (void)resetCursorRects {
	if (!isReloading) {
		[super resetCursorRects];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    
    if ([[self tableView] respondsToSelector:@selector(menuForColumnConfiguration:)]) {
        NSPoint theClickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
        NSInteger theColumn = [self columnAtPoint:theClickPoint];
        NSTableColumn *theTableColumn = nil;
        if (theColumn > -1)
            theTableColumn = [[self tableView] tableColumns][theColumn];
        
        NSMenu *theMenu = [[self tableView] performSelector:@selector(menuForColumnConfiguration:) withObject:theTableColumn];
        return theMenu;
    }
    
    return nil;
}



/*
 doesn't use private API but is less efficent i think
 - (NSInteger)resizedColumn{
 NSUInteger originalResizingMask = 0;
 NSInteger i;
 //change all user-resizable-only columns
 for (i=0; i<[[self tableView] numberOfColumns]; i++) {
 NoteAttributeColumn *col = [[[self tableView] tableColumns] objectAtIndex:i];
 if ((originalResizingMask = [col resizingMask]) == NSTableColumnUserResizingMask) {
 [col setResizingMask: NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
 [col performSelector:@selector(setResizingMaskNumber:) withObject:[NSNumber numberWithUnsignedInt:originalResizingMask] afterDelay:0.0f];
 }
 }
 
 
 return [super resizedColumn];
 
 }
 */

@end

@implementation HeaderViewWithMenu (Private)

- (void)_resizeColumn:(NSInteger)resizedColIdx withEvent:(id)event {
    
	//use a more understandable column resizing by changing the resizing mask immediately before calling through to the private method,
	//and reverting it back to the original at the next runloop iteration
	NSUInteger originalResizingMask = 0;
	NSInteger i;
	//change all user-resizable-only columns
	for (i=0; i<[[self tableView] numberOfColumns]; i++) {
		NoteAttributeColumn *col = [[self tableView] tableColumns][i];
		if ((originalResizingMask = [col resizingMask]) == NSTableColumnUserResizingMask) {
			[col setResizingMask: NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
			[col performSelector:@selector(setResizingMaskNumber:) withObject:@(originalResizingMask) afterDelay:0];
		}
	}
    
	[super _resizeColumn:resizedColIdx withEvent:event];
}

@end

