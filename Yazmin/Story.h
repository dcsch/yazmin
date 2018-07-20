//
//  Story.h
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class Blorb;
@class IFStory;
@class ZMachine;
@class DebugInfo;

@interface Story : NSDocument

@property (readonly, copy) NSArray *facets;
@property (copy) NSString *inputString;
@property (readonly, copy) NSData *zcodeData;
@property (readonly, strong) Blorb *blorb;
@property (readonly, strong) IFStory *metadata;
@property (readonly, copy) NSString *ifid;
@property (readonly, strong) ZMachine *zMachine;
@property (readonly, strong) DebugInfo *debugInfo;
@property (readonly) BOOL hasEnded;
@property (readonly, copy) NSData *savedSessionData;
- (void)saveSessionData:(NSData *)data;
@property  unsigned int lastRestoreOrSaveResult;
- (void)error:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)updateWindowWidth;
- (void)handleBackgroundColourChange:(NSNotification *)note;
- (void)handleForegroundColourChange:(NSNotification *)note;
- (void)handleFontChange:(NSNotification *)note;

@property (readonly, copy) NSString *input;
@property (readonly) char inputChar;

@end
