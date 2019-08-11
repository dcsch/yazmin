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
#import "Story.h"

@interface InformationViewController () {
  IBOutlet NSImageView *imageView;
  IBOutlet NSTextField *titleTextField;
  IBOutlet NSTextField *authorTextField;
  IBOutlet NSTextField *descriptionTextField;
  IBOutlet NSTextField *ifidTextField;
}

@end

@implementation InformationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];

  Story *story = self.representedObject;

  ifidTextField.stringValue = story.ifid;

  // Set the artwork
  if (story.coverImage) {

    // Resize the image to a high quality thumbnail
    float resizeWidth = 128.0;
    float resizeHeight = 128.0;
    NSImage *resizedImage =
        [[NSImage alloc] initWithSize:NSMakeSize(resizeWidth, resizeHeight)];

    NSSize originalSize = story.coverImage.size;

    [resizedImage lockFocus];
    [NSGraphicsContext currentContext].imageInterpolation =
        NSImageInterpolationHigh;
    [story.coverImage
        drawInRect:NSMakeRect(0, 0, resizeWidth, resizeHeight)
          fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height)
         operation:NSCompositingOperationSourceOver
          fraction:1.0];
    [resizedImage unlockFocus];

    imageView.image = resizedImage;
  }

  if (story.metadata) {
    titleTextField.stringValue = story.metadata.bibliographic.title;
    NSString *author = story.metadata.bibliographic.author;
    authorTextField.stringValue = author ? author : @"";
    NSString *desc = story.metadata.bibliographic.storyDescription;
    descriptionTextField.stringValue = desc ? desc : @"";
  }
}

@end
