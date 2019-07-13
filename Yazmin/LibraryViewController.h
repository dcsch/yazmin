//
//  LibraryViewController.h
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;
@class Story;

NS_ASSUME_NONNULL_BEGIN

@interface LibraryViewController : NSViewController

@property Library *library;

- (void)addStory:(Story *)story;

@end

NS_ASSUME_NONNULL_END
