//
//  main.m
//  cartool
//
//  Created by Steven Troughton-Smith on 14/07/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CUICommonAssetStorage : NSObject

-(NSArray *)allAssetKeys;
-(NSArray *)allRenditionNames;

-(id)initWithPath:(NSString *)p;

-(NSString *)versionString;

@end

@interface CUINamedImage : NSObject

-(CGImageRef)image;

@end

@interface CUIRenditionKey : NSObject
@end

@interface CUIThemeFacet : NSObject

+(CUIThemeFacet *)themeWithContentsOfURL:(NSURL *)u error:(NSError **)e;

@end

@interface CUICatalog : NSObject

-(id)initWithName:(NSString *)n fromBundle:(NSBundle *)b;
-(id)allKeys;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s deviceIdiom:(int)idiom;

@end

#define kCoreThemeIdiomPhone 1
#define kCoreThemeIdiomPad 2

void CGImageWriteToFile(CGImageRef image, NSString *path)
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}


void exportCarFileAtPath(NSString * carPath, NSString *outputDirectoryPath)
{
    NSError *error = nil;
    
    outputDirectoryPath = [outputDirectoryPath stringByExpandingTildeInPath];
    
    CUIThemeFacet *facet = [CUIThemeFacet themeWithContentsOfURL:[NSURL fileURLWithPath:carPath] error:&error];
    
    CUICatalog *catalog = [[CUICatalog alloc] init];
    
    /* Override CUICatalog to point to a file rather than a bundle */
    [catalog setValue:facet forKey:@"_storageRef"];
    
    /* CUICommonAssetStorage won't link */
    CUICommonAssetStorage *storage = [[NSClassFromString(@"CUICommonAssetStorage") alloc] initWithPath:carPath];
    
    for (NSString *key in [storage allRenditionNames])
    {
        printf("%s\n", [key UTF8String]);
        
        CGImageRef iphone2X = [[catalog imageWithName:key scaleFactor:2.0 deviceIdiom:kCoreThemeIdiomPhone] image];
        CGImageRef iphone3X = [[catalog imageWithName:key scaleFactor:3.0 deviceIdiom:kCoreThemeIdiomPhone] image];
        
        if (iphone2X)
            CGImageWriteToFile(iphone2X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", key]]);
        
        if (iphone3X)
            CGImageWriteToFile(iphone3X, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@3x.png", key]]);
    }
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        if (argc != 3)
        {
            printf("Usage: cartool Assets.car outputDirectory\n");
            return -1;
        }
        
        exportCarFileAtPath([NSString stringWithUTF8String:argv[1]], [NSString stringWithUTF8String:argv[2]]);
        
    }
    return 0;
}
