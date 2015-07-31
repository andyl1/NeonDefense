//
//  GameScene.m
//  NeonDefense
//
//  Created by Andy Lee on 17/07/2015.
//  Copyright (c) 2015 Andy Lee. All rights reserved.
//

#import "GameScene.h"
#import "GameMenu.h"
#import "Ball.h"
#import <AVFoundation/AVFoundation.h>

@implementation GameScene


// Declaring Class Variables.
{
    AVAudioPlayer *_audioPlayer;
    GameMenu *_menu;
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    BOOL _didShoot;
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_lazerSound;
    SKAction *_zapSound;
    SKAction *_shieldUpSound;
    BOOL _gameOver;
    NSUserDefaults *_userDefaults;
    NSMutableArray *_shieldPool;
}


// Declaring Class Constants
static const CGFloat SHOOT_SPEED            = 1500;
static const CGFloat HALO_LOW_ANGLE         = 200 * M_PI / 180;
static const CGFloat HALO_HIGH_ANGLE        = 340 * M_PI / 180;
static const CGFloat HALO_SPEED             = 100;

static const uint32_t HALO_CATEGORY         = 0x1 << 0;
static const uint32_t BALL_CATEGORY         = 0x1 << 1;
static const uint32_t EDGE_CATEGORY         = 0x1 << 2;
static const uint32_t SHIELD_CATEGORY       = 0x1 << 3;
static const uint32_t LIFEBAR_CATEGORY      = 0x1 << 4;
static const uint32_t SHIELDUP_CATEGORY     = 0x1 << 5;
static const uint32_t MULTISHOT_CATEGORY    = 0x1 << 6;


static NSString * const kALTopScoreKey = @"TopScore";


static inline CGVector radiansToVector(CGFloat radians) {
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}


static inline float randomInRange(CGFloat low, CGFloat high) {
    CGFloat value = arc4random_uniform (UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}


-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    // Gravity.
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    self.physicsWorld.contactDelegate = self;
    
    // Background.
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.size = self.frame.size;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    // Edges
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    leftEdge.position = CGPointMake(0.0, 0.0);
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    
    // Main Layer
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    // Cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [self addChild:_cannon];
    
    // Cannon Rotation Action
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    // Halo Spawn Action
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                               [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
    
    // Shield Power Up Spawn Action
    SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:15 withRange:4],
                                                        [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
    
    // Multi Shot Power Up Spawn Action
    SKAction *spawnMultiShotPowerUp = [SKAction sequence:@[[SKAction waitForDuration:35 withRange:10],
                                                           [SKAction performSelector:@selector(spawnMultiShotPowerUp) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnMultiShotPowerUp]];
    
    // Ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                   [SKAction runBlock:^{
        if (!_multiMode) {
            self.ammo++;
        }
    }]]];
    
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    // Shield Pool OK
    _shieldPool = [[NSMutableArray alloc] init];
    
    // Shields
    if (self.frame.size.width == 320) {
        for (int i = 0; i < 6; i++) {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(36 + (50 * i), 90);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
            shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
            shield.physicsBody.collisionBitMask = 0;
            [_shieldPool addObject:shield];                             //Shields are in array not set as a node yet.
        }
    }
    else if (self.frame.size.width == 375) {
        for (int i = 0; i < 7; i++) {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(38 + (50 * i), 90);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
            shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
            shield.physicsBody.collisionBitMask = 0;
            [_shieldPool addObject:shield];                             //Shields are in array not set as a node yet.
        }
    }
    else if (self.frame.size.width == 414) {
        for (int i = 0; i < 8; i++) {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(37 + (49 * i), 90);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
            shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
            shield.physicsBody.collisionBitMask = 0;
            [_shieldPool addObject:shield];                             //Shields are in array not set as a node yet.
        }
    }
    
    // Pause Button
    _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
    _pauseButton.position = CGPointMake(self.size.width - 30, 18);
    [self addChild:_pauseButton];
    
    // Resume Button
    _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
    _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    [self addChild:_resumeButton];
    
    // Score Display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    // Points Multiplier Label
    _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _pointLabel.position = CGPointMake(15, 30);
    _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _pointLabel.fontSize = 15;
    [self addChild:_pointLabel];
    
    // Sound Files
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _lazerSound = [SKAction playSoundFileNamed:@"Lazer.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
    
    // Menu
    _menu = [[GameMenu alloc] init];
    _menu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
    [self addChild:_menu];
    
    // Initial values
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    _resumeButton.hidden = YES;
    [_menu show];
    
    // Top Score.
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _menu.topScore = [_userDefaults integerForKey:kALTopScoreKey];
    
    // Music
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (!_audioPlayer) {
        NSLog(@"Error loading media player: %@", error);
    }
    else {
        _audioPlayer.numberOfLoops = -1;
        _audioPlayer.volume = 0.09;
        [_audioPlayer play];
        _menu.musicPlaying = YES;
    }
}



