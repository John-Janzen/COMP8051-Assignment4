//
//  Collidables.h
//  MyGLGame
//
//  Created by John Janzen on 2017-04-05.
//  Copyright © 2017 BCIT. All rights reserved.
//

#ifndef Collidables_h
#define Collidables_h
#include <Box2D/Box2D.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface Collidable : NSObject {
    @public
    bool hit;
    b2Body *body;
    NSString *_ID;
}

@end


#endif /* Collidables_h */
