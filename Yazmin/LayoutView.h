/* LowerWindow */

#import <Cocoa/Cocoa.h>

@class StoryController;
@class StoryFacetView;

@interface LayoutView : NSView
{
    IBOutlet StoryController *controller;
    StoryFacetView *upperWindow;
    StoryFacetView *lowerWindow;
    NSScrollView *lowerScrollView;
}

- (StoryController *)controller;
- (StoryFacetView *)upperWindow;
- (void)setUpperWindow:(StoryFacetView *)view;
- (StoryFacetView *)lowerWindow;
- (void)setLowerWindow:(StoryFacetView *)view;
- (NSScrollView *)lowerScrollView;
- (void)resizeUpperWindow:(int)lines;

@end
