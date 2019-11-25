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
NSString * const kIdKey = @"VPN";
NSString * const kWifiPrefKey = @"Wifis";
NSString * const kAutoConnectKey = @"AutoConnect";


@implementation ACPreferences


+ (ACPreferences *)sharedPreferences {
	static ACPreferences *SsharedPreferences = nil;
	if(SsharedPreferences == nil) {
		SsharedPreferences = [[ACPreferences alloc] init];
	}
	
	return SsharedPreferences;
}

- (NSDictionary *)getPrefs{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults]
                           dictionaryForKey:kServicesPrefKey];
    if (prefs == nil) prefs = [[NSDictionary alloc] init];
    return prefs;
}

- (void)setPrefs: (NSDictionary *) pref{
    [[NSUserDefaults standardUserDefaults] setObject:pref forKey:kServicesPrefKey];
}

- (NSDictionary *)getVPNPrefs: (NSString *)VPNId{
    NSDictionary *prefs = [self getPrefs][VPNId];
    if (prefs == nil) prefs = [[NSDictionary alloc] init];
    return prefs;
}

- (BOOL)getVPNAutoConnect:(NSString *)VPNId{
    NSDictionary *VPNPref = [self getVPNPrefs:VPNId];
    return [VPNPref[kAutoConnectKey] boolValue];
} 

- (BOOL)getWifiAutoConnect:(NSString *)VPNId forWifi:(NSString *)wifiId{
    NSDictionary *VPNPref = [self getVPNPrefs:VPNId];
    return VPNPref[wifiId] != nil;
}

- (void)setVPNAutoConnect:(BOOL)autoConnect forVPN:(NSString *)VPNId{
    NSMutableDictionary *VPNPref = [[self getVPNPrefs:VPNId] mutableCopy];
    NSMutableDictionary *prefs = [[self getPrefs] mutableCopy];
    VPNPref[kAutoConnectKey] = [NSNumber numberWithBool:autoConnect];
    prefs[VPNId] = VPNPref;
    [self setPrefs:prefs];
}

- (void)setWifiAutoConnect:(BOOL)autoConnect forVPN:(NSString *)VPNId forWifi:(NSString *)wifiId{
    NSMutableDictionary *VPNPref = [[self getVPNPrefs:VPNId] mutableCopy];
    NSMutableDictionary *prefs = [[self getPrefs] mutableCopy];
    VPNPref[wifiId] = autoConnect ? [NSNumber numberWithBool:autoConnect] : nil;
    prefs[VPNId] = VPNPref;
    [self setPrefs:prefs];
}

@end
