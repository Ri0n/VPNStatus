//
//  ACNEService.h
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//
//	The ACNEService class replicates the ANPNEService class from Network.prefPane
//	The initializer takes a NEConfiguration object from the NetworkExtension.framework.
//
//

#import <Foundation/Foundation.h>
#import "ACDefines.h"
#import "ACNEServicesManager.h"
#import "ACPreferences.h"
#import "ACCWManager.h"

@interface ACNEService : NSObject

@property (retain) NEConfiguration * configuration;
@property (assign) ne_session_t session;

// Use to ensure we got the session status
@property (assign) BOOL gotInitialSessionStatus;
@property (assign) BOOL start; // true if the user want it to start
@property (assign) ne_session_status_t sessionStatus;
@property (retain) NSDate *lastConnectTime;
@property (assign) int connectTried;

// init
- (instancetype) initWithConfig:(NEConfiguration *)inConfiguration;

// Access information
-(NSString *) name;
-(NSString *) serverAddress;
-(NSString *) protocol;
-(NSString *) uid;

-(BOOL) shouldAutoReconnect;
-(BOOL) shouldAutoStartConnect;
-(BOOL) getVPNAutoConnect;
-(void) setVPNAutoConnect:(BOOL) autoConnect;
-(BOOL) getWifiAutoConnect;
-(void) setWifiAutoConnect:(BOOL) autoConnect;
-(BOOL) getWifiAutoConnect:(NSString *) bssid;
-(void) setWifiAutoConnect:(NSString *) bssid to:(BOOL) autoConnect;

// Refresh and get the state of the session
-(void) refreshSession;
-(SCNetworkConnectionStatus) state;

// Connect and disconnect
-(void) connect;
-(void) disconnect;

@end

