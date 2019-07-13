//
//  StoryDocumentController.m
//  Yazmin
//
//  Created by David Schweinsberg on 5/27/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryDocumentController.h"
#import "LibraryViewController.h"
#import "Story.h"

@implementation StoryDocumentController

- (void)addDocument:(NSDocument *)document {
  [super addDocument:document];
  LibraryViewController *vc =
      (LibraryViewController *)NSApp.mainWindow.contentViewController;
  Story *story = (Story *)document;
  [vc addStory:story];
}

@end
