//
//  GameMenu.m
//  NeonDefence
//
//  Created by Andy Lee on 11/07/2015.
//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import "GameMenu.h"

@implementation GameMenu
{
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
    SKSpriteNode *_title;
    SKSpriteNode *_scoreBoard;
    SKSpriteNode *_playButton;
    SKSpriteNode *_musicButton;
}

-(id)init {
    self = [super init];
    if (self) {
        _title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        _title.position = CGPointMake(0, 140);
        [self addChild:_title];
        
        _scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        _scoreBoard.position = CGPointMake(0, 70);
        [self addChild:_scoreBoard];
        
        _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        _playButton.name = @"Play";
        _playButton.position = CGPointMake(0, 0);
        [self addChild:_playButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 20;
        _scoreLabel.position = CGPointMake(-52, -20);
        [_scoreBoard addChild:_scoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 20;
        _topScoreLabel.position = CGPointMake(48, -20);
        [_scoreBoard addChild:_topScoreLabel];
        
        _musicButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        _musicButton.name = @"Music";
        _musicButton.position = CGPointMake(90, 0);
        [self addChild:_musicButton];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;
        
    }
    return self;
}

-(void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

-(void)setTopScore:(int)topScore {
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

-(void)setMusicPlaying:(BOOL)musicPlaying {
    _musicPlaying = musicPlaying;
    if (_musicPlaying) {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    }
    else {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
    }
}

-(void)hide {
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1;
        self.yScale = 1;
    }];
}

-(void)show {
    self.hidden = NO;
    self.touchable = NO;
    
    // Set Fade
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.5];
    
    // Animate Title
    _title.position = CGPointMake(0, 280);
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140 duration:0.5],
                                               fadeIn]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [_title runAction:animateTitle];
    
    // Animate Scoreboard
    _scoreBoard.xScale = 4;
    _scoreBoard.yScale = 4;
    _scoreBoard.alpha = 0;
    SKAction *animateScoreboard = [SKAction group:@[[SKAction scaleTo:1 duration:0.5],
                                                    fadeIn]];
    animateScoreboard.timingMode = SKActionTimingEaseOut;
    [_scoreBoard runAction:animateScoreboard];
    
    // Animate Play Button
    _playButton.alpha = 0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [_playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
    
    // Animate Music On/Off Button
    _musicButton.alpha = 0;
    [_musicButton runAction:animatePlayButton];
}

@end
