//
//  IFDBService.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/17/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IFDBService : NSObject

- (void)fetchRecordForIFID:(NSString *)ifid
         completionHandler:(void (^)(NSData *data))handler;

@end

NS_ASSUME_NONNULL_END