-(void)newGame {
    
    [_mainLayer removeAllChildren];
    
    while (_shieldPool.count > 0) {
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        [_shieldPool removeObjectAtIndex:0];
    }
    
    // Life Bar
    if (self.frame.size.width == 320) {
        SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
        lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
        lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
        lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
        [_mainLayer addChild:lifeBar];
    }
    else if (self.frame.size.width == 375) {
        SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
        lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
        lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
        lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
        [_mainLayer addChild:lifeBar];
    }
    else if (self.frame.size.width == 414) {
        SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
        lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
        lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
        lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
        [_mainLayer addChild:lifeBar];
    }
    
    // Initial Values
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    self.multiMode = NO;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    _pauseButton.hidden = NO;
    [_menu hide];
    _gameOver = NO;
}


// Ammo Limit - Setter Override
-(void)setAmmo:(int)ammo {
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}


// Current Score - Setter Override
-(void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}


// Points Multiplier - Setter Override
-(void)setPointValue:(int)pointValue {
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Multi: x%d", pointValue];
}


// MultiMode - Setter Override
-(void)setMultiMode:(BOOL)multiMode {
    _multiMode = multiMode;
    if (multiMode) {
        _cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    }
    else {
        _cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
}


// Pause - Setter Override
-(void)setGamePaused:(BOOL)gamePaused {
    if (!_gameOver) {
        _gamePaused = gamePaused;
        _pauseButton.hidden = gamePaused;
        _resumeButton.hidden = !gamePaused;
        self.paused = gamePaused;
    }
}


// Shoot Action
-(void)shoot {
    
    // Create BALL.
    Ball *ball = [Ball spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    ball.physicsBody.restitution = 1.0;         //Bouncey-ness after interaction with other nodes (1.0 max).
    ball.physicsBody.linearDamping = 0.0;       //Air friction, slowing of the node (1.0 max).
    ball.physicsBody.friction = 0.0;            //Loss of angle in bounce due to friction (1.0 max).
    ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    ball.physicsBody.collisionBitMask = EDGE_CATEGORY;
    ball.physicsBody.contactTestBitMask = EDGE_CATEGORY | SHIELDUP_CATEGORY | MULTISHOT_CATEGORY;
    [self runAction:_lazerSound];
    [_mainLayer addChild:ball];
    
    // Create BALL TRAIL.
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.targetNode = _mainLayer;          // Particles will now stay in the co-ordinate of _mainLayer instead of the Ball.
    [_mainLayer addChild:ballTrail];
    ball.trail = ballTrail;
    [ball updateTrail];
    
}


// Spawn Halo
-(void)spawnHalo {
    
    // Create HALO Node.
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5) - 15),
                                self.size.height + (halo.size.height));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16];
    CGVector direction = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    halo.physicsBody.collisionBitMask = EDGE_CATEGORY;
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | LIFEBAR_CATEGORY | EDGE_CATEGORY;
    
    // Halo Counter. OK
    int haloCount = 0;
    for (SKNode *node in _mainLayer.children) {
        if ([node.name isEqualToString:@"halo"]) {
            haloCount++;
        }
    }
    if (haloCount >= 4 && arc4random_uniform(3) == 1) {
        //  Create HaloBomb. OK
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Bomb"];
    }
    else if (!_gameOver && arc4random_uniform(6) == 0) {
        // Create HaloX.
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    [_mainLayer addChild:halo];
    
    // Increase Spawn Speed with each spawn.
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if (spawnHaloAction.speed < 1.60) {
        spawnHaloAction.speed += 0.01;
    }
}


