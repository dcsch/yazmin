//
//  InformationWindowController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/16/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "InformationWindowController.h"

@interface InformationWindowController ()

@end

@implementation InformationWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
}

- (void)setDocument:(id)document {
  [super setDocument:document];

  // Set representedObject for all the controllers
  NSTabViewController *tabViewController =
      (NSTabViewController *)self.contentViewController;
  for (NSTabViewItem *item in tabViewController.tabViewItems)
    item.viewController.representedObject = document;
}

@end
