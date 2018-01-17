//
//  JoinGameViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "JoinGameViewController.h"
#import "MatchmakingClient.h"

@interface JoinGameViewController ()

@end

@implementation JoinGameViewController
{
    MatchmakingClient *_matchmakingClient; // the matchmaking client
    QuitReason _quitReason; // the reason for a connection being dropped
}

@synthesize delegate = _delegate;
@synthesize nameTextField = _nameTextField;
@synthesize tableView = _tableView;

-(GKSession*)getSession {
    return [_matchmakingClient session];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // Here so that other views can unwind back to this one.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_matchmakingClient == nil)
    {
        _quitReason = QuitReasonConnectionDropped;
        
        _matchmakingClient = [[MatchmakingClient alloc] init];
        _matchmakingClient.delegate = self;
        [_matchmakingClient startSearchingForServers];
        
        self.nameTextField.placeholder = _matchmakingClient.session.displayName;
        [self.tableView reloadData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation); // only portrait supported
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Allow text field cancellation by tapping somewhere else. //
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:_nameTextField action:@selector(resignFirstResponder)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Called when exited.
- (IBAction)exitAction:(id)sender {
    _quitReason = QuitReasonUserQuit;
    [_matchmakingClient disconnectFromServer];
    [self.delegate joinViewControllerDidCancel:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"Segue id: %@", [segue identifier]);
    if([segue.identifier isEqualToString:@"exitJoinSegue"]){
        [self exitAction:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"Table view # called.");
    if (_matchmakingClient != nil){
        return [_matchmakingClient availableServerCount];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"JoinCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
    cell.textLabel.text = [_matchmakingClient displayNameForPeerID:peerID];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_matchmakingClient != nil)
    {
        self.spinningAlert = [[UIAlertView alloc] initWithTitle:@"Connecting" message:@"Attempting to connect..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        UIView* viewBack = [[UIView alloc] initWithFrame:CGRectMake(83, 0, 100, 60)];
        UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(50, 10, 37, 37)];
        loadingIndicator.center = viewBack.center;
        loadingIndicator.hidesWhenStopped = true;
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [loadingIndicator startAnimating];
        [viewBack addSubview:loadingIndicator];
        viewBack.center = self.view.center;
        [self.spinningAlert setValue:viewBack forKey:@"accessoryView"];
        [loadingIndicator startAnimating];
        [self.spinningAlert show];
        
        NSString *peerID = [_matchmakingClient peerIDForAvailableServerAtIndex:indexPath.row];
        [_matchmakingClient connectToServerWithPeerID:peerID];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - MatchmakingClientDelegate

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameAvailable:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameUnavailable:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client didConnectToServer:(NSString*)peerID {
    if(self.spinningAlert != nil){
        [self.spinningAlert dismissWithClickedButtonIndex:0U animated:YES];
        self.spinningAlert = nil;
    }
    NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([name length] == 0)
        name = _matchmakingClient.session.displayName;
    
    [self.delegate joinViewController:self startGameWithSession:_matchmakingClient.session playerName:name server:peerID];
}

- (void)matchmakingClient:(MatchmakingClient *)client didDisconnectFromServer:(NSString *)peerID {
    _matchmakingClient.delegate = nil;
    _matchmakingClient = nil;
    [self.tableView reloadData];
    [self.delegate joinViewController:self didDisconnectWithReason:_quitReason];
}

- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client
{
    _quitReason = QuitReasonNoNetwork;
}

@end
