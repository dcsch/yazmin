//
//  Story.h
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class StoryFacet;
@class Blorb;
@class IFStory;
@class ZMachine;
@class DebugInfo;
@class StoryController;

@interface Story : NSDocument
{
    NSMutableArray *facets;
    NSString *inputString;
    Blorb *blorb;
    IFStory *metadata;
    NSString *ifid;
    NSData *zcodeData;
    ZMachine *zMachine;
    DebugInfo *debugInfo;
    unsigned int lastRestoreOrSaveResult;
    StoryController *controller;
}

- (NSArray *)facets;
- (NSString *)inputString;
- (void)setInputString:(NSString *)input;
- (NSData *)zcodeData;
- (Blorb *)blorb;
- (IFStory *)metadata;
- (NSString *)ifid;
- (ZMachine *)zMachine;
- (DebugInfo *)debugInfo;
- (BOOL)hasEnded;
- (NSData *)savedSessionData;
- (void)saveSessionData:(NSData *)data;
- (unsigned int)lastRestoreOrSaveResult;
- (void)setLastRestoreOrSaveResult:(unsigned int)result;
- (void)error:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)updateWindowWidth;
- (void)handleBackgroundColourChange:(NSNotification *)note;
- (void)handleForegroundColourChange:(NSNotification *)note;
- (void)handleFontChange:(NSNotification *)note;

- (NSString *)input;
- (char)inputChar;

@end
