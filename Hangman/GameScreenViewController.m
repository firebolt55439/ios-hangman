//
//  GameScreenViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 12/1/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "GameScreenViewController.h"
#import "LetterSelectionViewController.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#include <algorithm>
#include <functional>
#include <map>
#include <vector>

@interface GameScreenViewController ()
{
    NSMutableArray* pickerData;
    NSMutableArray* numberPickerData;
    BOOL _isHost;
}

@end

@implementation GameScreenViewController

@synthesize hangingManImg = _hangingManImg;
@synthesize wordImage = _wordImage;
@synthesize letterPicker = _letterPicker;
@synthesize mode = _mode;
@synthesize incorrect = _incorrect;
@synthesize guessed = _guessed;
@synthesize collectionView = _collectionView;
@synthesize levelLbl = _levelLbl;
@synthesize scoreLbl = _scoreLbl;
@synthesize modeLbl = _modeLbl;
@synthesize wordlist = _wordlist;
@synthesize guessProgressBar = _guessProgressBar;
@synthesize guessLbl = _guessLbl;
@synthesize gameHasStarted = _gameHasStarted;
@synthesize spinningAlert = _spinningAlert;

#pragma mark - View Helper Functions

- (void)dismissView {
    [self performSegueWithIdentifier:@"exitGameSegue" sender:nil];
}

- (UIAlertController*)getAlertFor:(BOOL)won {
    UIAlertController* alert;
    if(!won){
        NSString* wordMessage = [NSString stringWithFormat:@"The word was: %s.", _word.c_str()];
        alert = [UIAlertController alertControllerWithTitle:@"Nice try!" message:wordMessage preferredStyle:UIAlertControllerStyleAlert];
        NSString* currentWord = [NSString stringWithFormat:@"%s", _word.c_str()];
        if([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:currentWord]){
            __weak __typeof(self) weakSelf = self;
            UIAlertAction* definition = [UIAlertAction actionWithTitle:@"What?" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UIReferenceLibraryViewController* ref = [[UIReferenceLibraryViewController alloc] initWithTerm:currentWord];
                [weakSelf presentViewController:ref animated:YES completion:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf resetForNewWord];
                    });
                }];
            }];
            if(!(_mode & FLAG_MULTI_PLAYER)){
                [alert addAction:definition];
            }
        }
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Congratulations!" message:@"You correctly guessed the word." preferredStyle:UIAlertControllerStyleAlert];
    }
    return alert;
}

- (UIAlertView*)getSpinningViewWithTitle:(NSString*)title andMessage:(NSString*)message {
    UIAlertView* spinningAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
    UIView* viewBack = [[UIView alloc] initWithFrame:CGRectMake(83, 0, 100, 60)];
    UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(50, 10, 37, 37)];
    loadingIndicator.center = viewBack.center;
    loadingIndicator.hidesWhenStopped = true;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [loadingIndicator startAnimating];
    [viewBack addSubview:loadingIndicator];
    viewBack.center = self.view.center;
    [spinningAlert setValue:viewBack forKey:@"accessoryView"];
    [loadingIndicator startAnimating];
    return spinningAlert;
}

#pragma mark - UI Element Setup & Update Functions

- (void)setUpLabels {
    [self updateLabels];
}

- (void)updateLabels {
    // Updates following labels:
    // 1. Level
    // 2. Score
    // 3. Mode
    // 4. Progress (bar)
    // (more to come)
    NSString* level = [NSString stringWithFormat:@"Level: %u/%d", [self level], NUM_LEVELS];
    NSString* score = [NSString stringWithFormat:@"Score: %d", [self score]];
    NSString* mode = @"(unknown)";
    bool multiplayer = [self mode]  & FLAG_MULTI_PLAYER;
    /*
     MODE_COMPUTER_PICKS_WORD = 2, // computer picks word, user(s) guess
     MODE_USER_PICKS_WORD = 4, // user picks word, other users guess (multiplayer-only)
     MODE_COMPUTER_GUESSES_WORD
     */
    // TODO: Say whether computer/user(s) guess(es)?
    if(!multiplayer){
        mode = @"Single Player";
    } else {
        mode = @"Multiplayer";
    }
    [_levelLbl setText:level];
    [_scoreLbl setText:score];
    [_modeLbl setText:mode];
    [_guessProgressBar setProgress:(float)_incorrect.size()/(float)GUESS_LIMIT];
    [_guessLbl setFont:[UIFont fontWithName:@"ActionMan" size:16.0f]];
    [_guessLbl setText:[NSString stringWithFormat:@"%lu/%d", _incorrect.size(), GUESS_LIMIT]];
}

- (void)setUpStageImage:(unsigned long)stage {
    // Generate the noose image.
    assert(stage <= 7UL);
    UIImage* nooseImg = [UIImage imageNamed:@"Noose"];
    CGSize newSize = _hangingManImg.bounds.size;
    UIGraphicsBeginImageContext(newSize);
    int nooseDiv = 1;
    while(201 / nooseDiv > (newSize.width * 0.76f)) ++nooseDiv;
    [nooseImg drawInRect:CGRectMake(0, 0, 201 / nooseDiv, 226 / nooseDiv)];
    
    // Generate the hanging man image.
    UIImage* stageImg = nil;
    if(stage == 0){ // stage 0 is no image
        stageImg = nil;
    } else {
        --stage; // otherwise, proceed as normal
        CGImageRef ref = CGImageCreateWithImageInRect([UIImage imageNamed:@"Stages"].CGImage, CGRectMake(stage * 75, 0, 75, 200));
        stageImg = [UIImage imageWithCGImage:ref];
    }
    int stageDiv = 1;
    while(75 / stageDiv > (newSize.width - newSize.width / 3)) ++stageDiv;
    [stageImg drawInRect:CGRectMake(newSize.width / 3, 0, 75 / stageDiv, 200 / stageDiv)];
    UIImage* blendedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Set the image appropriately.
    [_hangingManImg setImage:blendedImg];
}

