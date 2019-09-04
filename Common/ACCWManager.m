//
//  ACCoreWLANManager.m
//  VPNStatus
//
//  Created by Toby on 2019-08-01.
//  Copyright © 2019 Timac. All rights reserved.
//

#import "ACCWManager.h"

@implementation ACCWManager

+ (ACCWManager *)sharedACCWManager {
    static ACCWManager *sSharedNEServicesManager = nil;
    if (sSharedNEServicesManager == nil) {
        sSharedNEServicesManager = [[ACCWManager alloc] init];
    }
    return sSharedNEServicesManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [CWWiFiClient sharedWiFiClient].delegate = self;
        NSError *error;
        [[CWWiFiClient sharedWiFiClient] startMonitoringEventWithType:CWEventTypeLinkDidChange error:&error];
        if (error) NSLog(@"error : %@",error);
    }
    return self;
}

- (void) linkDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName{
    NSLog(@"link changed");
    if ([self networkConnected]) 
        [[ACNEServicesManager sharedNEServicesManager] tryConnectAll];
}

- (CWInterface *) wlan{
    return [CWWiFiClient sharedWiFiClient].interface;
}

- (BOOL)networkConnected{
    return [self wlan].bssid != nil;
}

- (BOOL)networkReachable{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(
        kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    
    if (reachability == nil) return NO;
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(reachability, &flags)) return NO;
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) return NO;
    return YES;
}

@end
