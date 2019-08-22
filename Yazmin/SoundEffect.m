//
//  SoundEffect.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/21/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "SoundEffect.h"

@interface SoundEffect () <NSSoundDelegate>

@end

@implementation SoundEffect

- (instancetype)initWithSound:(NSSound *)sound {
  self = [super init];
  if (self) {
    _sound = sound;
    _sound.delegate = self;
  }
  return self;
}

#pragma mark - NSSoundDelegate Methods

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)flag {
  if (_repeat > 1)
    [_sound play];
  if (_repeat > 0 && _repeat != 255)
    --_repeat;
}

@end