- (void)updateStageImage {
    [self setUpStageImage:_incorrect.size()];
}

- (void)updateWordImage {
    [self setUpWordImage];
}

- (void)setUpWordImage {
    // Create the context.
    if(_word.length() == 0UL) return;
    const float WIDTH = _wordImage.frame.size.width;
    const float HEIGHT = _wordImage.frame.size.height;
    CGRect bounds = CGRectMake(0.0, 0.0, WIDTH, HEIGHT);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(WIDTH, HEIGHT), NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    
    // Set the bounds and fill with all white as a background color.
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0 alpha:0].CGColor);
    CGContextFillRect(context, bounds);
    
    // Decide on the path to draw text.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, bounds );
    
    // Generate the CF-compatible string reference.
    NSString* blanked = [[NSString alloc] initWithCString:[self getBlankedWord].c_str()];
    CFStringRef textString = (__bridge CFStringRef) blanked;
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), textString);
    
    // Figure out the appropriate size.
    double size = 48.0f * 2;
    CTFontRef font;
    CTFramesetterRef framesetter;
    while(true)
    {
        size -= 0.5f;
        static NSString* fontName = @"DKCoolCrayon"/*@"ActionMan"*/;
        font = CTFontCreateWithName((CFStringRef)fontName, size, nil);
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, blanked.length), kCTFontAttributeName, font);
        framesetter = CTFramesetterCreateWithAttributedString(attrString);
        CFRange range;
        CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, blanked.length), nil, CGSize{WIDTH, HEIGHT}, &range);
        if(range.length == blanked.length) break;
    }
    
    
    // Generate the frame.
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CFRelease(attrString);
    
    // Draw the specified frame in the given context.
    CTFrameDraw(frame, context);
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    [_wordImage setImage:[UIImage imageWithCGImage:CGBitmapContextCreateImage(context)]];
    CGContextRelease(context);
}

- (void)updateLetterPicker {
    // Updates the selection of letters available in the letter picker.
    @synchronized(pickerData) {
        [pickerData removeAllObjects];
        for(unsigned short c = 'A'; c <= 'Z'; c++)
        {
            if(std::find(_guessed.begin(), _guessed.end(), tolower(c)) == _guessed.end())
            {
                [pickerData addObject:[NSString stringWithCharacters:&c length:1]];
            }
        }
        [_letterPicker reloadAllComponents];
    }
}

- (void)setUpLetterPicker __attribute__((deprecated)) {
    // Fill in data.
    for(unsigned short c = 'A'; c <= 'Z'; c++)
    {
        [pickerData addObject:[NSString stringWithCharacters:&c length:1]];
    }
    
    // Connect picker.
    self.letterPicker.dataSource = self;
    self.letterPicker.delegate = self;
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 26;
}

- (void)updateCellAtIndexPath:(NSIndexPath*)indexPath orCell:(UICollectionViewCell*)cell {
    if(cell == nil)
        cell = [_collectionView cellForItemAtIndexPath:indexPath];
    cell.userInteractionEnabled = NO;
    const CGFloat DISABLED_ALPHA = 0.439216f;
    UIColor* DISABLED_COLOR = [UIColor colorWithRed:143.0f green:143.0f blue:143.0f alpha:DISABLED_ALPHA];
    [cell.contentView subviews][0].alpha = DISABLED_ALPHA;
    [[cell.contentView subviews][0] setBackgroundColor:DISABLED_COLOR];
    cell.backgroundColor = DISABLED_COLOR;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    char guess = char(indexPath.row + 'a');
    [self handleGuess:guess];
    [self updateCellAtIndexPath:indexPath orCell:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AlphabetCellID";
    NSString* letter = [NSString stringWithFormat:@"%c", (char)(indexPath.row + 'A')];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.userInteractionEnabled = YES;
    for(UIView* subview in [cell.contentView subviews]){
        [subview removeFromSuperview];
    }
    cell.backgroundColor = [UIColor colorWithRed:0.0f green:0.6f blue:0.1f alpha:0.5f];
    [cell.layer setCornerRadius:7.0f];
    [cell.layer setMasksToBounds:YES];
    [cell.layer setBorderWidth:2.0f];
    UITextView* textView = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
    textView.userInteractionEnabled = NO;
    textView.backgroundColor = cell.backgroundColor;
    textView.frame = cell.bounds;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [textView setText:letter];
    [textView setTextAlignment:NSTextAlignmentCenter];
    [textView setFont:[UIFont fontWithName:@"DK Cool Crayon" size:17.0f]];
    [cell.contentView addSubview:textView];
    textView.frame = cell.contentView.bounds;
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    const int SIDE_LENGTH = 28;
    return CGSize{SIDE_LENGTH, SIDE_LENGTH};
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsets{
        .top =  0.0,
        .left =  0.0,
        .bottom =  0.0,
        .right =  0.0
    };
}

#pragma mark - UIPickerViewDelegate

// The number of columns of data.
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data.
- (long)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [numberPickerData count];
}

// The data to return for the row and component (column) that's being passed in.
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[numberPickerData objectAtIndex:row] stringByAppendingString:@" letters"];
}

// Initialize picker data.
- (void)setUpLengthPicker {
    static const int LENGTH_MAX = 99;
    numberPickerData = [[NSMutableArray alloc] initWithCapacity:30];
    bool isLengthSet[LENGTH_MAX + 1];
    for(int i = 0; i <= LENGTH_MAX; i++){
        isLengthSet[i] = false;
    }
    auto& words = _wordlist->getSortedWords();
    for(auto& word : words){
        isLengthSet[word.length()] = true;
    }
    for(int i = 0; i <= LENGTH_MAX; i++){
        if(isLengthSet[i]){
            [numberPickerData addObject:[NSString stringWithFormat:@"%d", i]];
        }
    }
}

#pragma mark - Game Helper Functions

