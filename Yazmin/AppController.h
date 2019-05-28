//
//  AppController.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;
@class LibraryController;

@interface AppController : NSObject <NSApplicationDelegate>

@property(readonly) Library *library;
@property(readonly) LibraryController *libraryController;

@end
