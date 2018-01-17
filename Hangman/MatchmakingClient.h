//
//  MatchmakingClient.h
//  Hangman
//
//  Created by Sumer Kohli on 11/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

typedef enum {
    QuitReasonNoNetwork,          // no Wi-Fi or Bluetooth
    QuitReasonConnectionDropped,  // communication failure with server
    QuitReasonUserQuit,           // the user terminated the connection
    QuitReasonServerQuit,         // the server quit the game (on purpose)
} QuitReason;

typedef enum {
    ClientStateIdle,
    ClientStateSearchingForServers,
    ClientStateConnecting,
    ClientStateConnected,
} ClientState;

@class MatchmakingClient;

@protocol MatchmakingClientDelegate <NSObject>

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameAvailable:(NSString *)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client serverBecameUnavailable:(NSString *)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client didConnectToServer:(NSString*)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client didDisconnectFromServer:(NSString *)peerID;
- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client;

@end

@interface MatchmakingClient : NSObject <GKSessionDelegate>

@property (nonatomic, strong, readonly) NSArray *availableServers;
@property (nonatomic, strong, readonly) GKSession *session;
@property (nonatomic, weak) id <MatchmakingClientDelegate> delegate;

- (void)startSearchingForServers;
- (void)startSearchingForServersWithSessionID:(NSString *)sessionID;
- (void)connectToServerWithPeerID:(NSString*)peerID;
- (NSUInteger)availableServerCount;
- (NSString *)peerIDForAvailableServerAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (void)disconnectFromServer;

@end