// Returns an uppercase hangman-compatible "blanked word", complete with spaces/underscores and all.
- (std::string)getBlankedWord {
    std::string ret = "";
    for(int i = 0; i < _word.length(); i++)
    {
        char on = _word[i];
        if(!(_mode & MODE_COMPUTER_GUESSES_WORD)){
            if(std::find(_guessed.begin(), _guessed.end(), on) != _guessed.end()){
                ret.push_back(toupper(on));
            } else {
                ret.push_back('_');
            }
        } else ret.push_back(on);
        if((i + 1) < _word.length()) ret.push_back(' ');
    }
    NSLog(@"Blanked: |%s|", ret.c_str());
    return ret;
}

- (void)setWord:(std::string)word {
    _word = word;
}

- (void)setKnownWordLength:(NSUInteger)length {
    _wordLength = (unsigned int)length;
    NSLog(@"Length: %u chars", _wordLength);
    _word = std::string((size_t)_wordLength, '_');
    NSLog(@"Cur: %s", _word.c_str());
}

- (int)computeScoreChangeForLevel:(unsigned int) level result:(bool)won {
    // Formula used:
    // w(x) = 1 if won, else -1
    // score(level) = w(x)*(level)^(3/2)
    // or: score(level) = -NUM_LEVELS*(1/level)^(3/2)
    double lvl = (double)level;
    if(!won) return (int)((-2)*NUM_LEVELS*sqrt(1.0/(lvl*lvl))); // if lost, compute score difference based on level alone
    double incorrect_scaled = _incorrect.size() / 13.0f; // scaling factor = 1/13
    return round(powf(level * level * level, 1.0f/(2.0f + incorrect_scaled))); // level ^ (3/(2 + incorrect_guess_num_scaled))
}

- (WLSettings)getWordListSettings {
    WLSettings ret;
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    double vowel_k = [userDefaults floatForKey:@"vowel_k"];
    double length_k = [userDefaults floatForKey:@"length_k"];
    if(vowel_k >= 0.01f) ret.vowel_k = vowel_k;
    if(length_k >= 0.01f) ret.length_k = length_k;
    return ret;
}

#pragma mark - Mode Set-Up Functions

- (void)setUpSinglePlayer {
    if(_mode == MODE_COMPUTER_PICKS_WORD || _mode == MODE_COMPUTER_GUESSES_WORD){
        // Set up the labels.
        [self setUpLabels];
        
        // Set up the stage image.
        [self setUpStageImage:_incorrect.size()];
        
        // Set up the letter picker.
        [self setUpLetterPicker];
        
        // Set up the word image.
        [self setUpWordImage];
    }
}

- (void)setUpMultiPlayer {
    int theMode = _mode & ~FLAG_MULTI_PLAYER;
    if(theMode == MODE_COMPUTER_PICKS_WORD | theMode == MODE_USER_PICKS_WORD){
        // Set up the labels.
        [self setUpLabels];
        
        // Set up the stage image.
        [self setUpStageImage:_incorrect.size()];
        
        // Set up the letter picker.
        [self setUpLetterPicker];
        
        // Set up the word image.
        [self setUpWordImage];
        
        // Check if the game has started yet.
        _session.available = NO;
        _session.delegate = self;
        [_session setDataReceiveHandler:self withContext:nil];
        if(!_gameHasStarted){
            // If not, wait on it.
            _isHost = NO;
            _spinningAlert = [self getSpinningViewWithTitle:@"Waiting" andMessage:@"Waiting for host to start game..."];
            [_spinningAlert show];
        } else {
            // Otherwise, broadcast it to connected clients.
            _isHost = YES;
            [self sendPacketToAllClients:[GamePacket generatePacket:PacketTypeGameStarting withArguments:nil]];
        }
    }
}

- (void)resetForNewWord {
    // Reset interface in preparation for a new word.
    if(!(_mode & FLAG_MULTI_PLAYER)){
        // Reset guesses.
        _incorrect.clear();
        _guessed.clear();
        
        // Reset keyboard.
        [_collectionView reloadData];
        
        // Pick new word, if applicable.
        if(_mode == MODE_COMPUTER_PICKS_WORD){
            _word = _wordlist->getWordAtLevel(_level);
        } else if(_mode == MODE_COMPUTER_GUESSES_WORD){
            __weak __typeof(self) weakSelf = self;
            __block NSString *messageTitle, *messagePlaceholder;
            messageTitle = @"How long is your word?";
            messagePlaceholder = @"Your Word's Length";
            dispatch_async(dispatch_get_main_queue(), ^{
                __block UITextField* wordTextField;
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:messageTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"Text: %@", [wordTextField text]);
                    if([wordTextField.text length] == 0){
                        return;
                    }
                    // TODO: Check if chosen word in dictionary and display appropriate error prompts
                    // TODO: Validate text field for only numbers if necessary
                    [weakSelf setKnownWordLength:[wordTextField.text integerValue]];
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf updateWordImage];
                        [weakSelf guessNextLetter];
                    });
                }];
                [alert addAction:ok];
                [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    // Configure and initialize the text field.
                    wordTextField = textField;
                    textField.placeholder = messagePlaceholder;
                    
                    // Create a UIPickerView.
                    [weakSelf setUpLengthPicker];
                    UIPickerView* pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
                    pickerView.delegate = weakSelf;
                    pickerView.dataSource = weakSelf;
                    
                    // Create a toolbar with a done button.
                    [weakSelf setAlertTextField:textField];
                    [weakSelf setAlertPickerView:pickerView];
                    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
                    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:weakSelf action:@selector(inputAccessoryViewDidFinish:)];
                    [toolbar setItems:[NSArray arrayWithObject: doneButton] animated:NO];
                    
                    // Initialize the input and accessory views of the text field.
                    textField.inputView = pickerView;
                    textField.inputAccessoryView = toolbar;
                }];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            });
        }
        
        // Reset images.
        [self setUpWordImage];
        [self setUpStageImage:0UL];
        [self setUpLabels];
    } else {
        // Reset guesses.
        _incorrect.clear();
        _guessed.clear();
        
        // Reset keyboard.
        [_collectionView reloadData];
        
        // Pick a new word, if applicable.
        if(_mode & MODE_COMPUTER_PICKS_WORD){
            if(_isHost){
                _word = _wordlist->getWordAtLevel(_level);
            } else {
                _word = "";
            }
        } else if(_mode & MODE_USER_PICKS_WORD){
            _word = "";
            __weak __typeof(self) weakSelf = self;
            if(_isHost){
                __block UITextField* wordTextField;
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter your next word" message:nil preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"Text: %@", [wordTextField text]);
                    // TODO: Check if chosen word in dictionary and display appropriate error prompts
                    [weakSelf setWord:std::string([wordTextField.text UTF8String])];
                    [weakSelf sendPacketToAllClients:[GamePacket generatePacket:PacketTypeComputerWord withArguments:[NSString stringWithUTF8String:[weakSelf word].c_str()]]];
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf updateWordImage];
                    });
                }];
                [alert addAction:ok];
                [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    wordTextField = textField;
                    textField.placeholder = @"Your Word";
                }];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            } else {
                _word = "";
            }
        }
        
        // Reset images.
        [self setUpWordImage];
        [self setUpStageImage:0UL];
        [self setUpLabels];
    }
}

