//
//  GamePreferencesViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 12/14/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GamePreferencesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *evilModeSwitch;
@property (weak, nonatomic) IBOutlet UISlider *lengthSlider;
@property (weak, nonatomic) IBOutlet UISlider *vowelSlider;

@end
