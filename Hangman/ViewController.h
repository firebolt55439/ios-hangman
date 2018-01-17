//
//  ViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatchmakingClient.h"
#import "HostGameViewController.h"
#import "JoinGameViewController.h"
#import "GameScreenViewController.h"

@interface ViewController : UIViewController <HostGameViewControllerDelegate, JoinGameViewControllerDelegate, GameScreenViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *hangmanLogo;
@property (weak, nonatomic) IBOutlet UIButton *hostBtn;
@property (weak, nonatomic) IBOutlet UIButton *joinBtn;
@property (weak, nonatomic) IBOutlet UIButton *singlePlayerBtn;
@property (nonatomic) GameMode gameMode;

+ (void)showDisconnectedAlert;
+ (void)showNoNetworkAlert;
- (void)setMode:(GameMode)mode;

@end

