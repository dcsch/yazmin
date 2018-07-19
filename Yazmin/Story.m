//
//  Story.m
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//

#import "Story.h"
#import "StoryFacet.h"
#import "GridStoryFacet.h"
#import "Preferences.h"
#import "Blorb.h"
#import "StoryController.h"
#import "ZMachine.h"
#import "DebugInfo.h"
#import "DebugInfoReader.h"
#import "AppController.h"
#import "IFictionMetadata.h"
#import "IFStory.h"
#import "IFIdentification.h"
#import "Library.h"
#import "LibraryController.h"

@interface Story (Private)

- (void)createZMachine;

@end

@implementation Story

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Create two facets (lower and upper), with the upper one being
        // a text grid
        facets = [[NSMutableArray alloc] init];
        StoryFacet *facet = [[StoryFacet alloc] initWithStory:self];
        [facets addObject:facet];
        
        facet = [[GridStoryFacet alloc] initWithStory:self columns:90];
        [facets addObject:facet];
        
        [self setHasUndoManager:NO];
        
        // Listen to notifications
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(handleBackgroundColourChange:)
                   name:@"SMBackgroundColourChanged"
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleForegroundColourChange:)
                   name:@"SMForegroundColourChanged"
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleFontChange:)
                   name:@"SMProportionalFontFamilyChanged"
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleFontChange:)
                   name:@"SMMonospacedFontFamilyChanged"
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleFontChange:)
                   name:@"SMFontSizeChanged"
                 object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

}

- (void)makeWindowControllers
{
    controller = [[StoryController alloc] init];
    [self addWindowController:controller];

    // Make sure the controller knows the score with text attributes
    [controller updateTextAttributes];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return nil;
}

