//
//  Preferences.h
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//
/*!
 @header Preferences
 @copyright David Schweinsberg
 @updated 2007-11-14
 @discussion This is a of the HeaderDoc documentation tool.
*/
#import <Cocoa/Cocoa.h>

extern NSString *SMBackgroundColourKey;
extern NSString *SMForegroundColourKey;
extern NSString *SMMonospacedFontKey;
extern NSString *SMProportionalFontKey;
extern NSString *SMFontSizeKey;
extern NSString *SMShowLibraryOnStartupKey;

/*!
 @class Preferences
 The Preferences object handles the global preferences for the application,
 and can be modified by the user via the Preferences.nib/PreferenceController
 object.
*/
@interface Preferences : NSObject
{
    NSUserDefaults *defaults;
    NSNotificationCenter *nc;
    NSMutableDictionary *fonts;
}

/*!
 @method sharedPreferences
 @abstract Returns a shared instance of the Preferences object.
 @discussion The shared instance of the Preferences object is accessable from
 any point in the application.
*/
+ (Preferences *)sharedPreferences;

/*!
 @method backgroundColour
 @abstract Returns the preferred background colour.
*/
- (NSColor *)backgroundColour;

/*!
 @method setBackgroundColour
 @abstract Sets the preferred background colour.
 @param colour The new background colour.
*/
- (void)setBackgroundColour:(NSColor *)colour;

/*!
 @method foregroundColour
 @abstract Returns the preferred foreground colour.
*/
- (NSColor *)foregroundColour;

/*!
 @method setForegroundColour
 @abstract Sets the preferred foreground colour.
 @param colour The new foreground colour.
*/
- (void)setForegroundColour:(NSColor *)colour;

/*!
 @method proportionalFontFamily
 @abstract Returns the preferred font family name for proportional fonts.
*/
- (NSString *)proportionalFontFamily;

/*!
 @method setProportionalFontFamily
 @abstract Sets the preferred font family name for proportional fonts.
 @param family The new font family name.
*/
- (void)setProportionalFontFamily:(NSString *)family;

/*!
 @method monospacedFontFamily
 @abstract Returns the preferred font family name for monospaced fonts.
*/
- (NSString *)monospacedFontFamily;

/*!
 @method setMonospacedFontFamily
 @abstract Sets the preferred font family name for monospaced fonts.
 @param family The new font family name.
*/
- (void)setMonospacedFontFamily:(NSString *)family;

/*!
 @method fontSize
 @abstract Returns the preferred font size.
*/
- (float)fontSize;

/*!
 @method setFontSize
 @abstract Sets the preferred font size.
 @param size The new font size.
*/
- (void)setFontSize:(float)size;

/*!
 @method fontForStyle
 @abstract Retrieves a font based on the specified style.
 @param style The specified style mask.
 @result A font that conforms to the specified style.
*/
- (NSFont *)fontForStyle:(int)style;

/*!
 @method convertFont:forceFixedPitch:
 @abstract Converts the specified font into the current font family and size
 based on the specified font's traits.
 @param font The font to convert from.
 @param fixedPitch Is the font conversion to be forced to monospacing?  With
        any luck this parameter won't be needed.
 @result The converted font.
*/
- (NSFont *)convertFont:(NSFont *)font forceFixedPitch:(BOOL)fixedPitch;

/*!
 @method proportionalLineHeight
 @abstract Returns the height of a proportional text line, based on the preferred
           font selection.
*/
- (float)proportionalLineHeight;

/*!
 @method monospacedlineHeight
 @abstract Returns the height of a monospaced text line, based on the preferred
           font selection.
 */
- (float)monospacedLineHeight;

/*!
 @method monospacedCharacterWidth
 @abstract Returns the width of a monospaced character, based on the preferred
           font selection.
 */
- (float)monospacedCharacterWidth;

/*!
 @method showsLibraryOnStartup
 @abstract Returns YES if the IF library is to be shown when starting the app.
 */
- (BOOL)showsLibraryOnStartup;

/*!
 @method setShowsLibraryOnStartup
 @abstract Sets whether the IF library is to be shown when starting the app.
 @param show YES if the library is to be shown.
 */
- (void)setShowsLibraryOnStartup:(BOOL)show;

@end