#pragma mark - Multiplayer Helper Functions

- (void)sendPacketToAllClients:(NSString *)packet {
    GKSendDataMode dataMode = GKSendDataReliable;
    NSData *data = [packet dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    if (![_session sendDataToAllPeers:data withDataMode:dataMode error:&error])
    {
        NSLog(@"Error sending data to clients: %@", error);
    }
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
#ifdef DEBUG
    NSLog(@"Game: peer %@ changed state %d", peerID, state);
#endif
    switch(state){
        case GKPeerStateDisconnected:
            if(_spinningAlert != nil){
                [_spinningAlert dismissWithClickedButtonIndex:0U animated:YES];
                _spinningAlert = nil; // no memory leaks, please
            }
            [self dismissViewControllerAnimated:NO completion:nil];
            [ViewController showDisconnectedAlert];
            break;
        default:
            break;
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
#ifdef DEBUG
    NSLog(@"Game: connection request from peer %@", peerID);
#endif
    
    // We are in the middle of a game - deny any connection requests.
    [session denyConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"Game: connection with peer %@ failed %@", peerID, error);
#endif
    // Not used.
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"Game: session failed %@", error);
#endif
}

#pragma mark - GKSession Data Receive Handler

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
#ifdef DEBUG
    NSLog(@"Game: receive data from peer: %@, data: %@, length: %d", peerID, data, (int)[data length]);
#endif
    NSUInteger len = [data length];
    const char* dat = (const char*)[data bytes];
    std::string str(dat, len);
    if(str.length() < 6) return;
    if(str.substr(0, 4) != "HANG"){
        NSLog(@"Malformed packet.");
        return;
    }
    PacketType type = (PacketType)[[NSString stringWithUTF8String:str.substr(4,6).c_str()] intValue];
    NSLog(@"Packet type: %d", (int)type);
    
    if(type == PacketTypeGameStarting){
        _gameHasStarted = YES;
    } else if(type == PacketTypeComputerWord){
        if(_spinningAlert != nil){
            [_spinningAlert dismissWithClickedButtonIndex:0U animated:YES];
            _spinningAlert = nil; // no memory leaks, please
        }
        _word = str.substr(6, str.length() - 1);
        NSLog(@"Received word: %s", _word.c_str());
        [self updateWordImage];
        [self updateLabels];
    } else if(type == PacketTypeUserGuess){
        char guess = str[6];
        NSLog(@"Received guess: %c", guess);
        if(std::find(_guessed.begin(), _guessed.end(), guess) != _guessed.end()){
            // We already guessed this letter (meaning that it may have been re-broadcasted
            // or some out-of-sync client sent it, so we ignore it.
            return;
        }
        [self handleGuess:guess];
        [self updateWordImage];
        [self updateLabels];
        for(UICollectionViewCell* cell in _collectionView.visibleCells){
            char at = tolower([((UITextView*)cell.contentView.subviews[0]).text characterAtIndex:0]);
            if(at == guess){
                [self updateCellAtIndexPath:0 orCell:cell];
                break;
            }
        }
        if(_isHost){
            // If we are the host, broadcast this guess to all connected devices.
            [self sendPacketToAllClients:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        }
    } else if(type == PacketTypeWordOver){
        // If we are the client, wait for the server's WordOver packet, reset the game, and
        // send a ResetAck packet acknowledging that we have reset the game.
        if(!_isHost){
            __weak __typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf resetForNewWord];
                [weakSelf sendPacketToAllClients:[GamePacket generatePacket:PacketTypeResetAck withArguments:nil]];
            });
        }
    } else if(type == PacketTypeResetAck){
        // If we are the server, wait for all the clients to reset their packets before starting the game
        // by sending a NextRound packet.
        NSLog(@"Received %lu/%lu ACK(s)", (_syncedClientCount + 1), (unsigned long)[_connectedClients count]);
        if(_isHost && _syncedClientCount < [_connectedClients count]){
            ++_syncedClientCount;
            if(_syncedClientCount >= [_connectedClients count]){
                if(_word.length() > 0){ // in case the user is still deciding on the word
                    [self sendPacketToAllClients:[GamePacket generatePacket:PacketTypeComputerWord withArguments:[NSString stringWithUTF8String:_word.c_str()]]];
                }
                [_spinningAlert dismissWithClickedButtonIndex:0U animated:YES];
                _spinningAlert = nil; // no memory leaks, please
            }
        }
    }
}

#pragma mark - Evil Mode Methods

