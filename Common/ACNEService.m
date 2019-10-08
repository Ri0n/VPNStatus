//
//  ACNEService.m
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "ACNEService.h"

@implementation ACNEService

- (instancetype)initWithConfig:(NEConfiguration *)config {
    self = [super init];
    if (self) {
        _configuration = config;
		_gotInitialSessionStatus = NO;
        _start = NO;
		
        // Get the configuration identifier to initialize the ne_session_t
        NSUUID *uuid = [config identifier];
		uuid_t uuidBytes;
		[uuid getUUIDBytes:uuidBytes];
		
        // Create the ne_session
        _session = ne_session_create(uuidBytes, NESessionTypeVPN);
		
		// Setup the callbacks
        [self setupEventCallback];
        [self refreshSession];
        if ([self shouldAutoStartConnect]) [self connect];
    }
    
    return self;
}

- (void)dealloc {
	ne_session_set_event_handler(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(xpc_object_t result) { });
	
	// Cancel and release the session
	ne_session_cancel(_session);
	ne_session_release(_session);
}

- (NSString *)name {
	return _configuration.name;
}

- (NSString *)serverAddress {
	return _configuration.VPN.protocol.serverAddress;
}

- (NSString *)uid {
    return [_configuration.identifier UUIDString];
}

- (BOOL)getVPNAutoConnect {
    return [[ACPreferences sharedPreferences] 
        getVPNAutoConnect:[self uid]];
}

- (void)setVPNAutoConnect:(BOOL) autoConnect {
    [[ACPreferences sharedPreferences] 
        setVPNAutoConnect:autoConnect forVPN:[self uid]];
}

- (BOOL)getWifiAutoConnect{
    return [self getWifiAutoConnect:[[ACCWManager sharedACCWManager] wlan].ssid];
}

- (void)setWifiAutoConnect:(BOOL)autoConnect{
    return [self setWifiAutoConnect:[[ACCWManager sharedACCWManager] wlan].ssid to:autoConnect];
}

- (BOOL)getWifiAutoConnect:(NSString *) bssid {
    return [[ACPreferences sharedPreferences] 
        getWifiAutoConnect:[self uid] forWifi:bssid];
}
- (void)setWifiAutoConnect:(NSString *) bssid to:(BOOL) autoConnect {
    [[ACPreferences sharedPreferences] 
        setWifiAutoConnect:autoConnect forVPN:[self uid] forWifi:bssid];
}

- (NSString *)protocol {
	NEVPNProtocol *protocol = _configuration.VPN.protocol;
	if([protocol isKindOfClass:[NEVPNProtocolIKEv2 class]]) return @"IKEv2";
	if([protocol isKindOfClass:[NEVPNProtocolIPSec class]]) return @"IPSec";
	// Fallback to catch future protocols?
	NSString *className = [protocol className];
	if([className hasPrefix:@"NEVPNProtocol"]) 
        return [className substringFromIndex:[@"NEVPNProtocol" length]];
	return @"Unknown";
}

- (SCNetworkConnectionStatus)state {
	if (self.gotInitialSessionStatus) 
        return SCNetworkConnectionGetStatusFromNEStatus(self.sessionStatus);
	return kSCNetworkConnectionInvalid;
}

- (void)setupEventCallback {
	ne_session_set_event_handler(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(xpc_object_t result) { [self refreshSession]; });
}

- (void)refreshSession {
	ne_session_get_status(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(ne_session_status_t status) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.sessionStatus = status;
			self.gotInitialSessionStatus = YES;
            if ([self shouldAutoReconnect]) [self connect];
            
			// Post a notification to refresh the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:kSessionStateChangedNotification object:nil];
		});
	});
}

- (BOOL) shouldAutoReconnect{
    return [self state] == kSCNetworkConnectionDisconnected // disconnected
    && [[ACCWManager sharedACCWManager] networkConnected] // network connected
    && [self getVPNAutoConnect] // reconnect enabled
    && _start; // commanded to start
}

- (BOOL) shouldAutoStartConnect{
    return [self state] == kSCNetworkConnectionDisconnected // disonnected
    && [[ACCWManager sharedACCWManager] networkConnected] // networkd connected
    && [self getWifiAutoConnect]; // connect on wifi enabled
}

// enfored max connect try count within 1 second to be less than 5
- (BOOL) connectTriedCheck {
    NSDate *now = [NSDate date];
    if (_lastConnectTime == nil ||
        [now compare: [_lastConnectTime dateByAddingTimeInterval:1]]
        == NSOrderedDescending) _connectTried = 0;
    _connectTried++;
    _lastConnectTime = now;
    return _connectTried < 5;
}

- (void) executeConnect: (int) count {
    NSLog(@"Connecting");
    _start = YES;
    if (![self connectTriedCheck]) return; 
    if (![[ACCWManager sharedACCWManager] networkReachable]) {
        if (count > 0){
            [NSThread sleepForTimeInterval: 1]; // retry after 1'
            [self executeConnect:count - 1];
            return;
        }
        _start = NO; // get out of the loop, connect anyway but disable reconnect
    }
    ne_session_start(_session);
}

- (void) connect {
    [self connect: 5];
}

- (void) connect: (int) count {
    dispatch_async([[ACNEServicesManager sharedNEServicesManager] neServiceQueue],
                   ^{ [self executeConnect: count]; }
                   );
}

- (void) disconnect {
    _start = NO;
	ne_session_stop(_session);
}

@end

