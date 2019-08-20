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

extern NSString *SMCoverImageChangedNotification;
extern NSString *SMMetadataChangedNotification;

@interface AppController : NSObject <NSApplicationDelegate>

@property(readonly) Library *library;
@property(readonly) NSWindowController *libraryWindowController;
@property(class, readonly) NSURL *applicationSupportDirectoryURL;

+ (NSURL *)URLForResource:(NSString *)name
             subdirectory:(nullable NSString *)subpath
createNonexistentDirectory:(BOOL)create;

@end

NS_ASSUME_NONNULL_END
