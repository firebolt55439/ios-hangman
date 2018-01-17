//
//  LetterSelectionViewController.h
//  Hangman
//
//  Created by Sumer Kohli on 12/12/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LetterSelectionViewController;

@protocol LetterSelectionViewControllerDelegate <NSObject>

- (void)letterSelectionDidChooseWord:(NSString*)word;

@end

@interface LetterSelectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) id <LetterSelectionViewControllerDelegate> delegate;
@property (retain, nonatomic) NSString* baseWord;
@property (nonatomic, assign) char letterChoosing;
@property (weak, nonatomic) IBOutlet UICollectionView *letterCollectionView;

@end
