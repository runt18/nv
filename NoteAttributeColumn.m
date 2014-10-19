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


#import "NoteAttributeColumn.h"
#import "NotesTableView.h"

/*
@implementation NoteTableHeaderCell

- (NSRect)drawingRectForBounds:(NSRect)theRect {
	return NSInsetRect(theRect, 6.0f, 0.0);
}

@end
*/
@implementation NoteAttributeColumn

- (id)initWithIdentifier:(id)anObject {
	self = [super initWithIdentifier:anObject];
	if (!self) { return nil; }

	absoluteMinimumWidth = [anObject sizeWithAttributes:[NoteAttributeColumn standardDictionary]].width + 5;
	[self setMinWidth:absoluteMinimumWidth];

	return self;
}

+ (NSDictionary*)standardDictionary {
	static NSDictionary *standardDictionary = nil;
	if (!standardDictionary) {
		standardDictionary = [@{
			NSFontAttributeName: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
		} retain];
	}

	return standardDictionary;
}

- (void)sizeToFit{
    NSLog(@"tablecolumn size to fit");
    [super sizeToFit];
}

- (void)updateWidthForHighlight {
	[self setMinWidth:absoluteMinimumWidth + ([[self tableView] highlightedTableColumn] == self ? 10 : 0)];
  
}

SEL columnAttributeMutator(NoteAttributeColumn *col) {
	return col->mutateObjectSelector;
}

- (void)setMutatingSelector:(SEL)selector {
	mutateObjectSelector = selector;
}

id columnAttributeForObject(NotesTableView *tv, NoteAttributeColumn *col, id object, NSInteger row) {
	NTVNoteAttributeGetter getter = col.attributeGetter;
	if (!getter) { return NULL; }
	return getter(tv, object, row);
}

- (void)setResizingMaskNumber:(NSNumber*)resizingMaskNumber {
	[self setResizingMask:[resizingMaskNumber unsignedIntValue]];
}

@end
