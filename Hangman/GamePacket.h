//
//  GamePacket.h
//  Hangman
//
//  Created by Sumer Kohli on 12/5/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PacketType : int {
    PacketTypeGameStarting, // sent by server when the game is about to start
    PacketTypeComputerWord, // sent by server to reveal computer word to connected user for collaborative guessing
    PacketTypeUserGuess,    // sent by client or server to all peers when guessing a letter
    PacketTypeWordOver,     // sent by server when this word/game is over, instructing any clients to reset for next word
    PacketTypeResetAck      // sent by any clients to server acknowledging that they have reset their games
};

@interface GamePacket : NSObject

+(NSString*)generatePacket:(PacketType)type withArguments:(id)arguments;

@end
