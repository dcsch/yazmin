//
//  StoryDocumentController.m
//  Yazmin
//
//  Created by David Schweinsberg on 5/27/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryDocumentController.h"
#import "AppController.h"
#import "LibraryViewController.h"
#import "Story.h"

@implementation StoryDocumentController

- (void)addDocument:(NSDocument *)document {
  [super addDocument:document];
  AppController *appController = NSApp.delegate;
  LibraryViewController *vc =
      (LibraryViewController *)
          appController.libraryWindow.contentViewController;
  Story *story = (Story *)document;
  [vc addStory:story];
}

- (void)noteNewRecentDocument:(NSDocument *)document {
  if (!self.onlyPeeking)
    [super noteNewRecentDocument:document];
}

@end