inline bool isVowel(char ch){
    ch = (std::islower(ch) ? ch : std::tolower(ch));
    return (ch == 'a') || (ch == 'e') || (ch == 'i') || (ch == 'o') || (ch == 'u');
}

// This method will, upon a "successful" guess, evilly alter the word using
// its all-encompassing knowledge to another word that satisfies the constraints
// but for which the guess is false.
// In other words, it thinks of a new word that makes your guess false, and
// will probably succeed 90%+ of the time.
-(std::string)replacementWordFor:(char)eschewedLetter withStringLength:(NSUInteger)length {
    // Generate the subset of the word list that matches the constraints. //
    bool guessedLetter[26]; // [letter #] --> [guessed or not]
    std::map<char, bool> guessValidity; // guess validity for computer guessing the word
    for(char c = 'a'; c <= 'z'; c++){
        int ind = (int)(c - 'a');
        if(std::find(_guessed.begin(), _guessed.end(), c) != _guessed.end()){
            guessedLetter[ind] = true;
            guessValidity[c] = (std::find(_incorrect.begin(), _incorrect.end(), c) == _incorrect.end());
        } else {
            guessedLetter[ind] = false;
        }
    }
    auto& words = _wordlist->getSortedWords();
    NSString* origBlanked = [NSString stringWithUTF8String:[self getBlankedWord].c_str()];
    NSString* blankedTrimmed = [origBlanked stringByReplacingOccurrencesOfString:@" " withString:@""];
    std::string orig([blankedTrimmed cStringUsingEncoding:NSUTF8StringEncoding]);
    NSLog(@"Original string: |%s|", orig.c_str());
    std::vector<std::reference_wrapper<std::string> > wordSubset;
    for(std::string& word : words){
        if(word.length() != length) continue; // the words are not the same length
        bool works = true;
        for(unsigned int i = 0; works && i < word.length(); i++){
            char on = word[i];
            int ind = (int)(on - 'a');
            if(on == eschewedLetter) works = false; // we want the user's guess to be false
            if(orig[i] != '_' && orig[i] != on) works = false; // the words thus far don't match up
            if(guessedLetter[ind]){ // if we have already guessed this letter
                if(!guessValidity[on]) works = false; // we guessed this letter and it was not there
                if(guessValidity[on] && orig[i] == '_') works = false; // we guessed this letter, and it was in the word but not here
            }
        }
        if(!works) continue;
        wordSubset.push_back(word);
    }
    
    // Return the hardest word in the subset.
    NSLog(@"Word subset size: %lu", wordSubset.size());
    if(wordSubset.size() == 0) return "";
    double minScore = -1.0f;
    std::string minWord = "";
    for(std::string& word : wordSubset){
        // Calculate the score.
        double score = _wordlist->getScoreFor(word);
        
        // And handle the final score.
        if(score > minScore){
            minScore = score;
            minWord = word;
        }
    }
    return minWord;
}

#pragma mark - Guessing Algorithm Methods

-(char)nextLetterToGuess {
    /*
     * Guessing Algorithm:
     * 1. Generate a subset of the wordlist that matches the recorded constraints.
     *	- e.g. Must not contain any letters of incorrect guesses, the "blanked word"
     *	       must match, etc.
     * 2. Find the probability of each letter that appears in each blank.
     *	- e.g. "a_b_c" with two words "axby" and "axbc", the probability for blank #1
     *		   of "x" is 100%, and for blank #2, the probability is 50-50 b/w "y" and "c".
     * 3. Find the letter that has the highest probability for any blank and guess it.
     *	- e.g. In above example, we would guess "x" with a probability of 100% of being
     *		   on the blank, versus taking a 50-50 chance with "y" or "c".
     */
    // Generate the subset of the word list. //
    bool guessedLetter[26]; // [letter #] --> [guessed or not]
    std::map<char, bool> guessValidity; // guess validity for computer guessing the word
    for(char c = 'a'; c <= 'z'; c++){
        int ind = (int)(c - 'a');
        if(std::find(_guessed.begin(), _guessed.end(), c) != _guessed.end()){
            guessedLetter[ind] = true;
            guessValidity[c] = (std::find(_incorrect.begin(), _incorrect.end(), c) == _incorrect.end());
        } else {
            guessedLetter[ind] = false;
        }
    }
    auto& words = _wordlist->getSortedWords();
    auto orig = _word;
    NSLog(@"Original string: |%s|", orig.c_str());
    std::vector<std::reference_wrapper<std::string> > wordSubset;
    for(std::string& word : words){
        if(word.length() != _wordLength) continue; // the words are not the same length
        bool works = true;
        for(unsigned int i = 0; works && i < word.length(); i++){
            char on = word[i];
            int ind = (int)(on - 'a');
            if(orig[i] != '_' && orig[i] != on) works = false; // the words thus far don't match up
            if(guessedLetter[ind]){ // if we have already guessed this letter
                if(!guessValidity[on]) works = false; // we guessed this letter and it was not there
                if(guessValidity[on] && orig[i] == '_') works = false; // we guessed this letter, and it was in the word but not here
            }
        }
        if(!works) continue;
        wordSubset.push_back(word);
    }
    
    // Count the occurences of each letter in each blank using the subset of possible words. //
    NSLog(@"Subset size: %lu", wordSubset.size());
    std::map<unsigned int, std::map<char, unsigned long long> > blank_counts;
    for(std::string& word : wordSubset){
        for(unsigned int i = 0; i < word.length(); i++){
            if(orig[i] == '_'){
                char on = word[i];
                auto& map = blank_counts[i];
                if(map.find(on) == map.end()){
                    map[on] = 1ULL;
                } else {
                    ++map[on];
                }
            }
        }
    }
    
    // Compute the probability, by blank, of each letter appearing in the blank. //
    std::map<unsigned int, std::map<char, double> > probabilities;
    for(auto& pair : blank_counts){
        unsigned long long total = 0;
        for(auto& on : std::get<1>(pair)){
            total += std::get<1>(on);
        }
        //std::cerr << "Blank #" << std::get<0>(pair) << ":\n";
        for(auto& on : std::get<1>(pair)){
            double prob = 100.0f * (double)std::get<1>(on) / (double)total;
            probabilities[std::get<0>(pair)][std::get<0>(on)] = prob;
            //std::cerr << "\t" << std::get<0>(on) << ": " << prob << "%" << std::endl;
        }
    }
    
    // Find the letter that has the highest probability for any blank and guess it.
    char guessingLetter = '\0';
    double maxProb = 0.0f;
    for(auto& pair: probabilities){
        for(auto& on : std::get<1>(pair)){
            double prob = std::get<1>(on);
            if(prob > maxProb){
                maxProb = prob;
                guessingLetter = std::get<0>(on);
            }
        }
    }
    assert(std::find(_guessed.begin(), _guessed.end(), guessingLetter) == _guessed.end());
    if(guessingLetter == '\0'){
        NSLog(@"Warning: No letter to guess - no word matching constraints exists.");
    }
    return guessingLetter;
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // Here so that other views can unwind back to this one.
    NSLog(@"Game Screen - prepareForUnwind: called");
    if(_mode == MODE_COMPUTER_GUESSES_WORD){ // non-multiplayer, computer guesses
        // Save new word.
        // TODO
        
        // Update necessary UI elements.
        [self updateWordImage];
        [self updateLabels];
        [self updateStageImage];
        
        // Guess the next letter.
        [self guessNextLetter];
    }
}

