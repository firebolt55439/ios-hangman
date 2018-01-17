//
//  GamePreferencesViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 12/14/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "GamePreferencesViewController.h"
#include "Wordlist.hpp"

@implementation GamePreferencesViewController

- (void)viewDidLoad {
    // Check the settings for evil mode, and adjust button as necessary.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    bool evilMode = [userDefaults boolForKey:@"evilmode"];
    [_evilModeSwitch setOn:evilMode animated:NO];
    
    // Check the settings for the length and vowel sliders, and adjust as necessary.
    const double length_min = 0.01f, length_max = 0.99f;
    const double vowel_min = 0.01f, vowel_max = 1.49f;
    double length_val = [userDefaults floatForKey:@"length_k"];
    double vowel_val = [userDefaults floatForKey:@"vowel_k"];
    [_lengthSlider setMinimumValue:length_min];
    [_lengthSlider setMaximumValue:length_max];
    [_vowelSlider setMinimumValue:vowel_min];
    [_vowelSlider setMaximumValue:vowel_max];
    WLSettings default_settings;
    if(length_val < 0.01f){
        length_val = default_settings.length_k;
    }
    if(vowel_val < 0.01f){
        vowel_val = default_settings.vowel_k;
    }
    [_vowelSlider setValue:vowel_val];
    [_lengthSlider setValue:length_val];
}

- (IBAction)resetButtonClicked:(id)sender {
    // Reset evil mode to off.
    [_evilModeSwitch setOn:NO animated:YES];
    [self evilSwitchToggled:nil];
    
    // Reset length and vowel sliders.
    WLSettings default_settings;
    [_vowelSlider setValue:default_settings.vowel_k animated:YES];
    [_lengthSlider setValue:default_settings.length_k animated:YES];
    [self lengthWeightageChanged:_lengthSlider];
    [self vowelWeightageChanged:_vowelSlider];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    //
}

- (IBAction)evilSwitchToggled:(id)sender {
    // Set the defaults as needed.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_evilModeSwitch.isOn forKey:@"evilmode"];
    [userDefaults synchronize];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"exitGamePreferencesSegue" sender:self];
}

- (IBAction)lengthWeightageChanged:(UISlider *)sender {
    // Set the defaults as needed.
    NSLog(@"New length weightage: %f", sender.value);
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:sender.value forKey:@"length_k"];
    [userDefaults synchronize];
}

- (IBAction)vowelWeightageChanged:(UISlider *)sender {
    // Set the defaults as needed.
    NSLog(@"New vowel weightage: %f", sender.value);
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:sender.value forKey:@"vowel_k"];
    [userDefaults synchronize];
}


@end
