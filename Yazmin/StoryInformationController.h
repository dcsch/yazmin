//
//  StoryInformationController.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFStory;

@interface StoryInformationController : NSWindowController

- (nonnull instancetype)initWithStoryMetadata:(nonnull IFStory *)storyMetadata
                                  pictureData:(nullable NSData *)pictureData;

@end