// Spawn Shield Power Up OK
-(void)spawnShieldPowerUp {
    if (_shieldPool.count > 0) {
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(200, self.size.height - 150));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldUp.physicsBody.categoryBitMask = SHIELDUP_CATEGORY;
        shieldUp.physicsBody.collisionBitMask = 0;
        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0;
        shieldUp.physicsBody.angularDamping = 0;
        [_mainLayer addChild:shieldUp];
    }
}


// Spawn Multi Shot Power Up
-(void)spawnMultiShotPowerUp {
    SKSpriteNode *multiShot = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiShot.name = @"multiShot";
    multiShot.position = CGPointMake(-multiShot.size.width, randomInRange(200, self.size.height - 150));
    multiShot.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12];
    multiShot.physicsBody.categoryBitMask = MULTISHOT_CATEGORY;
    multiShot.physicsBody.collisionBitMask = 0;
    multiShot.physicsBody.velocity = CGVectorMake(100, randomInRange(40, -40));
    multiShot.physicsBody.angularVelocity = M_PI;
    multiShot.physicsBody.linearDamping = 0;
    multiShot.physicsBody.angularDamping = 0;
    [_mainLayer addChild:multiShot];
}


// Did Begin Contacts
-(void)didBeginContact:(SKPhysicsContact *)contact {
    
    // Define FIRST and SECOND Bodies.
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // HALO CONTACTS
    
    // Collisions between HALO and BALL.
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY) {
        
        self.score += self.pointValue;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        // Add HaloX Identifier.
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {      //Using userData property to store data in node.
            self.pointValue++;
        }
        
        // Add HaloBomb Identifier. OK
        else if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            firstBody.node.name = nil;                                              //Avoids multiple explosions of halos.
            [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                self.score += self.pointValue;
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        
        firstBody.categoryBitMask = 0;                                              //Avoids multiple explosions of halos with ball.
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    // Collisions between HALO and SHIELD. (The problem is that Halo Bombs in iP6 & iP6+ are being picked up as normal halos...)
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY) {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self addExplosion:secondBody.node.position withName:@"BlockExplosion"];
        [self runAction:_explosionSound];
        
        // Add HaloBomb Identifier. OK
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            firstBody.categoryBitMask = 0;          //Avoids multiple explosions of halo and shields.
            [firstBody.node removeFromParent];
            [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addExplosion:node.position withName:@"BlockExplosion"];
                [_shieldPool addObject:node];               //Replacing shield to Shield Pool. Testing. OK.
                [node removeFromParent];
            }];
            NSLog(@"SHIELDS IN POOL - BOMB ON SHIELD = %lu",(unsigned long)_shieldPool.count);
        }
        
        else {
            firstBody.categoryBitMask = 0;          //Avoids multiple explosions of halo and shields.
            [firstBody.node removeFromParent];
            [_shieldPool addObject:secondBody.node];        //Replacing shield to Shield Pool. OK
            [secondBody.node removeFromParent];
            NSLog(@"SHIELDS IN POOL - HALO ON SHIELD = %lu",(unsigned long)_shieldPool.count);
        }
        
        self.pointValue = 1;
    }
    
    // Collisions between HALO and LIFEBAR.
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == LIFEBAR_CATEGORY) {
        [self addExplosion:secondBody.node.position withName:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    
    // Collisions between HALO and EDGE.
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        [self runAction:_zapSound];
    }
    
    // BALL CONTACTS
    
    // Collisions between BALL and EDGE.
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        [self addExplosion:contact.contactPoint withName:@"BounceExplosion"];
        [self runAction:_bounceSound];
        // Count Number of Bounces.
        if ([firstBody.node isKindOfClass:[Ball class]]) {
            ((Ball *)firstBody.node).numberOfBounces++;
            if (((Ball *)firstBody.node).numberOfBounces > 3) {
                [firstBody.node removeFromParent];
            }
        }
    }
    
    // Collisions between BALL and SHIELD UP. OK
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == SHIELDUP_CATEGORY) {
        if (_shieldPool.count > 0) {
            int randomIndex  = arc4random_uniform((int)_shieldPool.count);      //Random shield of however many is in there.
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
            NSLog(@"SHIELDS IN POOL - BALL ON SHIELD UP %lu",(unsigned long)_shieldPool.count);
            [self runAction:_shieldUpSound];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    // Collisions between BALL and MULTI SHOT
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == MULTISHOT_CATEGORY) {
        self.multiMode = YES;
        [self runAction:_shieldUpSound];
        self.ammo = 5;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}


// Game Over Actions
-(void)gameOver {
    
    // Find all HALO, BALL and SHIELD Nodes.
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"BlockExplosion"];
        [_shieldPool addObject:node];       //Replacing shield to Shield Pool. OK
        [node removeFromParent];
        NSLog(@"SHIELDS IN POOL - GAMEOVER = %lu",(unsigned long)_shieldPool.count);
    }];
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
        NSLog(@"HALOS REMOVED");
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
        NSLog(@"BALL REMOVED");
    }];
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];        //OK
        NSLog(@"SHIELD POWER-UP REMOVED");
    }];
    [_mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
        NSLog(@"MULTI SHOT POWER-UP REMOVED");
    }];
    
    // Current Score and Saving Top Score.
    _menu.score = self.score;
    if (self.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:kALTopScoreKey];
        [_userDefaults synchronize];
    }
    
    // Game Over Values.
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    self.multiMode = NO;
    self.ammo = 5;
    [self runAction:[SKAction waitForDuration:1] completion:^{
        [_menu show];
    }];
}


