//
//  StoryWindowController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/16/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryWindowController.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "Story.h"
#import "StoryViewController.h"

@interface StoryWindowController ()

@end

@implementation StoryWindowController

- (void)windowDidLoad {
  [super windowDidLoad];

  // When the user closes the story window, we want all other windows
  // attached to the story (debuggers, etc) to close also
  self.shouldCloseDocument = YES;
}

- (void)setDocument:(NSDocument *)document {
  [super setDocument:document];

  Story *story = self.document;
  self.contentViewController.representedObject = story;
  if (story) {
    // Note: triggers NSViewFrameDidChangeNotification
    self.windowFrameAutosaveName = story.ifid;
  }
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {

  // Retrieve the title from metadata, if present.  Otherwise use the
  // default display name.
  Story *story = self.document;
  NSString *title;
  if (story.metadata)
    title = story.metadata.bibliographic.title;
  else
    title = [super windowTitleForDocumentDisplayName:displayName];

  if (story.hasEnded)
    title = [title stringByAppendingString:@" — Ended"];

  return title;
}

@end