-(void)guessNextLetter {
    // No two threads should be able to access this method at the same time.
    if(_isGuessMethodRunning) return;
    _isGuessMethodRunning = YES;
    
    // Check if game is over.
    bool gameOver = false, gameResult = false; // gameResult = true if computer won, false if user won
    NSString *message, *messageTitle;
    if(_incorrect.size() >= GUESS_LIMIT){
        // User wins.
        gameOver = true;
        gameResult = false; // user wins
        messageTitle = @"Congratulations!";
        message = @"You win!";
    } else if(_word.find('_') == std::string::npos){
        // Computer wins.
        gameOver = true;
        gameResult = true; // computer wins
        messageTitle = @"Nice Try!";
        message = @"Computer wins!";
    }
    
    // Figure out what to guess next if game is not already over.
    __block char guess;
    __weak __typeof(self) weakSelf = self;
    if(!gameOver){
        guess = [self nextLetterToGuess];
        if(guess != '\0'){
            message = [NSString stringWithFormat:@"Is the letter %c in your word?", guess];
            _lastComputerGuess = guess;
        } else {
            gameOver = true;
            messageTitle = @"Nice Try!";
            message = @"No such word exists in the dictionary - computer wins.";
            gameResult = true; // computer wins
        }
    }
    
    // Inform user if game is over.
    if(gameOver){
        // Compute new score.
        int scoreDiff = [self computeScoreChangeForLevel:_level result:gameResult];
        _score += scoreDiff;
        
        // Compute new level.
        if(gameResult){
            _level = std::min(_level + 1, (unsigned int)NUM_LEVELS);
        } else {
            _level = std::max(1U, _level - 1);
        }
        
        // Apprise user of result.
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:messageTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf resetForNewWord];
        }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // Display guess to user.
        __block auto& guessedRef = _guessed;
        __block auto& incorrectRef = _incorrect;
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Computer Guess" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            guessedRef.push_back(guess);
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update cell image.
                for(UICollectionViewCell* cell in _collectionView.visibleCells){
                    char at = tolower([((UITextView*)cell.contentView.subviews[0]).text characterAtIndex:0]);
                    if(at == guess){
                        [weakSelf updateCellAtIndexPath:0 orCell:cell];
                        break;
                    }
                }
                
                // Transition over to the letter selection view.
                [weakSelf performSegueWithIdentifier:@"letterSelectionSegue" sender:weakSelf];
            });
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction* no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            guessedRef.push_back(guess);
            incorrectRef.push_back(guess);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateWordImage];
                [weakSelf updateLabels];
                [weakSelf updateStageImage];
                for(UICollectionViewCell* cell in _collectionView.visibleCells){
                    char at = tolower([((UITextView*)cell.contentView.subviews[0]).text characterAtIndex:0]);
                    if(at == guess){
                        [weakSelf updateCellAtIndexPath:0 orCell:cell];
                        break;
                    }
                }
                [weakSelf guessNextLetter];
            });
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:yes];
        [alert addAction:no];
        [self presentViewController:alert animated:YES completion:nil];
    }
    _isGuessMethodRunning = NO;
}

#pragma mark - View Setup Functions

