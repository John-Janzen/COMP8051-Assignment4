//
//  CBox2D.h
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum
{
    VertexAttribPosition,
    VertexAttribColor,
    NumVertexAttribs
};

@interface CBox2D : NSObject {
@public
    NSMutableArray *objects;
}

-(id) init:(bool) type :(id) view;

-(void) HelloWorld;

-(void) LaunchBall;
-(void) movePlayer:(CGFloat) pos;
-(void) Update:(float)elapsedTime;
-(void) Render:(int)mvpMatPtr;
-(void) RegisterHit;

@end

#endif