// Explosion Actions
-(void)addExplosion:(CGPoint)position withName:(NSString *)name {
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.0],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}


// Touches Began
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if (!_gameOver && !self.gamePaused) {
            if (![_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                _didShoot = YES;
            }
        }
    }
}


// Touches Ended
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (_gameOver && _menu.touchable) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([n.name isEqualToString:@"Play"]) {
                [self newGame];
                   NSLog(@"WIDTH = %f", self.frame.size.width);
            }
            if ([n.name isEqualToString:@"Music"]) {
                _menu.musicPlaying = !_menu.musicPlaying;
                if (_menu.musicPlaying) {
                    [_audioPlayer play];
                }
                else {
                    [_audioPlayer stop];
                }
            }
        }
        else if (!_gameOver) {
            if (self.gamePaused) {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]]) {
                    if (!_menu.musicPlaying) {
                        self.gamePaused = NO;
                    }
                    else {
                        self.gamePaused = NO;
                        [_audioPlayer play];
                    }
                }
            }
            else {
                if ([_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                    self.gamePaused = YES;
                    [_audioPlayer pause];
                }
            }
        }
    }
}


// Did Simulate Physics
-(void)didSimulatePhysics {
    
    if (_didShoot) {
        if (self.ammo > 0) {
            self.ammo --;
            
            [self shoot];
            
            if (_multiMode) {
                for (int i = 1; i < 5; i++) {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                if (self.ammo == 0) {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        _didShoot = NO;
    }
    
    // Remove Balls outside of frame.
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0];
        }
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
    
    // Remove Halos below bottom of frame.
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
    
    // Remove Shield Power Ups left of frame. OK
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
    
    // Remove Multi Shot Power Ups right of frame
    [_mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x - node.frame.size.height > self.size.width) {
            [node removeFromParent];
        }
    }];
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (_gamePaused) {
        self.paused = YES; }
    if (!_gamePaused) {
        self.paused = NO;
    }
}



@end