- (void)inputAccessoryViewDidFinish:(id) sender {
    // Called when the 'done' button in the toolbar is pressed for the word-length selection.
    NSUInteger row = [self.alertPickerView selectedRowInComponent:0];
    NSString* chosenLength = [numberPickerData objectAtIndex:row];
    [self.alertTextField resignFirstResponder];
    [self.alertTextField setText:chosenLength];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"Game - viewDidAppear");
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if([weakSelf wordlist] != NULL){
            WLSettings settings = [weakSelf getWordListSettings];
            while([weakSelf isWordlistUsed]) usleep(500000);
            [weakSelf wordlist]->scoreWords(settings);
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Hide the collection view backgroumd.
    [_collectionView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0]];
    
    // Set according to chosen mode.
    _mode = [_delegate currentGameMode]/*MODE_COMPUTER_PICKS_WORD*/;
    _isGuessMethodRunning = NO;
    NSLog(@"Mode: %d", _mode);
    
    // Initialize necessary variables.
    pickerData = [[NSMutableArray alloc] initWithCapacity:26];
    _level = 1U; // from [1, NUM_LEVELS]
    _score = 0;
    
    // Initialize the wordlist in the background. //
    // Display a spinning alert.
    UIAlertView* spinningAlert = [self getSpinningViewWithTitle:@"Loading" andMessage:@"Please wait..."];
    [spinningAlert show];
    
    // Dispatch background task.
    __weak __typeof(self) weakSelf = self;
    unsigned int currentLevel = _level;
    _isHost = (_connectedClients != nil);
    _isWordlistUsed = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [weakSelf setIsWordlistUsed:YES];
        [weakSelf setWordlist:new Wordlist()];
        NSString* wordlistPath = [[NSBundle mainBundle] pathForResource:@"wordlist" ofType:@"txt"];
        std::string wordlistStr([wordlistPath UTF8String]);
        if(![weakSelf wordlist]->readWordlist(wordlistStr)){
            NSLog(@"Could not read wordlist!");
            assert(false);
        }
        [weakSelf wordlist]->scoreWords([self getWordListSettings]);
        [weakSelf setIsWordlistUsed:NO];
        
        // If either:
        //  1. We are in multiplayer mode and the game has started
        //  (OR)
        //  2. We are in single-player computer-picks-word mode.
        if((([weakSelf mode] & FLAG_MULTI_PLAYER) && ([weakSelf mode] & MODE_COMPUTER_PICKS_WORD) && [weakSelf gameHasStarted]) || (!([weakSelf mode] & FLAG_MULTI_PLAYER) && [weakSelf mode] == MODE_COMPUTER_PICKS_WORD)){
            // Then come up with a word, and save it.
            std::string usingWord = [weakSelf wordlist]->getWordAtLevel(currentLevel);
            [weakSelf setWord:usingWord];
            
            // And if we are in multiplayer mode and are the host, broadcast it.
            if([weakSelf mode] & FLAG_MULTI_PLAYER){
                [weakSelf sendPacketToAllClients:[GamePacket generatePacket:PacketTypeComputerWord withArguments:[NSString stringWithUTF8String:[weakSelf word].c_str()]]];
            }
        } else if((([weakSelf mode] & FLAG_MULTI_PLAYER) && ([weakSelf mode] & MODE_USER_PICKS_WORD) && _isHost) || (!([weakSelf mode] & FLAG_MULTI_PLAYER) && [weakSelf mode] == MODE_COMPUTER_GUESSES_WORD)){
            __block NSString *messageTitle, *messagePlaceholder;
            __block BOOL computerIsGuessing = ([weakSelf mode] == MODE_COMPUTER_GUESSES_WORD);
            if(computerIsGuessing){
                messageTitle = @"How long is your word?";
                messagePlaceholder = @"Your Word's Length";
            } else {
                messageTitle = @"Enter your word";
                messagePlaceholder = @"Your Word";
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                __block UITextField* wordTextField;
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:messageTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"Text: %@", [wordTextField text]);
                    if([wordTextField.text length] == 0){
                        return;
                    }
                    // TODO: Check if chosen word in dictionary and display appropriate error prompts
                    // TODO: Validate text field for only numbers if necessary
                    if(!computerIsGuessing){
                        [weakSelf setWord:std::string([wordTextField.text UTF8String])];
                        [weakSelf sendPacketToAllClients:[GamePacket generatePacket:PacketTypeComputerWord withArguments:[NSString stringWithUTF8String:[weakSelf word].c_str()]]];
                    } else {
                        [weakSelf setKnownWordLength:[wordTextField.text integerValue]];
                    }
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf updateWordImage];
                        if(computerIsGuessing){
                            [weakSelf guessNextLetter];
                        }
                    });
                }];
                [alert addAction:ok];
                [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    // Configure and initialize the text field.
                    wordTextField = textField;
                    textField.placeholder = messagePlaceholder;
                    
                    if(computerIsGuessing){
                        // Create a UIPickerView.
                        [weakSelf setUpLengthPicker];
                        UIPickerView* pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
                        pickerView.delegate = weakSelf;
                        pickerView.dataSource = weakSelf;
                        
                        // Create a toolbar with a done button.
                        [weakSelf setAlertTextField:textField];
                        [weakSelf setAlertPickerView:pickerView];
                        UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
                        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:weakSelf action:@selector(inputAccessoryViewDidFinish:)];
                        [toolbar setItems:[NSArray arrayWithObject: doneButton] animated:NO];
                        
                        // Initialize the input and accessory views of the text field.
                        textField.inputView = pickerView;
                        textField.inputAccessoryView = toolbar;
                    }
                }];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            });
        }
        
        // And finally, dismiss the spinning loading alert and update the word image.
        dispatch_async(dispatch_get_main_queue(), ^{
            [spinningAlert dismissWithClickedButtonIndex:0 animated:NO];
            [weakSelf updateWordImage];
        });
    });
    
    // Call the setup method for the specific mode.
    if(!(_mode & FLAG_MULTI_PLAYER)){
        NSLog(@"Setting up single player...");
        [self setUpSinglePlayer];
    } else {
        NSLog(@"Setting up multi player...");
        [self setUpMultiPlayer];
    }
}

- (void)dealloc {
    delete _wordlist;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation); // only portrait supported
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Game Action Handlers

