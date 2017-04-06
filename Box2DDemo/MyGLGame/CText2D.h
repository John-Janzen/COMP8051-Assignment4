//
//  CText2D.h
//  GLESTextDemos
//
//  Created by Borna Noureddin on 2015-03-18.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface CText2D : NSObject

@property (nonatomic) int pointSize;
@property (nonatomic) int dotsPerInch;
@property (nonatomic) CGPoint textLocation;

-(void)DrawText:(NSString*)str inView:(UIView *)view;
-(void)DrawText:(NSString*)str inView:(UIView *)view withColor:(GLKVector3)col;

@end
