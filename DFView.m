//
//  DFView.m
//  Notation
//
//  Created by ElasticThreads on 2/15/11.
//

#import "DFView.h"
#import "AppController.h"


@implementation DFView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (!self) { return nil; }

	if (!vColor) {
		[self setBackgroundColor:[NTVAppDelegate() backgrndColor]];
	}

	return self;
}

- (void)dealloc{
	[vColor release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    if (!IsLionOrLater&&([NTVAppDelegate() isInFullScreen])){
        NSRect bounds = [self bounds];
        bounds.origin.x -=2.0f;
        bounds.size.width +=4.0f;
        NSBezierPath *aPath=[NSBezierPath bezierPath];
        [aPath moveToPoint:NSMakePoint(floor(bounds.origin.x), floor(bounds.origin.y))];
        [aPath lineToPoint:NSMakePoint(floor(bounds.origin.x+bounds.size.width), floor(bounds.origin.y))];        
        [aPath setLineWidth:1.0];
        [vColor setStroke];
//        [[NSColor redColor] setStroke];
        [aPath stroke];       
    }
}

- (void)setBackgroundColor:(NSColor *)inColor{
    if (vColor) {
        [vColor release];
    }
    CGFloat fWhite;
	
	fWhite = [[inColor colorUsingColorSpaceName:NSCalibratedWhiteColorSpace] whiteComponent];
	if (fWhite < 0.75f) {
		if (fWhite<0.25f) {
			fWhite += 0.22f;
		}else {
			fWhite += 0.16f;
		}		
	}else {
		fWhite -= 0.20f;
	}	
	vColor = [NSColor colorWithCalibratedWhite:fWhite alpha:1.0f];
	[vColor retain];
}



@end
