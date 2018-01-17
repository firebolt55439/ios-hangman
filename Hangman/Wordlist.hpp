//
//  Wordlist.hpp
//  Hangman
//
//  Created by Sumer Kohli on 12/5/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#ifndef Wordlist_hpp
#define Wordlist_hpp

#import <UIKit/UIKit.h>
#include <cstdio>
#include <cmath>
#include <string>
#include <vector>
#include <map>

#define NUM_LEVELS 20
#define GUESS_LIMIT 7
#define MIN_LETTERS 5

// Constants //
static const std::string WORDLIST_PATH = "./wordlist.txt";
static std::map<std::string, double> LETTER_FREQUENCIES = {
    {"E", 12.02},
    {"T", 9.10},
    {"A", 8.12},
    {"O", 7.68},
    {"I", 7.31},
    {"N", 6.95},
    {"S", 6.28},
    {"R", 6.02},
    {"H", 5.92},
    {"D", 4.32},
    {"L", 3.98},
    {"U", 2.88},
    {"C", 2.71},
    {"M", 2.61},
    {"F", 2.30},
    {"Y", 2.11},
    {"W", 2.09},
    {"G", 2.03},
    {"P", 1.82},
    {"B", 1.49},
    {"V", 1.11},
    {"K", 0.69},
    {"X", 0.17},
    {"Q", 0.11},
    {"J", 0.10},
    {"Z", 0.07}
};

// Settings for wordlist class.
struct WLSettings {
    double length_k = 0.5f; // length scaling factor for function f(x) = length_k * x(x + 1)
    double vowel_k = 0.75f; // vowel scaling factor (multiplied by this - lower is harder)
};

// Wordlist class.
class Wordlist {
private:
    std::map<char, double> frequencies; // letter --> frequency
    std::vector<std::string> words; // sorted from easiest --> hardest (in ascending order)
    std::map<std::string, double> scores; // word --> score (higher is easier, lower is harder)
    int levelIndices[NUM_LEVELS + 1]; // leveling data
    
    inline bool isVowel(char ch); // return if the specified character is a vowel
    void initLevels(); // initialize level data
public:
    Wordlist();
    ~Wordlist(){ }
    
    std::string dispProgress(int at, int total, std::string message="Progress", std::string style="percent", int metering=-1, int increment=5, bool silent=false); // display progress in multiple ways
    bool readWordlist(std::string filename); // read wordlist
    std::vector<std::string>& getSortedWords(){ return words; } // return sorted wordlist
    void scoreWords(WLSettings settings); // score all words
    double getScoreFor(std::string word); // get score for specific word
    std::string getWordAtLevel(unsigned int level); // higher level = harder
};

#endif /* Wordlist_hpp */
