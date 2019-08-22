//
//  ResourcesViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/21/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "ResourcesViewController.h"
#import "IFAnnotation.h"
#import "IFStory.h"
#import "IFYazmin.h"
#import "Story.h"

@interface ResourcesViewController () {
  IBOutlet NSTextField *blorbTextField;
}

- (IBAction)chooseBlorb:(id)sender;

@end

@implementation ResourcesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];
  Story *story = self.representedObject;
  if (story.metadata.annotation.yazmin.blorbURL)
    blorbTextField.stringValue =
        story.metadata.annotation.yazmin.blorbURL.lastPathComponent;
}

#pragma mark - Actions

- (IBAction)chooseBlorb:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[ @"blorb", @"blb" ];
  panel.allowsMultipleSelection = NO;
  [panel beginSheetModalForWindow:self.view.window
                completionHandler:^(NSInteger result) {
                  if (result == NSModalResponseOK) {
                    Story *story = self.representedObject;
                    story.metadata.annotation.yazmin.blorbURL = panel.URL;
                    self->blorbTextField.stringValue =
                        panel.URL.lastPathComponent;
                  }
                }];
}

@end
