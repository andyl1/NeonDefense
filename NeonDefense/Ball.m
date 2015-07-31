//
//  Ball.m
//  NeonDefense
//
//  Created by Andy Lee on 11/07/2015.
//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import "Ball.h"

@implementation Ball

-(void)updateTrail {
    if (self.trail) {
        self.trail.position = self.position;
    }
}

-(void)removeFromParent {
    if (self.trail) {
        self.trail.particleBirthRate = 0;
        
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime
                                                      + self.trail.particleLifetimeRange],
                                                     [SKAction removeFromParent]]];
        [self runAction:removeTrail];
    }
    [super removeFromParent];
}

@end

