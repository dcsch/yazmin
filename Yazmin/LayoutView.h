
#import <Cocoa/Cocoa.h>

@class StoryController;
@class StoryFacetView;

@interface LayoutView : NSView

@property IBOutlet StoryController *controller;
@property StoryFacetView *upperWindow;
@property StoryFacetView *lowerWindow;
@property(readonly) NSScrollView *lowerScrollView;

- (void)resizeUpperWindow:(int)lines;

@end
