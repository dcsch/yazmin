//
//  LibraryController.h
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;

@interface LibraryController : NSWindowController {
  IBOutlet NSTableView *tableView;
  Library *library;
}

- (void)playStory;
//- (void)update;

@end
