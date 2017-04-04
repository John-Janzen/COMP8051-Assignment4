//
//  Brick.m
//  MyGLGame
//
//  Created by John Janzen on 2017-04-03.
//  Copyright © 2017 BCIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Brick.h"

@implementation Brick

- (id) init:(int)posX :(int)posY :(int)width :(int)height {
    
    self = [super init];
    if (self) {
        positionX = posX; positionY = posY;
        _width = width; _height = height;
        _indices = 0;
    }
    
    return self;
}

@end
