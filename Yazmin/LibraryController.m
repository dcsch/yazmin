//
//  LibraryController.m
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryController.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Story.h"

@interface LibraryController () <NSMenuItemValidation> {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
  Library *library;
}

- (IBAction)openStory:(id)sender;
- (IBAction)showStoryInfo:(id)sender;
- (IBAction)removeStory:(id)sender;

@end

@implementation LibraryController

- (instancetype)initWithLibrary:(Library *)aLibrary {
  self = [super initWithWindowNibName:@"Library"];
  if (self) {
    library = aLibrary;

    // We don't want this window to appear in the Windows menu
    self.window.excludedFromWindowsMenu = YES;
  }
  return self;
}

- (void)addStory:(Story *)story {
  if (![library containsStory:story]) {
    LibraryEntry *entry =
        [[LibraryEntry alloc] initWithIfid:story.ifid url:story.fileURL];
    [arrayController addObject:entry];
  }
}

- (IBAction)openStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    LibraryEntry *entry = arrayController.arrangedObjects[row];
    [NSDocumentController.sharedDocumentController
        openDocumentWithContentsOfURL:entry.fileURL
                              display:YES
                    completionHandler:^(NSDocument *_Nullable document,
                                        BOOL documentWasAlreadyOpen,
                                        NSError *_Nullable error){
                    }];
  }
}

- (IBAction)showStoryInfo:(id)sender {
}

- (IBAction)removeStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    LibraryEntry *entry = arrayController.arrangedObjects[row];
    [arrayController removeObject:entry];
  }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    return YES;
  }
  return NO;
}

@end
