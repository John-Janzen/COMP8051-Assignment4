//
//  Player.h
//  MyGLGame
//
//  Created by John Janzen on 2017-04-05.
//  Copyright © 2017 BCIT. All rights reserved.
//

#ifndef Player_h
#define Player_h
#include "Collidables.h"


@interface Player : Collidable {
@public
    int _indices;
    GLuint _vertexBuffer[2], _vertexArray;
}

- (id) init;

@end


#endif /* Player_h */
