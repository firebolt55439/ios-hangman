//
//  LetterSelectionViewController.m
//  Hangman
//
//  Created by Sumer Kohli on 12/12/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "LetterSelectionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#include <string>
#include <algorithm>

@implementation LetterSelectionViewController {
    NSMutableArray* selectionData; // contains ['appl', '_'] for example
    NSMutableArray* selectionReadOnly; // whether the cell is read-only or not ([true, false] in above example)
    NSMutableArray* selectionDataChanged; // the "new" array that can be changed
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // Here so that other views can unwind back to this one.
    NSLog(@"Letter Selection - prepareForUnwind: called");
}

- (void)dismissView {
    [self performSegueWithIdentifier:@"exitLetterSelectionSegue" sender:self];
}

- (void)setUpSelectionData {
    // Merging done as follows:
    // 'apples' as 'appl__'
    // ['appl', '_', '_']
    std::string word((const char*)[_baseWord cStringUsingEncoding:NSUTF8StringEncoding]);
    std::string letterComb = "";
    for(unsigned int i = 0; i <= word.length(); i++){
        char on;
        if(i < word.length()) on = word[i];
        else on = '.';
        if(!isalpha(on) && letterComb.length() > 0){
            [selectionData addObject:[NSString stringWithFormat:@"%s", letterComb.c_str()]];
            [selectionReadOnly addObject:@"YES"];
            letterComb = "";
        }
        if(isalpha(on)){
            letterComb.push_back(on);
        } else if(on == '_'){
            [selectionData addObject:@"_"];
            [selectionReadOnly addObject:@"NO"];
        }
    }
    selectionDataChanged = [[NSMutableArray alloc] initWithArray:selectionData copyItems:YES];
}

- (void)viewDidLoad {
    // Set up collection view data.
    selectionData = [[NSMutableArray alloc] initWithCapacity:[_baseWord length]];
    selectionReadOnly = [[NSMutableArray alloc] initWithCapacity:[_baseWord length]];
    [self setUpSelectionData];
    
    // Set up collection view.
    _letterCollectionView.delegate = self;
    _letterCollectionView.dataSource = self;
}

- (NSString*)getModifiedWord {
    NSString* ret = @"";
    for(NSString* text in selectionDataChanged){
        ret = [ret stringByAppendingString:text];
    }
    NSLog(@"Generated modified word: %@", ret);
    return ret;
}

- (IBAction)doneButtonClicked:(id)sender {
    NSLog(@"Done button clicked.");
    [_delegate letterSelectionDidChooseWord:[self getModifiedWord]];
    NSLog(@"Dismissing letter selection view...");
    [self dismissView];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [selectionData count];
}

- (void)makeCellDisabled:(UICollectionViewCell*)cell {
    cell.userInteractionEnabled = NO;
    const CGFloat DISABLED_ALPHA = 0.439216f;
    UIColor* DISABLED_COLOR = [UIColor colorWithRed:143.0f green:143.0f blue:143.0f alpha:DISABLED_ALPHA];
    [cell.contentView subviews][0].alpha = DISABLED_ALPHA;
    [[cell.contentView subviews][0] setBackgroundColor:DISABLED_COLOR];
    cell.backgroundColor = DISABLED_COLOR;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [_letterCollectionView cellForItemAtIndexPath:indexPath];
    UITextView* textView = (UITextView*)[cell.contentView subviews][0];
    NSString* newValue;
    if([textView.text isEqualToString:@"_"]){
        newValue = [NSString stringWithFormat:@"%c", _letterChoosing];
    } else {
        newValue = [selectionData objectAtIndex:indexPath.row];
    }
    [textView setText:newValue];
    [selectionDataChanged replaceObjectAtIndex:indexPath.row withObject:newValue];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LetterSelectionCellID";
    NSString* content = [selectionData objectAtIndex:indexPath.row];
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
    [textView setText:content];
    [textView setTextAlignment:NSTextAlignmentCenter];
    [textView setFont:[UIFont fontWithName:@"DK Cool Crayon" size:34.0f]];
    [cell.contentView addSubview:textView];
    textView.frame = cell.contentView.bounds;
    if([[selectionReadOnly objectAtIndex:indexPath.row] isEqualToString:@"YES"]){
        [self makeCellDisabled:cell];
    }
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    const int SIDE_LENGTH = 28 * 2;
    return CGSize{static_cast<CGFloat>(SIDE_LENGTH * [[selectionData objectAtIndex:indexPath.row] length]), SIDE_LENGTH};
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsets{
        .top =  0.0,
        .left =  0.0,
        .bottom =  0.0,
        .right =  0.0
    };
}

@end
