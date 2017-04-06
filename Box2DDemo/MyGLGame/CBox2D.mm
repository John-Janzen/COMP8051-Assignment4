//
//  CBox2D.m
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <OpenGLES/ES2/glext.h>
#include <stdio.h>
#include "Brick.h"
#include "Player.h"
#include "Wall.h"
#include "Floor.h"
#include "Collidables.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
//#define LOG_TO_CONSOLE

#pragma mark - Brick and ball physics parameters

// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X			27.5
#define BRICK_WIDTH			50.0f
#define BRICK_HEIGHT		10.0f
#define BRICK_WAIT			1.5f
#define BALL_POS_X			400
#define BALL_POS_Y			75
#define BALL_RADIUS			15.0f
#define BALL_VELOCITY		100000000.0f
#define BALL_SPHERE_SEGS	128

const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            if (parentObj != nil) {
                for (Collidable *object in parentObj->objects) {
                    if (object->body == bodyA) {
                        object->hit = true;
                        return;
                    }
                }
            }
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    b2Body *theBall;
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    
    CContactListener *contactListener;
    
    // GL-specific variables
    // You will need to set up 2 vertex arrays (for brick and ball)
    GLuint ballVertexArray;
    int numBallVerts, numOfBricks, brickDistanceDown, bricksPerRow;
    CGFloat width, height;
    GLKMatrix4 modelViewProjectionMatrix;

    // You will also need some extra variables here
    bool ballLaunched, ballHitFloor, started, _type;
    float totalElapsedTime;
}

@end

@implementation CBox2D

- (instancetype)init : (bool) type
{
    self = [super init];
    if (self) {
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        objects = [[NSMutableArray alloc] init];
        width = [UIScreen mainScreen].bounds.size.width;
        height = [UIScreen mainScreen].bounds.size.height;
        bricksPerRow = width / BRICK_WIDTH;
        numOfBricks = bricksPerRow * 6;
        brickDistanceDown = (numOfBricks / bricksPerRow) * BRICK_HEIGHT;
        _type = type;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        [self InitializePieces];
        
        totalElapsedTime = 0;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched && !started)
    {
        theBall->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);

        ballLaunched = false;
        started = true;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    for (int i = 0; i < objects.count; i++) {
        Collidable *object = [objects objectAtIndex:i];
        if (object->hit && [object isKindOfClass:[Brick class]]) {
            theBall->SetAngularVelocity(0);
            world->DestroyBody(object->body);
            [objects removeObject:object];
            i--;
            numOfBricks--;
            NSLog(@"Brick Hit");
        }
        if (object->hit && [object isKindOfClass:[Player class]]) {
            float direction = (theBall->GetPosition().x - object->body->GetPosition().x) / BRICK_WIDTH;
            if ([object->_ID isEqualToString:@"Player"]) {
                theBall->SetLinearVelocity(b2Vec2(BALL_VELOCITY * direction, BALL_VELOCITY));
            } else {
                theBall->SetLinearVelocity(b2Vec2(BALL_VELOCITY * direction, -BALL_VELOCITY));
            }
            
            theBall->SetAngularVelocity(0);
            NSLog(@"Player Hit");
            object->hit = false;
        }
        if (object->hit && [object isKindOfClass:[Floor class]]) {
            theBall->SetAwake(false);
            if (_type) {
                theBall->SetTransform(b2Vec2(width / 2, BALL_POS_Y), 0);
            } else {
                theBall->SetTransform(b2Vec2(width / 2, height / 2), 0);
            }
            
            NSLog(@"Floor Hit");
            object->hit = false;
            started = false;
        }
        if (object->hit && [object isKindOfClass:[Wall class]]) {
            NSLog(@"Wall Hit");
            object->hit = false;
        }
    }
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
    
    for (Collidable *object in objects) {
        if ([object isKindOfClass:[Player class]]) {
            Player *player = (Player*) object;
            glGenVertexArraysOES(1, &player->_vertexArray);
            glBindVertexArrayOES(player->_vertexArray);
            
            glGenBuffers(2, player->_vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, player->_vertexBuffer[0]);
            GLfloat vertPos[18];
            int k = 0;
            player->_indices = 0;
            vertPos[k++] = player->body->GetPosition().x - BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y + BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            vertPos[k++] = player->body->GetPosition().x + BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y + BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            vertPos[k++] = player->body->GetPosition().x + BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y - BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            vertPos[k++] = player->body->GetPosition().x - BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y + BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            vertPos[k++] = player->body->GetPosition().x + BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y - BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            vertPos[k++] = player->body->GetPosition().x - BRICK_WIDTH;
            vertPos[k++] = player->body->GetPosition().y - BRICK_HEIGHT/2;
            vertPos[k++] = 10;
            player->_indices++;
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
            glEnableVertexAttribArray(VertexAttribPosition);
            glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
            
            GLfloat vertCol[player->_indices*3];
            for (k=0; k<player->_indices*3; k+=3)
            {
                vertCol[k] = 1.0f;
                vertCol[k+1] = 1.0f;
                vertCol[k+2] = 0.0f;
            }
            glBindBuffer(GL_ARRAY_BUFFER, player->_vertexBuffer[1]);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
            glEnableVertexAttribArray(VertexAttribColor);
            glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
            
            glBindVertexArrayOES(0);
        }
    }
    
    

   
    // Set up vertex arrays and buffers for the brick and ball here
    
    if (theBall)
    {
        glGenVertexArraysOES(1, &ballVertexArray);
        glBindVertexArrayOES(ballVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];
        int k = 0;
        vertPos[k++] = theBall->GetPosition().x;
        vertPos[k++] = theBall->GetPosition().y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            vertPos[k++] = theBall->GetPosition().x + sin(t)*BALL_RADIUS;
            vertPos[k++] = theBall->GetPosition().y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        glBindVertexArrayOES(0);
    }

    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, -10, 100);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

