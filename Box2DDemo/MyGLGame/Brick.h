//
//  Brick.h
//  MyGLGame
//
//  Created by John Janzen on 2017-04-03.
//  Copyright © 2017 BCIT. All rights reserved.
//

#ifndef Brick_h
#define Brick_h
#include <Box2D/Box2D.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface Brick : NSObject {
    @public
    int positionX, positionY;
    int _width, _height, _indices;
    bool hit;
    b2Body *body;
    GLuint _vertexBuffer[2], _vertexArray;
    GLfloat *_verticesArray;
}

- (id) init: (int)posX : (int)posY : (int)width : (int) height;

@end

#endif /* Brick_h */
