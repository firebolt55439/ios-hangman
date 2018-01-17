//
//  HostGameViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "HostGameViewController.h"
#import "MatchmakingServer.h"

@interface HostGameViewController ()

@end

@implementation HostGameViewController
{
    MatchmakingServer *_matchmakingServer;
    QuitReason _quitReason;
    GameMode _gameMode;
}

@synthesize delegate;
@synthesize startBtn;
@synthesize nameTextField;

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // Here so that other views can unwind back to this one.
    NSLog(@"Host - prepareForUnwind: called");
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation); // only portrait supported
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Disable start button. //
    startBtn.enabled = NO; // don't have a quorum of players yet
    
    // Allow text field cancellation by tapping somewhere else. //
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:nameTextField action:@selector(resignFirstResponder)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_matchmakingServer == nil)
    {
        _matchmakingServer = [[MatchmakingServer alloc] init];
        _matchmakingServer.delegate = self;
        _matchmakingServer.maxClients = MAX_CLIENTS;
        [_matchmakingServer startAcceptingConnections];
        
        self.nameTextField.placeholder = _matchmakingServer.session.displayName;
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAction:(id)sender {
    _quitReason = QuitReasonUserQuit;
    [_matchmakingServer endSession];
    [self.delegate hostViewControllerDidCancel:self];
}

-(void)setMode:(GameMode)mode {
    _gameMode = mode;
}

- (IBAction)startButtonClicked:(id)sender {
    UIAlertController* view = [UIAlertController alertControllerWithTitle:@"Mode" message:@"Select your mode." preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof(self) weakSelf = self;
    UIAlertAction* computerPicks = [UIAlertAction actionWithTitle:@"Computer picks word" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setMode:(GameMode)(MODE_COMPUTER_PICKS_WORD | FLAG_MULTI_PLAYER)];
            [weakSelf performSegueWithIdentifier:@"hostToGameSegue" sender:sender];
        });
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction* userPicks = [UIAlertAction actionWithTitle:@"User picks word" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setMode:(GameMode)(MODE_USER_PICKS_WORD | FLAG_MULTI_PLAYER)];
            [weakSelf performSegueWithIdentifier:@"hostToGameSegue" sender:sender];
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
    //[self performSegueWithIdentifier:@"hostToGameSegue" sender:sender];
}

- (GameMode)currentGameMode {
    //return (GameMode)(FLAG_MULTI_PLAYER | MODE_COMPUTER_PICKS_WORD);
    return _gameMode;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"Segue id: %@", [segue identifier]);
    if([segue.identifier isEqualToString:@"exitHostSegue"]){
        [self exitAction:self];
    }
    if([segue.identifier isEqualToString:@"hostToGameSegue"]){
        GameScreenViewController* gm = (GameScreenViewController*)[segue destinationViewController];
        gm.delegate = self;
        gm.session = _matchmakingServer.session;
        gm.gameHasStarted = YES;
        gm.connectedClients = [_matchmakingServer connectedClients];
        [_matchmakingServer stopAcceptingConnections];
    }
}

#pragma mark - MatchmakingServerDelegate

- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID
{
    startBtn.enabled = YES;
    [self.tableView reloadData];
}

- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID
{
    [self.tableView reloadData];
    if([_matchmakingServer connectedClientCount] == 0){
        startBtn.enabled = NO;
    }
}

- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server
{
    _matchmakingServer.delegate = nil;
    _matchmakingServer = nil;
    [self.tableView reloadData];
    [self.delegate hostViewController:self didEndSessionWithReason:_quitReason];
}

- (void)matchmakingServerNoNetwork:(MatchmakingServer *)server
{
    _quitReason = QuitReasonNoNetwork;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_matchmakingServer != nil)
        return [_matchmakingServer connectedClientCount];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HostCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSString *peerID = [_matchmakingServer peerIDForConnectedClientAtIndex:indexPath.row];
    cell.textLabel.text = [_matchmakingServer displayNameForPeerID:peerID];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
