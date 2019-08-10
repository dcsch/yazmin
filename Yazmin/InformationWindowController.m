//
//  InformationWindowController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/16/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "InformationWindowController.h"
#import "InformationViewController.h"
#import "Story.h"

@interface InformationWindowController ()

- (void)prepareWithMetadata:(IFStory *)storyMetadata image:(NSImage *)image;

@end

@implementation InformationWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
}

- (void)setDocument:(id)document {
  [super setDocument:document];

  Story *story = document;
  [self prepareWithMetadata:story.metadata image:story.coverImage];
}

- (void)prepareWithMetadata:(IFStory *)storyMetadata image:(NSImage *)image {

  // Fish through all the controllers
  NSTabViewController *tabViewController =
      (NSTabViewController *)self.contentViewController;
  InformationViewController *infoViewController =
      (InformationViewController *)tabViewController.tabViewItems[0]
          .viewController;
  infoViewController.representedObject = self.document;
  infoViewController.storyMetadata = storyMetadata;
  infoViewController.picture = image;

  NSViewController *artViewController =
      tabViewController.tabViewItems[1].viewController;
  artViewController.representedObject = image;
}

@end
