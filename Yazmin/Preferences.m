//
//  Preferences.m
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "Preferences.h"

NSString *SMBackgroundColourKey = @"BackgroundColour";
NSString *SMForegroundColourKey = @"ForegroundColour";
NSString *SMMonospacedFontKey = @"MonospacedFont";
NSString *SMProportionalFontKey = @"ProportionalFont";
NSString *SMFontSizeKey = @"FontSize";
NSString *SMShowLibraryOnStartupKey = @"ShowLibraryOnStartup";

@implementation Preferences

+ (Preferences *)sharedPreferences
{
    // This is never deallocated, so what is a better way of doing this?
    static Preferences *preferences = nil;
    if (!preferences)
        preferences = [[Preferences alloc] init];
    return preferences;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        defaults = [NSUserDefaults standardUserDefaults];
        nc = [NSNotificationCenter defaultCenter];
        fonts = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [fonts release];
    [super dealloc];
}

- (NSColor *)backgroundColour
{
    NSData *colourAsData = [defaults objectForKey:SMBackgroundColourKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:colourAsData];
}

- (void)setBackgroundColour:(NSColor *)colour
{
    NSData *colourAsData = [NSKeyedArchiver archivedDataWithRootObject:colour];
    [defaults setObject:colourAsData forKey:SMBackgroundColourKey];
    [nc postNotificationName:@"SMBackgroundColourChanged" object:self];
}

- (NSColor *)foregroundColour
{
    NSData *colourAsData = [defaults objectForKey:SMForegroundColourKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:colourAsData];
}

- (void)setForegroundColour:(NSColor *)colour
{
    NSData *colourAsData = [NSKeyedArchiver archivedDataWithRootObject:colour];
    [defaults setObject:colourAsData forKey:SMForegroundColourKey];
    [nc postNotificationName:@"SMForegroundColourChanged" object:self];
}

- (NSString *)proportionalFontFamily
{
    return [defaults objectForKey:SMProportionalFontKey];
}

- (void)setProportionalFontFamily:(NSString *)family
{
    [defaults setObject:family forKey:SMProportionalFontKey];
    [fonts removeAllObjects];
    [nc postNotificationName:@"SMProportionalFontFamilyChanged" object:self];
}

- (NSString *)monospacedFontFamily
{
    return [defaults objectForKey:SMMonospacedFontKey];
}

- (void)setMonospacedFontFamily:(NSString *)family
{
    [defaults setObject:family forKey:SMMonospacedFontKey];
    [fonts removeAllObjects];
    [nc postNotificationName:@"SMMonospacedFontFamilyChanged" object:self];
}

- (float)fontSize
{
    return [[defaults objectForKey:SMFontSizeKey] floatValue];
}

- (void)setFontSize:(float)size
{
    [defaults setObject:[NSNumber numberWithFloat:size] forKey:SMFontSizeKey];
    [fonts removeAllObjects];
    [nc postNotificationName:@"SMFontSizeChanged" object:self];
}

- (NSFont *)fontForStyle:(int)style
{
    // Mask-off the reverse flag bit, as the font will be the same anyhow
    style &= 0xfe;

    // Check our font cache for this style
    NSFont *font = [fonts objectForKey:[NSNumber numberWithInt:style]];
    if (font == nil)
    {
        // What font family are we using?
        NSString *fontFamily;
        if (style & 8)
            fontFamily = [self monospacedFontFamily];
        else
            fontFamily = [self proportionalFontFamily];
        
        // Bold and italic traits?
        NSFontTraitMask traits = 0;
        if (style & 6)
        {
            if (style & 2)
                traits |= NSBoldFontMask;
            if (style & 4)
                traits |= NSItalicFontMask;
        }
        font = [[NSFontManager sharedFontManager] fontWithFamily:fontFamily
                                                          traits:traits
                                                          weight:5
                                                            size:[self fontSize]];
        [fonts setObject:font forKey:[NSNumber numberWithInt:style]];
    }
    return font;
}

- (NSFont *)convertFont:(NSFont *)font forceFixedPitch:(BOOL)fixedPitch;
{
    // Determine the style of this font
    NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];
    int style = 0;
    if (traits & NSBoldFontMask)
        style |= 2;
    if (traits & NSItalicFontMask)
        style |= 4;
    if ((traits & NSFixedPitchFontMask) || fixedPitch)
        style |= 8;
    return [self fontForStyle:style];
}

- (float)proportionalLineHeight
{
    NSFont *font = [self fontForStyle:0];
    return [font boundingRectForFont].size.height;
}

- (float)monospacedLineHeight
{
    NSFont *font = [self fontForStyle:8];
    return [font boundingRectForFont].size.height;
}

- (float)monospacedCharacterWidth
{
    NSFont *font = [self fontForStyle:8];
    return [font advancementForGlyph:0].width;
}

- (BOOL)showsLibraryOnStartup
{
    return [[defaults objectForKey:SMShowLibraryOnStartupKey] intValue];
}

- (void)setShowsLibraryOnStartup:(BOOL)show
{
    [defaults setObject:[NSNumber numberWithInt:show]
                 forKey:SMShowLibraryOnStartupKey];
}

@end
