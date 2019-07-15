//
//  InformationViewController.h
//  Yazmin
//
//  Created by David Schweinsberg on 7/13/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IFStory;

NS_ASSUME_NONNULL_BEGIN

@interface InformationViewController : NSViewController

@property IFStory *storyMetadata;
@property NSImage *picture;

@end

NS_ASSUME_NONNULL_END