- (void)handleGuess:(char)guess {
    // Handle guess by mode.
    if(_mode & MODE_COMPUTER_GUESSES_WORD) return;
    bool shouldCheckExit = false; // whether to check if the game is over or not
    guess = tolower(guess);
    
    // Verify the guess.
    if(std::find(_guessed.begin(), _guessed.end(), guess) != _guessed.end()){
        //NSLog(@"Warning: A letter was re-guessed.");
        return;
    }
    
    // Check if the guess was correct.
    bool correct = false;
    for(int i = 0; i < _word.length(); i++)
    {
        if(_word[i] == guess){
            correct = true;
            break;
        }
    }
    
    // If we are in "evil mode" and the guess was "correct", perform any evil word transpositions here. //
    // Note: Evil mode is currently not available in multiplayer, and it can be toggled from the game
    // preferences view.
    const bool EVIL_MODE = !(_mode & FLAG_MULTI_PLAYER) && [[NSUserDefaults standardUserDefaults] boolForKey:@"evilmode"];
    if(EVIL_MODE && correct && (_mode & MODE_COMPUTER_PICKS_WORD)){
        std::string newWord = [self replacementWordFor:guess withStringLength:_word.length()];
        if(newWord.length() > 0){
            NSLog(@"New evil word: %s", newWord.c_str());
            correct = false;
            _word = newWord;
            
            // Show an alien popping in and out of the screen to show that we evilly changed the word.
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage* img = [UIImage imageNamed:@"AlienOrb"];
                UIImageView* imgView = [[UIImageView alloc] initWithImage:img];
                imgView.center = self.view.center;
                imgView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                [self.view addSubview:imgView];
                const double duration = 0.4f;
                [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    imgView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        imgView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                    } completion:^(BOOL finished) {
                        [imgView removeFromSuperview];
                    }];
                }];
            });
        }
    }
    
    // Save the guess as well as its veracity.
    _guessed.push_back(guess);
    if(!correct) _incorrect.push_back(guess);
    
    // Handle modes now.
    if(!(_mode & FLAG_MULTI_PLAYER)){
        assert(_mode == MODE_COMPUTER_PICKS_WORD); // it is the only single-player mode in which the user has to guess
        shouldCheckExit = true;
    } else {
        shouldCheckExit = true;
        unsigned short shortGuess = (unsigned short)guess;
        [self sendPacketToAllClients:[GamePacket generatePacket:PacketTypeUserGuess withArguments:[NSString stringWithCharacters:(unsigned short*)&shortGuess length:1]]];
    }
    
    // Check if the game is over, if requested.
    bool gameOver = false;
    bool gameResult = false; // won/lost
    UIAlertController* alert;
    NSString* alertOkText;
    if(shouldCheckExit)
    {
        if(_incorrect.size() >= GUESS_LIMIT){
            // Game over.
            gameOver = true;
            gameResult = false;
            NSLog(@"Word over - lost.");
            alert = [self getAlertFor:NO];
            alertOkText = @"OK";
        } else if([self getBlankedWord].find('_') == std::string::npos){
            gameOver = true;
            gameResult = true;
            NSLog(@"Word over - won.");
            alert = [self getAlertFor:YES];
            alertOkText = @"OK";
        }
    }
    
    // Update all necessary items.
    [self updateLabels];
    [self updateWordImage];
    [self updateStageImage];
    if(gameOver){
        // Compute new score.
        int scoreDiff = [self computeScoreChangeForLevel:_level result:gameResult];
        _score += scoreDiff;
        
        // Compute new level.
        if(gameResult){
            _level = std::min(_level + 1, (unsigned int)NUM_LEVELS);
        } else {
            _level = std::max(1U, _level - 1);
        }
        
        // Display result.
        __weak __typeof(self) weakSelf = self;
        if(!(_mode & FLAG_MULTI_PLAYER)){
            UIAlertAction* ok = [UIAlertAction actionWithTitle:alertOkText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf resetForNewWord];
                });
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            // Clear any guesses.
            _guessed.clear();
            _incorrect.clear();
            
            // Dismiss any spinning alert.
            if(_spinningAlert != nil){
                [_spinningAlert dismissWithClickedButtonIndex:0U animated:YES];
                _spinningAlert = nil;
            }
            
            // Display game result alert.
            UIAlertAction* ok = [UIAlertAction actionWithTitle:alertOkText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf dismissAlertController:alert];
                });
            }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
            [self performSelector:@selector(dismissAlertController:) withObject:alert afterDelay:2];
        }
    }
}

- (void)dismissAlertController:(UIAlertController*)alert {
    if(_spinningAlert != nil) return;
    NSLog(@"dismissAlertController: called");
    [alert dismissViewControllerAnimated:YES completion:nil];
    alert = nil;
    _spinningAlert = [self getSpinningViewWithTitle:@"Synchronizing" andMessage:@"Waiting for other players..."];
    [_spinningAlert show];
    __weak __typeof(self) weakSelf = self;
    if(_isHost) {
        // If we are the host, dispatch a WordOver packet, reset the game, and wait for *ALL* the
        // connected clients to acknowledge that they have reset their respective games.
        self.syncedClientCount = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf resetForNewWord];
            [weakSelf sendPacketToAllClients:[GamePacket generatePacket:PacketTypeWordOver withArguments:nil]];
        });
    } else {
        // If we are the client, wait for the server's WordOver packet, reset the game, and
        // send a ResetAck packet acknowledging that we have reset the game.
        // Note: This is handled in the data receive method.
    }
}

- (IBAction)exitButtonPressed:(id)sender {
    __weak __typeof(self) weakSelf = self;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"All data will be lost." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if(weakSelf.session != nil){
            [weakSelf.session disconnectFromAllPeers];
            weakSelf.session.available = NO;
            weakSelf.session.delegate = nil;
            weakSelf.session = nil;
        }
        [weakSelf dismissView];
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - LetterSelectionViewControllerDelegate

- (void)letterSelectionDidChooseWord:(NSString*)word {
    NSLog(@"Modified word: %@", word);
    __weak __typeof(self) weakSelf = self;
    self.word = std::string([word cStringUsingEncoding:NSUTF8StringEncoding]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateWordImage];
        [weakSelf updateLabels];
        [weakSelf updateStageImage];
        [weakSelf guessNextLetter];
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"Segue id: %@", [segue identifier]);
    if([segue.identifier isEqualToString:@"letterSelectionSegue"]){
        LetterSelectionViewController* view = (LetterSelectionViewController*)segue.destinationViewController;
        view.delegate = self;
        view.baseWord = [NSString stringWithFormat:@"%s", _word.c_str()];
        view.letterChoosing = _lastComputerGuess;
    }
}

@end
