//
//  CoverArtViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/11/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "CoverArtViewController.h"
#import "AppController.h"
#import "Story.h"

@interface CoverArtViewController () {
  IBOutlet NSImageView *imageView;
}

- (IBAction)dropImage:(id)sender;
- (IBAction)removeImage:(id)sender;

@end

@implementation CoverArtViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];

  Story *story = self.representedObject;
  if (story.coverImage)
    imageView.image = story.coverImage;
}

#pragma mark - Actions

- (IBAction)dropImage:(id)sender {
  for (NSImageRep *imageRep in imageView.image.representations) {
    if ([imageRep isKindOfClass:NSBitmapImageRep.class]) {
      NSBitmapImageRep *bitmapImageRep = (NSBitmapImageRep *)imageRep;
      NSData *data =
          [bitmapImageRep representationUsingType:NSBitmapImageFileTypeJPEG
                                       properties:@{
                                         NSImageCompressionFactor : @0.8
                                       }];
      Story *story = self.representedObject;
      NSString *filename = [NSString stringWithFormat:@"%@.jpg", story.ifid];
      NSURL *url = [AppController URLForResource:filename
                                    subdirectory:@"Cover Art"
                      createNonexistentDirectory:YES];
      [data writeToURL:url atomically:YES];
      NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
      [nc postNotificationName:SMCoverImageChangedNotification object:self];
      break;
    }
  }
}

- (IBAction)removeImage:(id)sender {
  imageView.image = [NSBundle.mainBundle imageForResource:@"NoCoverArt"];

  Story *story = self.representedObject;
  NSFileManager *fm = NSFileManager.defaultManager;
  NSURL *artURL = [AppController.applicationSupportDirectoryURL
      URLByAppendingPathComponent:@"Cover Art"];
  NSArray<NSURL *> *urls = [fm contentsOfDirectoryAtURL:artURL
                             includingPropertiesForKeys:nil
                                                options:0
                                                  error:nil];
  for (NSURL *url in urls) {
    NSString *ifid = url.lastPathComponent.stringByDeletingPathExtension;
    if ([ifid isEqualToString:story.ifid])
      [fm removeItemAtURL:url error:nil];
  }
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName:SMCoverImageChangedNotification object:self];
}

@end
