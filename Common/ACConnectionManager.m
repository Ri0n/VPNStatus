//
//  ACConnectionManager.m
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "ACConnectionManager.h"
#import "ACNEService.h"
#import "ACNEServicesManager.h"
#import "ACPreferences.h"

@interface ACConnectionManager ()

// Timer to try to reconnect services set to always auto connect
@property (strong) NSTimer *autoConnectTimer;

@end


@implementation ACConnectionManager

+ (ACConnectionManager *) sharedManager {
	static ACConnectionManager *sSharedManager = nil;
	if(sSharedManager == nil) {
		sSharedManager = [[ACConnectionManager alloc] init];
	}
	
	return sSharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self startAutoConnectTimer];
    }
    return self;
}

- (void) toggleConnectionForService:(ACNEService *) service {
	if (service == nil)
		return;
	
	SCNetworkConnectionStatus serviceState = [service state];
	
	switch(serviceState) {
		case kSCNetworkConnectionDisconnected:
            [service connect];
            break;
		case kSCNetworkConnectionConnected:
            [service disconnect];
            break;
		default:
            break;
	}
}

- (void) startConnectionForService:(NSString *)serviceId {
	if ([serviceId length] <= 0)
		return;
	
	// Get all services and find the correct NEService
	NSArray <ACNEService*>* services =
        [[ACNEServicesManager sharedNEServicesManager] services];
	
	ACNEService *foundService = nil;
	for(ACNEService *service in services) {
		if([serviceId isEqualToString:[service.configuration.identifier UUIDString]]) {
			foundService = service;
			break;
		}
	}
	
	// Connect to the service if it is currently disconnected
	if(foundService != nil) {
		if([foundService state] == kSCNetworkConnectionDisconnected) {
			[foundService connect];
		}
	}
}

- (void) startAutoConnectTimer {
	// Recreate the timer
	if(self.autoConnectTimer != nil) {
		[self.autoConnectTimer invalidate];
		self.autoConnectTimer = nil;
	}
	
	self.autoConnectTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:[[ACPreferences sharedPreferences] autoConnectInterval] repeats:YES block:^(NSTimer * timer) {
		// Each time the timer fires, execute this block
        NSArray <NSString *> * serviceIds = [[ACPreferences sharedPreferences]
                                             autoConnectServicesIds];
        for(NSString *serviceId in serviceIds) {
            [self startConnectionForService:serviceId];
        }
	}];
	
	// Add the timer to the RunLoop
	[[NSRunLoop currentRunLoop] addTimer:self.autoConnectTimer forMode:NSDefaultRunLoopMode];
}

- (void) setAutoConnect:(BOOL) autoConnect
               forService:(ACNEService *) service {
	if (service == nil) return;
	
	// Save the preferences
	[[ACPreferences sharedPreferences] setAutoConnect:autoConnect forServiceId:[service.configuration.identifier UUIDString]];
	
	// Start the Timer
	[self startAutoConnectTimer];
}

- (BOOL) hasAutoConnect {
	
	NSArray<NSString *>*serviceIds = [[ACPreferences sharedPreferences]
                                      autoConnectServicesIds];
	if([serviceIds count] <= 0)
		return NO;
	
	// Check each service
	NSArray <ACNEService*>* services = [[ACNEServicesManager sharedNEServicesManager] services];
	for(ACNEService *neService in services) {
		if([serviceIds containsObject:[neService.configuration.identifier UUIDString]]) {
            return YES;
		}
	}
	
	return NO;
}

-(void) disconnectAllAutoConnectedServices {
	NSArray<NSString *>*serviceIds = [[ACPreferences sharedPreferences] autoConnectServicesIds];
	if ([serviceIds count] <= 0) return;
	
	// Disconnect each service marked as always auto connecting
	NSArray <ACNEService*>* services = [[ACNEServicesManager sharedNEServicesManager] services];
	for(ACNEService *service in services) {
		if([serviceIds containsObject:[service.configuration.identifier UUIDString]]) {
			[service disconnect];
		}
	}
}

-(void)connectAllAutoConnectedServices {
	NSArray<NSString *>*serviceIds = [[ACPreferences sharedPreferences] autoConnectServicesIds];
	if ([serviceIds count] <= 0) return;
	
	// Connect each service marked as always auto connecting
	NSArray <ACNEService*>* services = [[ACNEServicesManager sharedNEServicesManager] services];
	for(ACNEService *service in services) {
		if([serviceIds containsObject:[service.configuration.identifier UUIDString]]) {
            if ([service state] == kSCNetworkConnectionDisconnected)
                [service connect];
		}
	}
}

@end
