//
//  JoinGameViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatchmakingClient.h"

@class JoinGameViewController;

@protocol JoinGameViewControllerDelegate <NSObject>

- (void)joinViewController:(JoinGameViewController *)controller didDisconnectWithReason:(QuitReason)reason;
- (void)joinViewControllerDidCancel:(JoinGameViewController *)controller;
- (void)joinViewController:(JoinGameViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;

@end

@interface JoinGameViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MatchmakingClientDelegate>

@property (nonatomic, weak) id <JoinGameViewControllerDelegate> delegate;
@property (nonatomic, strong) UIAlertView* spinningAlert;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

-(GKSession*)getSession;

@end
