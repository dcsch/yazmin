//
//  CoverArtViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/11/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "CoverArtViewController.h"
#import "Story.h"

@interface CoverArtViewController () {
  IBOutlet NSImageView *imageView;
}

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

@end
