//
//  AppController.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;

NS_ASSUME_NONNULL_BEGIN

@interface AppController : NSObject <NSApplicationDelegate>

@property(readonly) Library *library;
@property(readonly) NSWindow *libraryWindow;

@end

NS_ASSUME_NONNULL_END
