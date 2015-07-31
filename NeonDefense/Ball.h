//
//  Ball.h
//  NeonDefense
//
//  Created by Andy Lee on 11/07/2015.
//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Ball : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int numberOfBounces;

-(void)updateTrail;

@end