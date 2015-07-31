//
//  GameMenu.h
//  NeonDefence
//
//  Created by Andy Lee on 11/07/2015.
//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL musicPlaying;

-(void)hide;
-(void)show;

@end
