//
//  ETContentView.m
//  Notation
//
//  Created by elasticthreads on 3/15/11.
//

@import Cocoa;


@interface ETContentView : NSView {
    NSColor *backColor;
}

- (void)setBackgroundColor:(NSColor *)inCol;
- (NSColor *)backgroundColor;

@end
