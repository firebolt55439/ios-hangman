//
//  HostGameViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatchmakingClient.h"
#import "MatchmakingServer.h"
#import "GameScreenViewController.h"

#define MAX_CLIENTS 5

@class HostGameViewController;

@protocol HostGameViewControllerDelegate <NSObject>

- (void)hostViewControllerDidCancel:(HostGameViewController *)controller;
- (void)hostViewController:(HostGameViewController *)controller didEndSessionWithReason:(QuitReason)reason;

@end

@interface HostGameViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MatchmakingServerDelegate, GameScreenViewControllerDelegate>

@property (nonatomic, weak) id <HostGameViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;

-(void)setMode:(GameMode)mode;

@end
