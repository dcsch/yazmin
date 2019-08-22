//
//  SoundEffect.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/21/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundEffect : NSObject

@property(readonly) NSSound *sound;
@property NSUInteger repeat;
@property int routine;

- (instancetype)initWithSound:(NSSound *)sound NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@end

NS_ASSUME_NONNULL_END
