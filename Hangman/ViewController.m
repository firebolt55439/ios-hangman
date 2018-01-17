//
//  ViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "ViewController.h"
#import "GameScreenViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    BOOL _performAnimations;
    GKSession* _session;
}

@synthesize hangmanLogo;
@synthesize joinBtn;
@synthesize hostBtn;
@synthesize singlePlayerBtn;
@synthesize gameMode = _gameMode;

// TODO: exit animation

-(void)awakeFromNib {
    _performAnimations = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation); // only portrait supported
}

- (void)prepareForIntroAnimation
{
    hangmanLogo.hidden = YES;
    singlePlayerBtn.hidden = hostBtn.hidden = joinBtn.hidden = YES;
    singlePlayerBtn.alpha = hostBtn.alpha = joinBtn.alpha = 0.0f;
}

- (void) rotateHangmanLogo:(int) num
{
    [UIView animateWithDuration: 0.25f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [hangmanLogo setTransform:CGAffineTransformRotate(hangmanLogo.transform, M_PI_2)]; // rotate 90 degrees clockwise
        hangmanLogo.alpha = hangmanLogo.alpha + 0.25f;
    } completion:^(BOOL finished){
        if (num < 4){
            [self rotateHangmanLogo:num + 1];
        }
    }];
}

- (void)performIntroAnimation
{
    const int NUM_BUTTONS = 3;
    const float STARTING_DELAY = 0.5f;
    const float BUTTON_STEP = 0.25f;
    hangmanLogo.hidden = NO;
    singlePlayerBtn.hidden = hostBtn.hidden = joinBtn.hidden = NO;
    hangmanLogo.alpha = 0.0f;
    [self rotateHangmanLogo:1];
    id buttons[] = { hostBtn, joinBtn, singlePlayerBtn };
    int button_c = 0;
    for(float delay = STARTING_DELAY; delay <= (STARTING_DELAY + (NUM_BUTTONS - 1) * BUTTON_STEP); delay += BUTTON_STEP, ++button_c){
        int ind = button_c;
        UIButton* on = (UIButton*)buttons[ind];
        [UIView animateWithDuration:1.0f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
            on.alpha = 1.0f;
        } completion:^(BOOL finished){
            // TODO
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Animation: %d", (int)_performAnimations);
    [super viewWillAppear:animated];
    
    if(_performAnimations){
        [self prepareForIntroAnimation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(_performAnimations){
        [self performIntroAnimation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // [blank]
}

- (void)startGameWithBlock:(void (^)())block
{
    [self performSegueWithIdentifier:@"generalGameSegue" sender:self];
}

+ (void)showDisconnectedAlert {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Disconnected", @"Client disconnected alert title")
                              message:NSLocalizedString(@"You were disconnected from the game.", @"Client disconnected alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
    [alertView show];
}

+ (void)showNoNetworkAlert {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"No Network", @"No network alert title")
                              message:NSLocalizedString(@"To use multiplayer, please enable Bluetooth or Wi-Fi in your device's Settings.", @"No network alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
    [alertView show];
}

- (void)setMode:(GameMode)mode {
    _gameMode = mode;
}

- (GameMode)currentGameMode {
    return _gameMode;
}

- (IBAction)singlePlayerPressed:(id)sender {
    __weak __typeof(self) weakSelf = self;
    UIAlertController* view = [UIAlertController alertControllerWithTitle:@"Mode" message:@"Select your mode." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* computerPicks = [UIAlertAction actionWithTitle:@"Computer picks word" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setMode:MODE_COMPUTER_PICKS_WORD];
            [weakSelf performSegueWithIdentifier:@"singlePlayerSegue" sender:sender];
        });
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction* userPicks = [UIAlertAction actionWithTitle:@"Computer guesses word" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setMode:MODE_COMPUTER_GUESSES_WORD];
            [weakSelf performSegueWithIdentifier:@"singlePlayerSegue" sender:sender];
        });
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
    [view addAction:computerPicks];
    [view addAction:userPicks];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    // TODO: Record whether single player, double player, etc. and handle delegates properly
    if([segue.identifier isEqualToString:@"singlePlayerSegue"]){ // single-player
        ((GameScreenViewController*)segue.destinationViewController).delegate = self;
    } else if([segue.identifier isEqualToString:@"generalGameSegue"]){ // multi-player (only for joining a game though)
        ((GameScreenViewController*)segue.destinationViewController).delegate = self;
        ((GameScreenViewController*)segue.destinationViewController).gameHasStarted = NO;
        ((GameScreenViewController*)segue.destinationViewController).session = _session;
        _gameMode = (GameMode)(FLAG_MULTI_PLAYER | MODE_COMPUTER_PICKS_WORD);
    }
    if([segue.destinationViewController isKindOfClass:[HostGameViewController class]]){
        _gameMode = FLAG_MULTI_PLAYER;
        ((HostGameViewController*)segue.destinationViewController).delegate = self;
    }
    if([segue.destinationViewController isKindOfClass:[JoinGameViewController class]]){
        _gameMode = FLAG_MULTI_PLAYER;
        ((JoinGameViewController*)segue.destinationViewController).delegate = self;
    }
}

#pragma mark - HostGameViewControllerDelegate

- (void)hostViewControllerDidCancel:(HostGameViewController *)controller
{
    //[self dismissViewControllerAnimated:NO completion:nil];
    // Allow it its own animation.
    _performAnimations = NO;
}

- (void)hostViewController:(HostGameViewController *)controller didEndSessionWithReason:(QuitReason)reason {
    if (reason == QuitReasonNoNetwork)
    {
        [ViewController showNoNetworkAlert];
    }
}

#pragma mark - JoinGameViewControllerDelegate

- (void)joinViewControllerDidCancel:(JoinGameViewController *)controller
{
    //[self dismissViewControllerAnimated:NO completion:nil];
    // We allow each class to do its own view controller dismissal.
    _performAnimations = NO;
}

- (void)joinViewController:(JoinGameViewController *)controller didDisconnectWithReason:(QuitReason)reason
{
    if (reason == QuitReasonNoNetwork)
    {
        [ViewController showNoNetworkAlert];
    }
    else if (reason == QuitReasonConnectionDropped)
    {
        [self dismissViewControllerAnimated:NO completion:^
         {
             [ViewController showDisconnectedAlert];
         }];
    }
}

- (void)joinViewController:(JoinGameViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    _session = [controller getSession];
    _performAnimations = NO;
    
    [self dismissViewControllerAnimated:NO completion:^
     {
         _performAnimations = YES;
         
         [self startGameWithBlock:^
          {
              // TODO: Finish
              //[game startClientGameWithSession:session playerName:name server:peerID];
          }];
     }];
}

@end
