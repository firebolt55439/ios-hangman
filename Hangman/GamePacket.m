//
//  GamePacket.m
//  Hangman
//
//  Created by Sumer Kohli on 12/5/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "GamePacket.h"

@implementation GamePacket

+(NSString*)generatePacket:(PacketType)type withArguments:(id)arguments {
    NSString* ret = [NSString stringWithFormat:@"HANG%2d", type];
    if(type == PacketTypeComputerWord || type == PacketTypeUserGuess){
        NSLog(@"Generating with word/guess: %@", (NSString*)arguments);
        ret = [ret stringByAppendingString:(NSString*)arguments];
    }
    return ret;
}

@end
