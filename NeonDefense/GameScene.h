//
//  GameScene.h
//  NeonDefense
//

//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

// Used in .m for their own methods
@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;
@property (nonatomic) BOOL multiMode;
@property (nonatomic) BOOL gamePaused;
@property(readonly, retain, nonatomic) NSDate *date;

-(void)reportScore;

@end