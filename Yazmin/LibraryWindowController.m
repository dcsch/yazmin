//
//  LibraryWindowController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/29/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "LibraryWindowController.h"
#import "LibraryViewController.h"

@interface LibraryWindowController () <NSSearchFieldDelegate>

@end

@implementation LibraryWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
}

#pragma mark - NSSearchFieldDelegate Methods

- (BOOL)control:(NSControl *)control
               textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {
  LibraryViewController *vc =
      (LibraryViewController *)self.contentViewController;
  if (vc.filterPredicate && commandSelector == @selector(insertNewline:)) {
    if (vc.sortedEntries.count > 0)
      [vc openStory:vc.sortedEntries[0]];
    return YES;
  }
  return NO;
}

@end
