//
//  StoryInformationController.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryInformationController.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"
//#import "IFictionMetadata.h"

@interface StoryInformationController () {
  IBOutlet NSImageView *imageView;
  IBOutlet NSTextField *title;
  IBOutlet NSTextField *author;
  IBOutlet NSTextView *storyDescription;
  IFStory *_storyMetadata;
  NSData *_pictureData;
}

@end

@implementation StoryInformationController

- (nonnull instancetype)initWithStoryMetadata:(nonnull IFStory *)storyMetadata
                                  pictureData:(nullable NSData *)pictureData {
  self = [super initWithWindowNibName:@"StoryInformation"];
  if (self) {
    _storyMetadata = storyMetadata;
    _pictureData = pictureData;
  }
  return self;
}

- (void)windowDidLoad {
  imageView.imageFrameStyle = NSImageFramePhoto;

  // Set the artwork
  if (_pictureData) {
    NSImage *image = [[NSImage alloc] initWithData:_pictureData];

    // Resize the image to a high quality thumbnail
    float resizeWidth = 128.0;
    float resizeHeight = 128.0;
    NSImage *resizedImage =
        [[NSImage alloc] initWithSize:NSMakeSize(resizeWidth, resizeHeight)];

    NSSize originalSize = image.size;

    [resizedImage lockFocus];
    [NSGraphicsContext currentContext].imageInterpolation =
        NSImageInterpolationHigh;
    [image drawInRect:NSMakeRect(0, 0, resizeWidth, resizeHeight)
             fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height)
            operation:NSCompositingOperationSourceOver
             fraction:1.0];
    [resizedImage unlockFocus];

    imageView.image = resizedImage;
  }

  if (_storyMetadata) {
    title.stringValue = _storyMetadata.bibliographic.title;
    author.stringValue = _storyMetadata.bibliographic.author;
    NSString *desc = _storyMetadata.bibliographic.storyDescription;
    if (desc)
      storyDescription.string = desc;
  }
}

@end
