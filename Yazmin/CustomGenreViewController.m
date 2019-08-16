//
//  CustomGenreViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/15/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "CustomGenreViewController.h"
#import "BibliographicViewController.h"

@interface CustomGenreViewController () {
  IBOutlet NSTextField *genreTextField;
}

@end

@implementation CustomGenreViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (IBAction)selectOK:(id)sender {
  BibliographicViewController *pvc =
      (BibliographicViewController *)self.presentingViewController;
  [pvc addCustomGenre:genreTextField.stringValue];
  [self dismissViewController:self];
}

- (IBAction)selectCancel:(id)sender {
  [self dismissViewController:self];
}

@end
