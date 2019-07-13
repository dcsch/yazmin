//
//  InterpreterPreferencesViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/10/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "InterpreterPreferencesViewController.h"

@interface InterpreterPreferencesViewController () <
    NSControlTextEditingDelegate>

@end

@implementation InterpreterPreferencesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark - NSControlTextEditingDelegate Methods

//- (BOOL)control:(NSControl *)control isValidObject:(id)obj {
//  if (control) {
//    NSString *text = control.stringValue;
//    if (text.length != 1 ||
//        [text characterAtIndex:0] <= 'A' ||
//        [text characterAtIndex:0] >= 'Z') {
////      NSRunAlertPanel(@"Version not valid", @"Must be between A and Z",
///NULL, NULL, NULL);
//      return NO;
//    }
//  }
//  return YES;
//}

//- (void)controlTextDidEndEditing:(NSNotification *)obj {
//  NSTextField *textField = obj.object;
//}

@end
