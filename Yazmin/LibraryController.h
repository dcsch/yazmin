//
//  LibraryController.h
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;
@class Story;

@interface LibraryController : NSWindowController

- (instancetype)initWithLibrary:(Library *)aLibrary;

- (void)addStory:(Story *)story;

@end
