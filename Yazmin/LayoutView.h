/* LowerWindow */

#import <Cocoa/Cocoa.h>

@class StoryController;
@class StoryFacetView;

@interface LayoutView : NSView {
  IBOutlet StoryController *controller;
  StoryFacetView *upperWindow;
  StoryFacetView *lowerWindow;
  NSScrollView *lowerScrollView;
}

@property(readonly, strong) StoryController *controller;
@property(strong) StoryFacetView *upperWindow;
@property(strong) StoryFacetView *lowerWindow;
@property(readonly, strong) NSScrollView *lowerScrollView;
- (void)resizeUpperWindow:(int)lines;

@end
