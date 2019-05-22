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

-(void) setAutoConnect:(BOOL)autoConnect forId:(NSString *)serviceId{
    NSMutableDictionary *servicesPref = [[self getServicesPref] mutableCopy];
    if (servicesPref[serviceId] == nil)
        servicesPref[serviceId] = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *servicePref = [servicesPref[serviceId] mutableCopy];
    servicePref[kServiceAutoConnectKey] = [NSNumber numberWithBool:autoConnect];
    servicesPref[serviceId] = servicePref;
    [self setServicesPref:servicesPref];
}

-(BOOL) getAutoConnect:(NSString *)serviceId {
    NSDictionary *serivicesPref = [self getServicesPref];
    NSDictionary *servicePref = serivicesPref[serviceId];
    if (servicePref == nil) return NO;
    return [servicePref[kServiceAutoConnectKey] boolValue];
}

-(NSDictionary *) getServicesPref{
    NSDictionary *servicesPref = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kServicesPrefKey];
    if(servicesPref == nil) servicesPref = [[NSDictionary alloc] init];
    return servicesPref;
}

-(void) setServicesPref:(NSDictionary *) servicesPref{
    [[NSUserDefaults standardUserDefaults] setObject:servicesPref forKey:kServicesPrefKey];
}

@end
