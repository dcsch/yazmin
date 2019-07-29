//
//  SearchFieldDelegate.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/28/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "SearchFieldDelegate.h"
#import "LibraryViewController.h"

@interface SearchFieldDelegate () <NSSearchFieldDelegate>

@end

@implementation SearchFieldDelegate

- (BOOL)control:(NSControl *)control
               textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {
  LibraryViewController *vc =
      (LibraryViewController *)
          control.window.windowController.contentViewController;
  if (vc.filterPredicate && commandSelector == @selector(insertNewline:)) {
    if (vc.sortedEntries.count > 0)
      [vc openStory:vc.sortedEntries[0]];
    return YES;
  }
  return NO;
}

@end
