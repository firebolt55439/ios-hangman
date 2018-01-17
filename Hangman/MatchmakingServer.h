//
//  MatchmakingServer.h
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

typedef enum {
    ServerStateIdle,
    ServerStateAcceptingConnections,
    ServerStateIgnoringNewConnections,
} ServerState;

@class MatchmakingServer;

@protocol MatchmakingServerDelegate <NSObject>

- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID;
- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID;
- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server;
- (void)matchmakingServerNoNetwork:(MatchmakingServer *)server;

@end

@interface MatchmakingServer : NSObject <GKSessionDelegate>

@property (nonatomic, weak) id <MatchmakingServerDelegate> delegate;
@property (nonatomic, assign) int maxClients;
@property (nonatomic, strong, readonly) NSArray *connectedClients;
@property (nonatomic, strong, readonly) GKSession *session;

- (void)startAcceptingConnections;
- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID;
- (void)stopAcceptingConnections;
- (NSUInteger)connectedClientCount;
- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (void)endSession;

@end
