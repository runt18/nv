//
//  TagEditingManager.m
//  Notation
//
//  Created by elasticthreads on 10/15/10.
//

@import Cocoa;


@interface TagEditingManager : NSObject <NSWindowDelegate> {
	
    IBOutlet NSPanel *tagPanel;
    IBOutlet NSTextField *tagField;
    BOOL isHappening;
    NSString *tagFieldString;
    NSArray *commonTags;
}

@property(retain,nonatomic)NSArray *commonTags;
@property(retain)NSString *tagFieldString;

- (id)initWithDelegate:(id)del commonTags:(NSArray *)cTags atPoint:(NSPoint)centerpoint;
- (void)setTF:(NSString *)inString;
- (void)closeTP:(id)sender;
- (NSTextView *)tagFieldEditor;
- (NSTextField *)tagField;
- (BOOL)isMultitagging;

@end
