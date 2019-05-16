//
//  ACPreferences.m
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "ACPreferences.h"

//
// Preferences keys
//
NSString * const kServicesPrefKey = @"Services";
NSString * const kServiceIdKey = @"Id";
NSString * const kServiceAutoConnectKey = @"AutoConnect";

NSString * const kAutoConnectIntervalKey = @"AutoConnectInterval";



@implementation ACPreferences


+ (ACPreferences *)sharedPreferences {
	static ACPreferences *SsharedPreferences = nil;
	if(SsharedPreferences == nil) {
		SsharedPreferences = [[ACPreferences alloc] init];
	}
	
	return SsharedPreferences;
}

-(NSArray<NSString *>*)autoConnectServicesIds {
	NSMutableArray<NSString *>* result = [[NSMutableArray alloc] init];
	
	// Get the list of services that should always been connected
	NSArray <NSDictionary *>*services = [[NSUserDefaults standardUserDefaults] arrayForKey:kServicesPrefKey];
	for (NSDictionary *service in services) {
		NSString *serviceId = service[kServiceIdKey];
		BOOL isAlwaysConnected = [service[kServiceAutoConnectKey] boolValue];
		if(isAlwaysConnected && [serviceId length] > 0) {
			[result addObject:serviceId];
		}
	}
	
	return result;
}

-(void) setAutoConnect:(BOOL)autoConnect forServiceId:(NSString *)targetServiceId {
	BOOL serviceFound = NO;
	NSMutableArray <NSDictionary *>*services = [[[NSUserDefaults standardUserDefaults] arrayForKey:kServicesPrefKey] mutableCopy];
	if(services == nil) {
		services = [[NSMutableArray alloc] init];
	}
	
	for(NSDictionary *service in services) {
		NSString *serviceId = service[kServiceIdKey];
		if([serviceId isEqualToString:targetServiceId]) {
			NSMutableDictionary *updatedServiceDictionary = [service mutableCopy];
			updatedServiceDictionary[kServiceAutoConnectKey] = [NSNumber numberWithBool:autoConnect];
			
			[services removeObject:service];
			[services addObject:updatedServiceDictionary];
			
			serviceFound = YES;
			break;
		}
	}
	
	if(!serviceFound) {
		NSMutableDictionary *serviceDictionary = [[NSMutableDictionary alloc] init];
		serviceDictionary[kServiceIdKey] = targetServiceId;
		serviceDictionary[kServiceAutoConnectKey] = [NSNumber numberWithBool:autoConnect];
		[services addObject:serviceDictionary];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:services forKey:kServicesPrefKey];
}

-(NSInteger)autoConnectInterval {
	NSInteger retryDelay = [[NSUserDefaults standardUserDefaults] integerForKey:kAutoConnectIntervalKey];
	if(retryDelay <= 1) {
		// Default is 60s
		retryDelay = 60;
	}
	
	return retryDelay;
}

@end
