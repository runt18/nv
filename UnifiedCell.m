/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
    This file is part of Notational Velocity.

    Notational Velocity is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Notational Velocity is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Notational Velocity.  If not, see <http://www.gnu.org/licenses/>. */


#import "UnifiedCell.h"
#import "NoteObject.h"
#import "NotesTableView.h"
#import "GlobalPrefs.h"
#import "NSBezierPath_NV.h"
#import "NSString_CustomTruncation.h"
#import "NoteAttributeColumn.h"

@implementation UnifiedCell

- (id)init {
	self = [super init];
	if (!self) { return nil; }

	[self setTruncatesLastVisibleLine:YES];
	[self setEditable:YES];

	return self;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj 
			   delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	
	NSRect rect = [(NotesTableView*)controlView lastEventActivatedTagEdit] ? [self nv_tagsRectForFrame:aRect] : [self nv_titleRectForFrame:aRect];
	[super selectWithFrame:rect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	
	[controlView setKeyboardFocusRingNeedsDisplayInRect:NSInsetRect([self nv_tagsRectForFrame:aRect], -3, -3)];
}

- (NSFocusRingType)focusRingType {
	return NSFocusRingTypeNone;
}

- (float)tableFontFrameHeight {
	return [(NotesTableView*)[self controlView] tableFontHeight] + 1.0f;
}

- (NSRect)nv_titleRectForFrame:(NSRect)aFrame {
	//fixed based on width of the cell

	//height could justifiably vary based on wrapped height of title string-9.0
	return NSMakeRect(aFrame.origin.x, aFrame.origin.y, aFrame.size.width, [self tableFontFrameHeight]);
}

- (NSRect)nv_tagsRectForFrame:(NSRect)frame {
	//if no tags, return a default small frame to allow adding them
	float fontHeight = [self tableFontFrameHeight];
	NSSize size = NSMakeSize(NSWidth(frame), fontHeight);
	NSPoint pos = NSMakePoint(NSMinX(frame) + 3.0, (previewIsHidden ? NSMinY(frame) + fontHeight + size.height + 2.0 : NSMaxY(frame) - 2.0) - fontHeight);
	
	return (NSRect){pos, size};
}

- (NoteObject*)noteObject {
	return noteObject;
}

- (void)setNoteObject:(NoteObject*)obj {
	[noteObject autorelease];
	noteObject = [obj retain];
}

- (void)setPreviewIsHidden:(BOOL)value {
	previewIsHidden = value;
}

+ (NSColor*)dateColorForTint {
	static NSColor *color = nil;
	static NSControlTint lastTint = -1;
	
	NSControlTint tint = [NSColor currentControlTint];
	
	if (!color || lastTint != tint) {
		if (tint == NSBlueControlTint) {
			color = [NSColor colorWithCalibratedRed:0.31 green:.494 blue:0.765 alpha:1.0];
		} else if (tint == NSGraphiteControlTint) {
			color = [NSColor colorWithCalibratedRed:0.498 green:0.525 blue:0.573 alpha:1.0];
		} else {
			color = [NSColor grayColor];
		}
		lastTint = tint;
		[color retain];
	}
	return color;
}

NSAttributedString *AttributedStringForSelection(NSAttributedString *str) {
	//used to modify the cell's attributed string before display when it is selected
	
	//snow leopard is stricter about applying the default highlight-attributes (e.g., no shadow unless no paragraph formatting)
	//so add the shadow here for snow leopard on selected rows

	NSRange fullRange = NSMakeRange(0, [str length]);
	NSMutableAttributedString *colorFreeStr = [str mutableCopy];
	[colorFreeStr removeAttribute:NSForegroundColorAttributeName range:fullRange];
	return [colorFreeStr autorelease];
}

- (NSMutableDictionary*)baseTextAttributes {
	static NSMutableParagraphStyle *alignStyle = nil;
	if (!alignStyle) {
		alignStyle = [[NSMutableParagraphStyle alloc] init];
		[alignStyle setAlignment:NSRightTextAlignment];
	}
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:alignStyle, NSParagraphStyleAttributeName, [self font], NSFontAttributeName, nil];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {	
	
	NotesTableView *tv = (NotesTableView *)controlView;
	
	[super drawWithFrame:cellFrame inView:controlView];	
	
	//draw note date and tags

	NSMutableDictionary *baseAttrs = [self baseTextAttributes];
	BOOL isActive = ([tv selectionHighlightStyle] == NSTableViewSelectionHighlightStyleSourceList) ? YES : [tv isActiveStyle];
	
	NSColor *textColor = ([self isHighlighted] && isActive) ? [NSColor whiteColor] : (![self isHighlighted] ? [[self class] dateColorForTint] : nil);
	if (textColor)
		baseAttrs[NSForegroundColorAttributeName] = textColor;

	float fontHeight = [tv tableFontHeight];
	
	//if the sort-order is date-created, then show the date on which this note was created; otherwise show date modified.
	unsigned int columnsBitmap = [[GlobalPrefs defaultPrefs] tableColumnsBitmap];
	
	if (ColumnIsSet(NoteDateCreatedColumn, columnsBitmap) || ColumnIsSet(NoteDateModifiedColumn, columnsBitmap)) {
		BOOL showDateCreated = NO;
		
		if (ColumnIsSet(NoteDateCreatedColumn, columnsBitmap) && ColumnIsSet(NoteDateModifiedColumn, columnsBitmap)) {
			showDateCreated = [[[GlobalPrefs defaultPrefs] sortedTableColumnKey] isEqualToString:NoteDateCreatedColumnString];
		} else if (ColumnIsSet(NoteDateCreatedColumn, columnsBitmap)) {
			showDateCreated = YES;
		}
		
		NSString *dateStr = (showDateCreated ? dateCreatedStringOfNote : dateModifiedStringOfNote)(tv, noteObject, NSNotFound);
        CGFloat dateLength=70.0;
        if (dateStr.length>8) {
            dateLength+=(((CGFloat)dateStr.length-8.0)*2);
        }
		[dateStr drawInRect:NSMakeRect(NSMaxX(cellFrame) - dateLength-4.0, NSMinY(cellFrame), dateLength, fontHeight) withAttributes:baseAttrs];
	}

	if (ColumnIsSet(NoteLabelsColumn, columnsBitmap) && [labelsOfNote(noteObject) length]) {
		NSRect rect = [self nv_tagsRectForFrame:cellFrame];
		rect.origin.y += fontHeight;
		rect = [controlView centerScanRect:rect];
		
		//clip the tags image within the bounds of the cell so that narrow columns look nicer
		[NSGraphicsContext saveGraphicsState];
		NSRectClip(cellFrame);
		[noteObject drawLabelBlocksInRect:rect rightAlign:!previewIsHidden highlighted:([self isHighlighted] && isActive)];
		[NSGraphicsContext restoreGraphicsState];
	}
	
	if ([tv currentEditor] && [self isHighlighted]) {
		//needed because the body text is normally not drawn while editing
		NSMutableAttributedString *cloneStr = [[self attributedStringValue] mutableCopy];
		NSRange range = NSMakeRange(0, [cloneStr length]);
		[cloneStr addAttribute:NSFontAttributeName value:[self font] range:range];
		if (textColor) [cloneStr addAttribute:NSForegroundColorAttributeName value:textColor range:range];
		[cloneStr addAttributes:LineTruncAttributesForTitle() range:NSMakeRange(0, [titleOfNote(noteObject) length])];
		
		[cloneStr drawWithRect:NSInsetRect([self titleRectForBounds:cellFrame], 2., 0.) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];
		[cloneStr release];
		
		//draw a slightly different focus ring than what would have been drawn
		NSRect rect = [tv lastEventActivatedTagEdit] ? [self nv_tagsRectForFrame:cellFrame] : [self nv_titleRectForFrame:cellFrame];
		[NSGraphicsContext saveGraphicsState];
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(rect, -2, -1)];
		
		//megafocusring casts a shadow both outside and inside
		if ([tv lastEventActivatedTagEdit]) {
			NSSetFocusRingStyle(NSFocusRingBelow);
			[path fill];
		}
		NSSetFocusRingStyle(NSFocusRingOnly);
		[path fill];

		[NSGraphicsContext restoreGraphicsState];
		
	}
}

@end
