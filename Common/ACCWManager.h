//
//  ACCWManager.h
//  VPNStatus
//
//  Created by Toby on 2019-08-01.
//  Copyright © 2019 Timac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>
#import "ACDefines.h"
#import "ACNEService.h"
#import "ACNEServicesManager.h"

@interface ACCWManager : NSObject<CWEventDelegate>

/**
 Get the singleton object
 */
+ (ACCWManager *)sharedACCWManager;
- (CWInterface *) wlan;
- (BOOL)networkConnected;
- (BOOL)networkReachable;

@end
