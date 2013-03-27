//
//  UIImage+Replacement.m
//  FontReplacer Demo
//
//  Created by Nick Bransby-Williams on 13/03/2013.
//
//

#import "UIImage+Replacement.h"
#import <objc/runtime.h>

@implementation UIImage (Replacement)

static NSDictionary *replacementDictionary = nil;

static void initializeReplacementImages()
{
	static BOOL initialized = NO;
	if (initialized)
		return;
	initialized = YES;
	
	NSDictionary *replacementDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ReplacementImages"];
	NSLog(@"ReplacementImages = %@", replacementDictionary);
	[UIImage setReplacementDictionary:replacementDictionary];
}

+ (void) load
{
	Class class = NSClassFromString(@"UIImageNibPlaceholder");
	Method initWithCoder = class_getInstanceMethod(class, @selector(initWithCoder:));
	Method replacementInitWithCoder = class_getInstanceMethod(class, @selector(replacement_initWithCoder:));
    
	if (initWithCoder && replacementInitWithCoder && strcmp(method_getTypeEncoding(initWithCoder), method_getTypeEncoding(replacementInitWithCoder)) == 0)
		method_exchangeImplementations(initWithCoder, replacementInitWithCoder);
}

+ (NSDictionary *) replacementInfoForImageNamed:(NSString *)imageName
{
	if (!replacementDictionary)
		return nil;
	
	return [replacementDictionary objectForKey:imageName];
}

+ (UIEdgeInsets) capInsetsForInfo:(NSDictionary *)info
{
	NSString* string = [info objectForKey:@"Insets"];
	return string ? UIEdgeInsetsFromString(string) : UIEdgeInsetsZero;
}

+ (UIImageResizingMode) resizingModeForInfo:(NSDictionary *)info
{
	return [info[@"Stretch"] isEqual:@YES] || [info[@"Tile"] isEqual:@NO] ? UIImageResizingModeStretch : UIImageResizingModeTile;
}

- (id) replacement_initWithCoder:(NSCoder *)coder
{
	initializeReplacementImages();
	UIImage* image = [self replacement_initWithCoder:coder];
	NSString * imageName = [coder decodeObjectForKey:@"UIResourceName"];
	NSDictionary* info = [UIImage replacementInfoForImageNamed:imageName];
	return info == nil ? image : [[image resizableImageWithCapInsets:[UIImage capInsetsForInfo:info] resizingMode:[UIImage resizingModeForInfo:info]] retain];
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
			NSLog(@"ERROR: Replacement image key must be a string.");
			return;
		}
		
		NSString *imageName = (NSString *)key;
		id value = [aReplacementDictionary valueForKey:imageName];
		if (![value isKindOfClass:[NSDictionary class]])
		{
			NSLog(@"ERROR: Replacement image value must be a dictionary.");
			return;
		}
		
		NSDictionary *replacementInfo = (NSDictionary *)value;
		NSString *replacementImageInsets = [replacementInfo objectForKey:@"Insets"];
		if (!replacementImageInsets)
		{
			NSLog(@"ERROR: Missing cap insets name for image '%@'", imageName);
			return;
		}
		
	}
	[replacementDictionary release];
	replacementDictionary = [aReplacementDictionary retain];
}

@end
