//
//  ACNEService.m
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "ACNEService.h"
#import "ACNEServicesManager.h"
#import "ACPreferences.h"

@implementation ACNEService

- (instancetype)initWithConfig:(NEConfiguration *)config {
    self = [super init];
    if (self) {
        _configuration = config;
		_gotInitialSessionStatus = NO;
        _start = NO;
        _connectTried = 0;
        _lastConnectTime = nil;
		
        // Get the configuration identifier to initialize the ne_session_t
        NSUUID *uuid = [config identifier];
		uuid_t uuidBytes;
		[uuid getUUIDBytes:uuidBytes];
		
        // Create the ne_session
        _session = ne_session_create(uuidBytes, NESessionTypeVPN);
		
		// Setup the callbacks
        [self setupEventCallback];
        [self refreshSession];
        if ([self shouldAutoConnect]) [self connect];
    }
    
    return self;
}

- (void)dealloc {
	ne_session_set_event_handler(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(xpc_object_t result) { });
	
	// Cancel and release the session
	ne_session_cancel(_session);
	ne_session_release(_session);
}

-(NSString *)name {
	return _configuration.name;
}

-(NSString *)serverAddress {
	return _configuration.VPN.protocol.serverAddress;
}

-(NSString *)uid {
    return [_configuration.identifier UUIDString];
}

-(BOOL)getAutoConnect {
    return [[ACPreferences sharedPreferences] getAutoConnect:[self uid]];
}

-(void)setAutoConnect:(BOOL) autoConnect {
    [[ACPreferences sharedPreferences] setAutoConnect:autoConnect forId:[self uid]];
}

-(NSString *)protocol {
	NEVPNProtocol *protocol = _configuration.VPN.protocol;
	if([protocol isKindOfClass:[NEVPNProtocolIKEv2 class]]) {
		return @"IKEv2";
	} else if([protocol isKindOfClass:[NEVPNProtocolIPSec class]]) {
		return @"IPSec";
	}
	
	// Fallback to catch future protocols?
	NSString *className = [protocol className];
	if([className hasPrefix:@"NEVPNProtocol"]) {
		return [className substringFromIndex:[@"NEVPNProtocol" length]];
	}
	
	
	return @"Unknown";
}

-(SCNetworkConnectionStatus)state {
	if (self.gotInitialSessionStatus) {
		return SCNetworkConnectionGetStatusFromNEStatus(self.sessionStatus);
	} else {
		return kSCNetworkConnectionInvalid;
	}
}

-(void)setupEventCallback {
	ne_session_set_event_handler(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(xpc_object_t result) { [self refreshSession]; });
}

-(void)refreshSession {
	ne_session_get_status(_session, [[ACNEServicesManager sharedNEServicesManager] neServiceQueue], ^(ne_session_status_t status) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.sessionStatus = status;
			self.gotInitialSessionStatus = YES;
            if ([self shouldAutoConnect]) [self connect];
            
			// Post a notification to refresh the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:kSessionStateChangedNotification object:nil];
		});
	});
}

-(BOOL) shouldAutoConnect{
    return [self state] == kSCNetworkConnectionDisconnected
    && [self getAutoConnect]
    && _start;
}

-(void) connect {
    NSDate *now = [NSDate date];
    if (_lastConnectTime == nil ||
        [now compare: [_lastConnectTime dateByAddingTimeInterval:1]]
        == NSOrderedDescending) _connectTried = 0;
    _connectTried++;
    _lastConnectTime = now;
    if (_connectTried > 3 && [self getAutoConnect]){
        //connection failed consecutively
        [self setAutoConnect:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSessionStateChangedNotification object:nil];
        return;
    }
	ne_session_start(_session);
}

-(void) disconnect {
	ne_session_stop(_session);
}

@end

