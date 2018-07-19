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
@property (copy) NSColor *backgroundColour;

/*!
 @method setBackgroundColour
 @abstract Sets the preferred background colour.
 @param colour The new background colour.
*/

/*!
 @method foregroundColour
 @abstract Returns the preferred foreground colour.
*/
@property (copy) NSColor *foregroundColour;

/*!
 @method setForegroundColour
 @abstract Sets the preferred foreground colour.
 @param colour The new foreground colour.
*/

/*!
 @method proportionalFontFamily
 @abstract Returns the preferred font family name for proportional fonts.
*/
@property (copy) NSString *proportionalFontFamily;

/*!
 @method setProportionalFontFamily
 @abstract Sets the preferred font family name for proportional fonts.
 @param family The new font family name.
*/

/*!
 @method monospacedFontFamily
 @abstract Returns the preferred font family name for monospaced fonts.
*/
@property (copy) NSString *monospacedFontFamily;

/*!
 @method setMonospacedFontFamily
 @abstract Sets the preferred font family name for monospaced fonts.
 @param family The new font family name.
*/

/*!
 @method fontSize
 @abstract Returns the preferred font size.
*/
@property  float fontSize;

/*!
 @method setFontSize
 @abstract Sets the preferred font size.
 @param size The new font size.
*/

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
@property (readonly) float proportionalLineHeight;

/*!
 @method monospacedlineHeight
 @abstract Returns the height of a monospaced text line, based on the preferred
           font selection.
 */
@property (readonly) float monospacedLineHeight;

/*!
 @method monospacedCharacterWidth
 @abstract Returns the width of a monospaced character, based on the preferred
           font selection.
 */
@property (readonly) float monospacedCharacterWidth;

/*!
 @method showsLibraryOnStartup
 @abstract Returns YES if the IF library is to be shown when starting the app.
 */
@property  BOOL showsLibraryOnStartup;

/*!
 @method setShowsLibraryOnStartup
 @abstract Sets whether the IF library is to be shown when starting the app.
 @param show YES if the library is to be shown.
 */

@end
