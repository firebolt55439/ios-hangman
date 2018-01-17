//
//  GameScreenViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 12/4/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MatchmakingClient.h"
#import "GamePacket.h"
#include "Wordlist.hpp"
#import "LetterSelectionViewController.h"
#include <iostream>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>

enum GameMode : int {
    FLAG_MULTI_PLAYER = 1, // flag that is set if it is multiplayer
    MODE_COMPUTER_PICKS_WORD = 2, // computer picks word, user(s) guess
    MODE_USER_PICKS_WORD = 4, // user picks word, other users guess (multiplayer-only)
    MODE_COMPUTER_GUESSES_WORD = 8 // user picks word, computer guesses
};

@class GameScreenViewController;

@protocol GameScreenViewControllerDelegate <NSObject>

-(GameMode)currentGameMode;

@end

@interface GameScreenViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GKSessionDelegate, LetterSelectionViewControllerDelegate>

// Delegate.
@property (nonatomic, weak) id <GameScreenViewControllerDelegate> delegate;

// Game instance variables.
@property (atomic, assign) Wordlist* wordlist; // the wordlist for the game
@property (nonatomic) enum GameMode mode; // game mode
@property (nonatomic) unsigned int level; // current level
@property (nonatomic, assign, readwrite) std::string word; // chosen word
@property (nonatomic, assign, readwrite) unsigned int wordLength; // word length, if we do not know the word
@property (nonatomic) int score; // current score
@property (nonatomic) std::vector<char> incorrect; // incorrectly guessed letters
@property (nonatomic) std::vector<char> guessed; // guessed letters
@property (weak, nonatomic) GKSession* session; // game GKSession
@property (nonatomic) BOOL gameHasStarted; // whether the game has started yet or not (only applicable in multiplayer mode)
@property (nonatomic) NSUInteger syncedClientCount; // count of clients that have checked in
@property (strong, nonatomic) UIAlertView* spinningAlert; // the current "spinning alert", if any
@property (strong, atomic) NSArray* connectedClients; // applicable only if this is the host
@property (nonatomic) char lastComputerGuess; // last computer guess
@property (atomic, assign, readwrite) BOOL isWordlistUsed; // is wordlist being used
@property (atomic, assign, readwrite) BOOL isGuessMethodRunning; // if the method is currently being run

// Outlets in-use.
@property (weak, nonatomic) IBOutlet UIImageView *hangingManImg;
@property (weak, nonatomic) IBOutlet UIImageView *wordImage;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *levelLbl;
@property (weak, nonatomic) IBOutlet UILabel *scoreLbl;
@property (weak, nonatomic) IBOutlet UILabel *modeLbl;
@property (weak, nonatomic) IBOutlet UIProgressView *guessProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *guessLbl;
@property (retain, nonatomic) IBOutlet UITextField* alertTextField;
@property (retain, nonatomic) IBOutlet UIPickerView* alertPickerView;

// Deprecated:
@property (weak, nonatomic) IBOutlet UIPickerView *letterPicker;
@property (weak, nonatomic) IBOutlet UIButton *letterChooseBtn;

// Selectors.
- (void)setKnownWordLength:(NSUInteger)length;

@end