-(void)Render:(int)mvpMatPtr
{
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t",
               theBall->GetPosition().x, theBall->GetPosition().y);
    printf("\n");
#endif
    
    glClearColor(0, 0, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUniformMatrix4fv(mvpMatPtr, 1, 0, modelViewProjectionMatrix.m);

    // Bind each vertex array and call glDrawArrays
    //  for each of the ball and brick

    for (Collidable *object in objects) {
        if ([object isKindOfClass:[Brick class]]) {
            Brick *brick = (Brick*)object;
            glBindVertexArrayOES(brick->_vertexArray);
            if (object->body && brick->_indices > 0)
                glDrawArrays(GL_TRIANGLES, 0, brick->_indices);
        } else if ([object isKindOfClass:[Player class]]) {
            Player *player = (Player*)object;
            glBindVertexArrayOES(player->_vertexArray);
            if (player->body && player->_indices > 0)
                glDrawArrays(GL_TRIANGLES, 0, player->_indices);
        }
    }
    
    glBindVertexArrayOES(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    
    
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void)movePlayer:(CGFloat)pos {
    for (Collidable *object in objects) {
        if ([object isKindOfClass:[Player class]]) {
            Player *player = (Player*)object;
            if ([player->_ID isEqualToString:@"Player"]) {
                player->body->SetTransform(b2Vec2(pos, 25.0f), 0);
            } else {
                player->body->SetTransform(b2Vec2(pos, height - 25.0f), 0);
            }
        }
    }
}

- (void) InitializePieces {
    int ballLocationY;
    if (_type) {
        
        for (int i = 0, row = 0, col = 0; i < numOfBricks; i++, row++) {
            if (BRICK_POS_X + (row * BRICK_WIDTH) + (row * 3) > width) {
                row = 0; col++;
            }
            [objects addObject:[[Brick alloc] init]];
            Brick *object = [objects lastObject];
            b2BodyDef brickBodyDef;
            brickBodyDef.type = b2_kinematicBody;
            brickBodyDef.position.Set(BRICK_POS_X + (row * BRICK_WIDTH) + (row * 3), ((height + ((col - 2) * 15)) - brickDistanceDown) - height / 2);
            object->body = world->CreateBody(&brickBodyDef);
            if (object->body)
            {
                object->body->SetUserData((__bridge void *)self);
                object->body->SetAwake(false);
                b2PolygonShape dynamicBox;
                dynamicBox.SetAsBox(BRICK_WIDTH / 2, BRICK_HEIGHT / 2);
                b2FixtureDef fixtureDef;
                fixtureDef.shape = &dynamicBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 1.0f;
                object->body->CreateFixture(&fixtureDef);
                object->hit = false;
                object->_ID = @"Brick";
                
            }
        }
        
        glEnable(GL_DEPTH_TEST);
        
        for (Collidable *object in objects) {
            if (object->body && [object isKindOfClass:[Brick class]])
            {
                Brick *brick = (Brick*)object;
                glGenVertexArraysOES(1, &brick->_vertexArray);
                glBindVertexArrayOES(brick->_vertexArray);
                
                glGenBuffers(2, brick->_vertexBuffer);
                glBindBuffer(GL_ARRAY_BUFFER, brick->_vertexBuffer[0]);
                GLfloat vertPos[18];
                int k = 0;
                brick->_indices = 0;
                vertPos[k++] = brick->body->GetPosition().x - BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y + BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                vertPos[k++] = brick->body->GetPosition().x + BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y + BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                vertPos[k++] = brick->body->GetPosition().x + BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y - BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                vertPos[k++] = brick->body->GetPosition().x - BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y + BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                vertPos[k++] = brick->body->GetPosition().x + BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y - BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                vertPos[k++] = brick->body->GetPosition().x - BRICK_WIDTH/2;
                vertPos[k++] = brick->body->GetPosition().y - BRICK_HEIGHT/2;
                vertPos[k++] = 10;
                brick->_indices++;
                glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
                glEnableVertexAttribArray(VertexAttribPosition);
                glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
                
                GLfloat vertCol[brick->_indices*3];
                for (k=0; k<brick->_indices*3; k+=3)
                {
                    vertCol[k] = 1.0f;
                    vertCol[k+1] = 0.0f;
                    vertCol[k+2] = 0.0f;
                }
                glBindBuffer(GL_ARRAY_BUFFER, brick->_vertexBuffer[1]);
                glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
                glEnableVertexAttribArray(VertexAttribColor);
                glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
                
                glBindVertexArrayOES(0);
            }
        }
        ballLocationY = BALL_POS_Y;
    } else {
        [objects addObject:[[Player alloc] init]];
        Player *object = [objects lastObject];
        b2BodyDef brickBodyDef;
        brickBodyDef.type = b2_kinematicBody;
        brickBodyDef.position.Set(width / 2, height - 25.0f);
        object->body = world->CreateBody(&brickBodyDef);
        if (object->body)
        {
            object->body->SetUserData((__bridge void *)self);
            object->body->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH, BRICK_HEIGHT / 2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            object->body->CreateFixture(&fixtureDef);
            object->hit = false;
            object->_ID = @"Enemy";
        }
        
        ballLocationY = height / 2;
    }
    
    [objects addObject:[[Player alloc] init]];
    Player *object = [objects lastObject];
    b2BodyDef brickBodyDef;
    brickBodyDef.type = b2_kinematicBody;
    brickBodyDef.position.Set(width / 2, 25.0f);
    object->body = world->CreateBody(&brickBodyDef);
    if (object->body)
    {
        object->body->SetUserData((__bridge void *)self);
        object->body->SetAwake(false);
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(BRICK_WIDTH, BRICK_HEIGHT / 2);
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.0f;
        fixtureDef.restitution = 1.0f;
        object->body->CreateFixture(&fixtureDef);
        object->hit = false;
        object->_ID = @"Player";
    }
    
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(width / 2, ballLocationY);
    theBall = world->CreateBody(&ballBodyDef);
    if (theBall)
    {
        theBall->SetUserData((__bridge void *)self);
        theBall->SetAwake(false);
        b2CircleShape circle;
        circle.m_p.Set(0, 0);
        circle.m_radius = BALL_RADIUS;
        b2FixtureDef circleFixtureDef;
        circleFixtureDef.shape = &circle;
        circleFixtureDef.density = 0.2f;
        circleFixtureDef.friction = 0.0f;
        circleFixtureDef.restitution = 1.0f;
        theBall->CreateFixture(&circleFixtureDef);
    }
}

-(void)HelloWorld
{
    [objects addObject:[[Floor alloc] init]];
    Floor *floor = [objects lastObject];
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_kinematicBody;
    bodyDef.position.Set(width / 2, -15.0f);
    floor->body = world->CreateBody(&bodyDef);
    if (floor->body) {
        floor->body->SetUserData((__bridge void *)self);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(width, 5.0f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        
        // Set the box density to be non-zero, so it will be dynamic.
        fixtureDef.density = 1.0f;
        
        // Override the default friction.
        fixtureDef.friction = 0.3f;
        
        // Add the shape to the body.
        floor->body->CreateFixture(&fixtureDef);
        floor->_ID = @"PlayerFloor";
    }
    
    [objects addObject:[[Floor alloc] init]];
    floor = [objects lastObject];
    
    // Define the dynamic body. We set its position and call the body factory.
    bodyDef.type = b2_kinematicBody;
    bodyDef.position.Set(width / 2, height + 15.0f);
    floor->body = world->CreateBody(&bodyDef);
    if (floor->body) {
        floor->body->SetUserData((__bridge void *)self);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(width, 5.0f);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        
        // Set the box density to be non-zero, so it will be dynamic.
        fixtureDef.density = 1.0f;
        
        // Override the default friction.
        fixtureDef.friction = 0.3f;
        
        // Add the shape to the body.
        floor->body->CreateFixture(&fixtureDef);
        floor->_ID = @"Roof";
    }
    
    [objects addObject:[[Wall alloc] init]];
    Wall *wall = [objects lastObject];
    
    bodyDef.type = b2_kinematicBody;
    bodyDef.position.Set(0.0f, height / 2);
    wall->body = world->CreateBody(&bodyDef);
    if (wall->body) {
        wall->body->SetUserData((__bridge void *)self);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(5.0f, height);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        
        // Set the box density to be non-zero, so it will be dynamic.
        fixtureDef.density = 1.0f;
        
        // Override the default friction.
        fixtureDef.friction = 0.0f;
        
        // Add the shape to the body.
        wall->body->CreateFixture(&fixtureDef);
        wall->_ID = @"LeftWall";
    }
    
    [objects addObject:[[Wall alloc] init]];
    wall = [objects lastObject];
    
    bodyDef.type = b2_kinematicBody;
    bodyDef.position.Set(width, height / 2);
    wall->body = world->CreateBody(&bodyDef);
    if (wall->body) {
        wall->body->SetUserData((__bridge void *)self);
        
        // Define another box shape for our dynamic body.
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(5.0f, height);
        
        // Define the dynamic body fixture.
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        
        // Set the box density to be non-zero, so it will be dynamic.
        fixtureDef.density = 1.0f;
        
        // Override the default friction.
        fixtureDef.friction = 0.0f;
        
        // Add the shape to the body.
        wall->body->CreateFixture(&fixtureDef);
        wall->_ID = @"RightWall";
    }
    
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 10;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        

    }
}

@end
