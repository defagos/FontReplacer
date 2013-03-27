//
//  UIColor+Replacement.m
//  FontReplacer Demo
//
//  Created by Nick Bransby-Williams on 13/03/2013.
//
//

#import "UIColor+Replacement.h"
#import <objc/runtime.h>

@implementation UIColor (Replacement)

static NSDictionary *replacementDictionary = nil;

static void initializeReplacementColors()
{
	static BOOL initialized = NO;
	if (initialized)
		return;
	initialized = YES;
	
	NSDictionary *replacementDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ReplacementColors"];
	NSLog(@"ReplacementColors = %@", replacementDictionary);
	[UIColor setReplacementDictionary:replacementDictionary];
}

+ (void) load
{
	Method initWithRedGreenBlueAlpha = class_getInstanceMethod([UIColor class], @selector(initWithRed:green:blue:alpha:));
	Method replacementInitWithRedGreenBlueAlpha = class_getInstanceMethod([UIColor class], @selector(replacement_initWithRed:green:blue:alpha:));
    
	if (initWithRedGreenBlueAlpha && replacementInitWithRedGreenBlueAlpha && strcmp(method_getTypeEncoding(initWithRedGreenBlueAlpha), method_getTypeEncoding(replacementInitWithRedGreenBlueAlpha)) == 0)
		method_exchangeImplementations(initWithRedGreenBlueAlpha, replacementInitWithRedGreenBlueAlpha);
}

- (UIColor *)replacementColorForString:(NSString*)string
{
	NSDictionary* info = [replacementDictionary objectForKey:string];
	NSLog(@"Found replacement color %@ for %@", info, string);
	if (!replacementDictionary)
		return nil;
	return [[UIColor colorWithPatternImage:[UIImage imageNamed:[info objectForKey:@"Image"]]] retain];
}


- (UIColor *)replacement_initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	initializeReplacementColors();
	NSString* string = [NSString stringWithFormat:@"{%d,%d,%d}", (int)ceilf(red*255), (int)ceilf(green*255), (int)ceilf(blue*255)];
	return [self replacementColorForString:string] ?: [self replacement_initWithRed:red green:green blue:blue alpha:alpha];
}

+ (NSDictionary *) replacementDictionary
{
	return replacementDictionary;
}

+ (void) setReplacementDictionary:(NSDictionary *)aReplacementDictionary
{
	if (aReplacementDictionary == replacementDictionary)
		return;
	
	for (id key in [aReplacementDictionary allKeys])
	{
		if (![key isKindOfClass:[NSString class]])
		{
			NSLog(@"ERROR: Replacement color key must be a string.");
			return;
		}
		
		NSString *colorName = (NSString *)key;
		id value = [aReplacementDictionary valueForKey:colorName];
		if (![value isKindOfClass:[NSDictionary class]])
		{
			NSLog(@"ERROR: Replacement color value must be a dictionary.");
			return;
		}
		
		NSDictionary *replacementInfo = (NSDictionary *)value;
		NSString *replacementImage = [replacementInfo objectForKey:@"Image"];
		if (!replacementImage)
		{
			NSLog(@"ERROR: Missing image name for color '%@'", colorName);
			return;
		}
		
	}
	[replacementDictionary release];
	replacementDictionary = [aReplacementDictionary retain];
}

@end
