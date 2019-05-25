//
//  LibraryController.m
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryController.h"
#import "AppController.h"
#import "Library.h"
#import "LibraryEntry.h"

@interface LibraryController () {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
  Library *library;
}

@end

@implementation LibraryController

- (instancetype)init {
  self = [super initWithWindowNibName:@"Library"];
  if (self) {
    AppController *app = NSApp.delegate;
    library = app.library;

    // We don't want this window to appear in the Windows menu
    self.window.excludedFromWindowsMenu = YES;
  }
  return self;
}

- (void)playStory {
  LibraryEntry *entry = arrayController.selectedObjects.firstObject;
  [NSDocumentController.sharedDocumentController
      openDocumentWithContentsOfURL:entry.fileURL
                            display:YES
                  completionHandler:^(NSDocument *_Nullable document,
                                      BOOL documentWasAlreadyOpen,
                                      NSError *_Nullable error){
                  }];
}

@end
