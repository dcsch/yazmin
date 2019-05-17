//
//  Preferences.m
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "Preferences.h"

NSString *SMBackgroundColorKey = @"BackgroundColor";
NSString *SMForegroundColorKey = @"ForegroundColor";
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

- (instancetype)init
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


- (NSColor *)backgroundColor
{
    NSData *colorAsData = [defaults objectForKey:SMBackgroundColorKey];
    return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                             fromData:colorAsData
                                                error:nil];
}

- (void)setBackgroundColor:(NSColor *)color
{
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                                requiringSecureCoding:NO
                                                                error:nil];
    [defaults setObject:colorAsData forKey:SMBackgroundColorKey];
    [nc postNotificationName:@"SMBackgroundColorChanged" object:self];
}

- (NSColor *)foregroundColor
{
    NSData *colorAsData = [defaults objectForKey:SMForegroundColorKey];
    return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                             fromData:colorAsData
                                                error:nil];
}

- (void)setForegroundColor:(NSColor *)color
{
    NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                                requiringSecureCoding:NO
                                                                error:nil];
    [defaults setObject:colorAsData forKey:SMForegroundColorKey];
    [nc postNotificationName:@"SMForegroundColorChanged" object:self];
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
    [defaults setObject:@(size) forKey:SMFontSizeKey];
    [fonts removeAllObjects];
    [nc postNotificationName:@"SMFontSizeChanged" object:self];
}

- (NSFont *)fontForStyle:(int)style
{
    // Mask-off the reverse flag bit, as the font will be the same anyhow
    style &= 0xfe;

    // Check our font cache for this style
    NSFont *font = fonts[@(style)];
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
        fonts[@(style)] = font;
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
    return font.boundingRectForFont.size.height;
}

- (float)monospacedLineHeight
{
    NSFont *font = [self fontForStyle:8];
    return font.boundingRectForFont.size.height;
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
    [defaults setObject:@(show)
                 forKey:SMShowLibraryOnStartupKey];
}

@end