- (void)createZMachine
{
    zMachine = [[ZMachine alloc] initWithStory:self];
    
    // Do we have an IFID?  If not, find one
    if (ifid == nil)
        ifid = zMachine.ifid;
    
    // Add this to the library
    AppController *app = NSApp.delegate;
    [app.library addStory:self];
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
                     ofType:(NSString *)typeName
                      error:(NSError **)outError
{
    if ([typeName compare:@"Inform Project"] == 0)
    {
        NSFileWrapper *zcodeWrapper = nil;
        NSFileWrapper *debugWrapper = nil;

        // Pick out the 'Build' directory
        NSFileWrapper *buildDir = fileWrapper.fileWrappers[@"Build"];
        if (buildDir)
        {
            NSDictionary *filesInDirectory = buildDir.fileWrappers;
            NSEnumerator *fileEnum = [filesInDirectory keyEnumerator];
            NSString *filePath;
            while ((filePath = [fileEnum nextObject]))
            {
                NSString *pathExtension = filePath.pathExtension;
                
                // Likely to be 'output.z5' or 'output.z8', so we'll just look
                // for the initial 'z' and go with that
                if ([pathExtension characterAtIndex:0] == 'z')
                    zcodeWrapper = filesInDirectory[filePath];
                else if ([pathExtension compare:@"dbg"] == 0)
                    debugWrapper = filesInDirectory[filePath];
            }
        }
        else
        {
            *outError = [NSError errorWithDomain:@"No build directory found within project bundle"
                                            code:666
                                        userInfo:nil];
            return NO;
        }
        
        if (zcodeWrapper)
        {
            zcodeData = zcodeWrapper.regularFileContents;
            [self createZMachine];
            if (debugWrapper)
            {
                NSData *debugData = debugWrapper.regularFileContents;
                DebugInfoReader *reader = [[DebugInfoReader alloc] initWithData:debugData];
                debugInfo = [reader debugInfo];
            }
            return YES;
        }
        else
        {
            *outError = [NSError errorWithDomain:@"No z-code output file found within project bundle"
                                            code:666
                                        userInfo:nil];
            return NO;
        }
    }
    else
        return [super readFromFileWrapper:fileWrapper
                                   ofType:typeName
                                    error:outError];

    *outError = [NSError errorWithDomain:@"Unsupported document bundle format"
                                    code:666
                                userInfo:nil];
    return NO;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    blorb = nil;

    if ([typeName compare:@"ZCode Blorb"] == 0)
    {
        // This is a blorb, so we need to unwrap
        if ([Blorb isBlorbData:data])
        {
            blorb = [[Blorb alloc] initWithData:data];
            NSData *mddata = [blorb metaData];
            if (mddata)
            {
                IFictionMetadata *ifmd = [[IFictionMetadata alloc] initWithData:mddata];
                metadata = [ifmd stories][0];
                ifid = [[metadata identification] ifids][0];
            }
            zcodeData = [blorb zcodeData];
        }
    }
    else
    {
        // Treat this data as executable z-code story data
        zcodeData = data;
    }
    
    if (zcodeData)
    {
        [self createZMachine];

        // Is there any debug information to load?
        NSString *path = self.fileURL.path;
        NSString *folderPath = path.stringByDeletingLastPathComponent;
        NSString *debugInfoPath = [folderPath stringByAppendingPathComponent:@"gameinfo.dbg"];
        NSURL *debugInfoURL = [NSURL fileURLWithPath:debugInfoPath];
        NSData *debugData = [NSData dataWithContentsOfURL:debugInfoURL];
        if (debugData)
        {
            DebugInfoReader *reader = [[DebugInfoReader alloc] initWithData:debugData];
            debugInfo = [reader debugInfo];
        }
        
        return YES;
    }
    else
    {
        *outError = [NSError errorWithDomain:@"Unsupported file format"
                                        code:666
                                    userInfo:nil];
        return NO;
    }
}

- (NSArray *)facets
{
    return facets;
}

- (NSString *)inputString
{
    return inputString;
}

- (void)setInputString:(NSString *)input
{
    inputString = input;
}

- (NSData *)zcodeData
{
    return zcodeData;
}

- (Blorb *)blorb
{
    return blorb;
}

- (IFStory *)metadata
{
    return metadata;
}

- (NSString *)ifid
{
    return ifid;
}

- (ZMachine *)zMachine
{
    return zMachine;
}

- (DebugInfo *)debugInfo
{
    return debugInfo;
}

- (BOOL)hasEnded
{
    return [zMachine hasQuit];
}

- (NSData *)savedSessionData
{
    [controller restoreSession];
    return nil;
}

- (void)saveSessionData:(NSData *)data
{
    [controller saveSessionData:data];
}

- (unsigned int)lastRestoreOrSaveResult
{
    return lastRestoreOrSaveResult;
}

- (void)setLastRestoreOrSaveResult:(unsigned int)result
{
    lastRestoreOrSaveResult = result;
}

- (void)error:(NSString *)errorMessage
{
    [controller showError:errorMessage];
}

- (void)updateWindowLayout
{
    [controller updateWindowLayout];
}

- (void)updateWindowWidth
{
    [controller updateWindowWidth];
}

- (void)handleBackgroundColourChange:(NSNotification *)note
{
    //    Preferences *sender = [note object];
    //    NSColor *newColour = [sender backgroundColour];
    //    [[layoutView lowerWindow] setBackgroundColor:newColour];
    //    [[layoutView upperWindow] setBackgroundColor:newColour];
    //    [layoutView setNeedsDisplay:YES];
}

- (void)handleForegroundColourChange:(NSNotification *)note
{
}

- (void)handleFontChange:(NSNotification *)note
{
    NSLog(@"Font change");
    
    Preferences *prefs = [Preferences sharedPreferences];
    StoryFacet *facet;
    for (facet in facets)
    {
        // Adjust the current font attribute
        NSFont *font = [prefs fontForStyle:[facet currentStyle]];
        [facet currentAttributes][NSFontAttributeName] = font;
        
        // Scan all the text and convert the fonts found within
        unsigned int index = 0;
        while (index < [facet textStorage].length)
        {
            NSRange range;
            NSFont *oldFont = [[facet textStorage] attribute:NSFontAttributeName
                                                     atIndex:index
                                              effectiveRange:&range];
            if (oldFont)
            {
                NSLog(@"Old font: %@ (%f)", oldFont.fontName, oldFont.pointSize);
                NSFont *newFont = [prefs convertFont:oldFont
                                     forceFixedPitch:NO];
                NSLog(@"New font: %@ (%f)", newFont.fontName, newFont.pointSize);
                [[facet textStorage] addAttribute:NSFontAttributeName
                                            value:newFont
                                            range:range];
            }
            index += range.length;
        }
    }
    [controller updateTextAttributes];
    [controller updateWindowLayout];
}

- (NSString *)input
{
    [controller prepareInput];
    
    // 'input' consumes the input string
    NSString *retString = inputString;
    inputString = nil;
    return retString;
}

- (char)inputChar
{
    [controller prepareInputChar];
    
    // 'inputChar' consumes the input string
    char c = [inputString characterAtIndex:0];
    inputString = nil;
    return c;
}

@end
