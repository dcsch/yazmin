//
//  InformationViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/13/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "InformationViewController.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"

@interface InformationViewController () {
  IBOutlet NSImageView *imageView;
  IBOutlet NSTextField *titleTextField;
  IBOutlet NSTextField *authorTextField;
  IBOutlet NSTextView *storyDescription;
}

@end

@implementation InformationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];

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
    titleTextField.stringValue = _storyMetadata.bibliographic.title;
    authorTextField.stringValue = _storyMetadata.bibliographic.author;
    NSString *desc = _storyMetadata.bibliographic.storyDescription;
    if (desc)
      storyDescription.string = desc;
  }
}

@end
