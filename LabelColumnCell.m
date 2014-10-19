//
//  LabelColumnCell.m
//  Notation
//
//  Created by Zachary Schneirov on 1/18/11.

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

#import "LabelColumnCell.h"
#import "NotesTableView.h"
#import "NoteObject.h"
#import "GlobalPrefs.h"

@implementation LabelColumnCell

- (id)init {
	self = [super init];
	if (!self) { return nil; }

	[self setEditable:YES];

	[self setFocusRingType:	NSFocusRingTypeExterior];

	return self;
}

- (BOOL)isScrollable {
	return YES;
}


- (NoteObject*)noteObject {
	return noteObject;
}

- (void)setNoteObject:(NoteObject*)obj {
	[noteObject autorelease];
	noteObject = [obj retain];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {	
	NotesTableView *tv = (NotesTableView *)controlView;
	
	NSInteger col = [tv editedColumn];
	BOOL isEditing = [self isHighlighted] && [tv currentEditor] &&
	(col > -1 && [[[tv tableColumns][col] identifier] isEqualToString:NoteLabelsColumnString]);
	
	if (isEditing) {
		[super drawWithFrame:cellFrame inView:controlView];	
	}
	
	if (!isEditing && noteObject.labels.length) {

		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSRectClip(cellFrame);
		CGRect blocksRect = cellFrame;
		blocksRect.origin = CGPointMake(CGRectGetMinX(cellFrame), CGRectGetMaxY(cellFrame) - ceil(((CGRectGetHeight(cellFrame) + 1) -
																					  ([[GlobalPrefs defaultPrefs] tableFontSize] * 1 + 1.5)) / 2));
		[noteObject drawLabelBlocksInRect:blocksRect rightAlign:NO highlighted:([self isHighlighted] && [tv isActiveStyle])];
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	
}

@end
