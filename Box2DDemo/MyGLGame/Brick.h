//
//  Brick.h
//  MyGLGame
//
//  Created by John Janzen on 2017-04-03.
//  Copyright © 2017 BCIT. All rights reserved.
//

#ifndef Brick_h
#define Brick_h
#include "Collidables.h"

@interface Brick : Collidable{
    @public
    int _indices;
    GLuint _vertexBuffer[2], _vertexArray;
}

- (id) init;

@end

#endif /* Brick_h */
