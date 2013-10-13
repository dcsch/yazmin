//
//  StoryInformationController.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryInformationController.h"
#import "Blorb.h"
#import "IFictionMetadata.h"
#import "IFStory.h"
#import "IFBibliographic.h"

@implementation StoryInformationController

- (id)initWithBlorb:(Blorb *)aBlorb
{
    self = [super initWithWindowNibName:@"StoryInformation"];
    if (self)
    {
        blorb = aBlorb;
        metadata = nil;
        if ([blorb metaData])
            metadata = [[IFictionMetadata alloc] initWithData:[blorb metaData]];
    }
    return self;
}


- (void)windowDidLoad
{
    [imageView setImageFrameStyle:NSImageFramePhoto];
    
    // Set the artwork
    NSData *pictureData = [blorb pictureData];
    if (pictureData)
    {
        NSImage *image = [[NSImage alloc] initWithData:pictureData];
        
        // Resize the image to a high quality thumbnail
        float resizeWidth = 128.0;
        float resizeHeight = 128.0;
        NSImage *resizedImage = [[NSImage alloc] initWithSize:NSMakeSize(resizeWidth, resizeHeight)];

        NSSize originalSize = [image size];
        
        [resizedImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [image drawInRect:NSMakeRect(0, 0, resizeWidth, resizeHeight)
                 fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height)
                operation:NSCompositeSourceOver
                 fraction:1.0];
        [resizedImage unlockFocus];    
        
        [imageView setImage:resizedImage];
    }
    
    if (metadata)
    {
        IFStory *storyMD = [metadata stories][0];
        [title setStringValue:[[storyMD bibliographic] title]];
        [author setStringValue:[[storyMD bibliographic] author]];
        [description setString:[[storyMD bibliographic] description]];
    }
}

@end
