//
//  IFDBService.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/17/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "IFDBService.h"

@implementation IFDBService

- (void)fetchRecordForIFID:(NSString *)ifid
         completionHandler:(void (^)(NSData *data))handler {
  NSURLSession *session = NSURLSession.sharedSession;
  NSString *str = [NSString
      stringWithFormat:@"https://ifdb.tads.org/viewgame?ifiction&ifid=%@",
                       ifid];
  NSLog(@"Fetching %@", str);
  NSURL *url = [NSURL URLWithString:str];
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:url
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
               NSLog(@"Response: %ld", (long)httpResponse.statusCode);
               if (httpResponse.statusCode == 200)
                 dispatch_async(dispatch_get_main_queue(), ^{
                   handler(data);
                 });
             }];
  [dataTask resume];
}

@end
