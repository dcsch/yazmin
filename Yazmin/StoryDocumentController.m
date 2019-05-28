//
//  StoryDocumentController.m
//  Yazmin
//
//  Created by David Schweinsberg on 5/27/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryDocumentController.h"
#import "AppController.h"
#import "LibraryController.h"

@implementation StoryDocumentController

- (void)addDocument:(NSDocument *)document {
  [super addDocument:document];
  AppController *appController = NSApp.delegate;
  Story *story = (Story *)document;
  [appController.libraryController addStory:story];
}

@end
