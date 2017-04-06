//
//  CText2D.m
//  GLESTextDemos
//
//  Created by Borna Noureddin on 2015-03-18.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import "CText2D.h"

#include <ft2build.h>
#include FT_FREETYPE_H


@interface CText2D()
{
    UIImageView *textiv;
    FT_Face       face;
}

@end

@implementation CText2D

@synthesize pointSize;
@synthesize dotsPerInch;
@synthesize textLocation;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self TextInit];
    }
    return self;
}


-(void)DrawText:(NSString*)str inView:(UIView *)view
{
    [self DrawText:str inView:view withColor:GLKVector3Make(1, 1, 1)];
}

-(void)DrawText:(NSString*)str inView:(UIView *)view withColor:(GLKVector3)col
{
    if (view == NULL)
        return;
    
    FT_Error error = FT_Set_Char_Size(face, pointSize * 64, pointSize * 64, dotsPerInch, dotsPerInch);
    if (error)
    {
        NSLog(@"Could not set font size!\n");
        return;
    }
    
    char *cstr = (char *)[str UTF8String];
    int nChars = strlen(cstr);
    
    // View and image parameters
    int myWidth = view.bounds.size.width;
    int myHeight = view.bounds.size.height;
    int w = myWidth / 2;
    int h = myHeight / 4;
    
    // Create new pixel data
    unsigned char *rawData = (unsigned char *)malloc(h * w * 4);
    memset(rawData, 0, h*w*4);
    
    int r, c, x, y, offset;
    x = y = 0;
    int gTop, gLeft, yoff, maxTop = -1;
    unsigned char glyphPix;
    for (int n=0; n<nChars; n++)
    {
        FT_Set_Transform(face, NULL, NULL);
        error = FT_Load_Char(face, cstr[n], FT_LOAD_RENDER);
        if (error) continue;
        gTop = face->glyph->bitmap_top;
        if (maxTop < gTop)
            maxTop = gTop;
    }
    for (int n=0; n<nChars; n++)
    {
        FT_Set_Transform(face, NULL, NULL);
        error = FT_Load_Char(face, cstr[n], FT_LOAD_RENDER);
        if (error) continue;
        gTop = face->glyph->bitmap_top;
        gLeft = face->glyph->bitmap_left;
        yoff = maxTop - gTop;
        for (r=0; r<face->glyph->bitmap.rows; r++)
            for (c=0; c<face->glyph->bitmap.width; c++)
            {
                glyphPix = face->glyph->bitmap.buffer[r * face->glyph->bitmap.width + c];
                if (glyphPix)
                {
                    offset = ((y + yoff + r) * w + (gLeft + x + c) ) * 4;
                    rawData[offset] = glyphPix * col.r;
                    rawData[offset+1] = glyphPix * col.g;
                    rawData[offset+2] = glyphPix * col.b;
                    rawData[offset+3] = glyphPix;
                }
            }
        x += face->glyph->advance.x >> 6;
        y += face->glyph->advance.y >> 6;
    }
    
    // Draw the pixels to a CG context and retrieve them into UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * w;
    NSUInteger bitsPerComponent = 8;
    int flags = kCGImageAlphaPremultipliedLast;
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 w,
                                                 h,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 flags );
    CGImageRef imageRef = CGBitmapContextCreateImage (context);
    UIImage *textImage;
    textImage = [UIImage imageWithCGImage:imageRef];
    CGContextRelease(context);
    
    // Free the memory for the raw data
    free(rawData);
    
    // Add a new view with the image
    if (textiv)
        [textiv setImage:textImage];
    else {
        textiv = [[UIImageView alloc] initWithImage:textImage];
        [view addSubview:textiv];
    }
    textiv.frame = CGRectMake(textLocation.x, textLocation.y, w, h);
}

- (void)TextInit
{
    FT_Library ftLib;
    FT_Error error = FT_Init_FreeType(&ftLib);
    if (error)
    {
        NSLog(@"Could not initialize freetype library!\n");
        return;
    }
    
    NSString *fontFile = [[NSBundle mainBundle] pathForResource:@"arial" ofType:@"ttf"];
    char *filename = (char *)[fontFile UTF8String];
    error = FT_New_Face(ftLib, filename, 0, &face);
    if (error)
    {
        NSLog(@"Could not find font file <%s>!\n", filename);
        return;
    }

    pointSize = 12;
    dotsPerInch = 300;
    textLocation.x = 0;
    textLocation.y = 0;
    textiv = NULL;
}

@end
