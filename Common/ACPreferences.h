//
//  ACPreferences.h
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//
//	This class is used to deal with the application preferences.

#import <Cocoa/Cocoa.h>


@interface ACPreferences : NSObject

/**
 Get the singleton object
 */
+ (ACPreferences *) sharedPreferences;


/**
 Return the list of VPN service identifiers that have been set to auto connect
 */
-(NSArray<NSString *>*) autoConnectServicesIds;


/**
 Enable or disable auto connect for the VPN service
 */
-(void) setAutoConnect:(BOOL)autoConnect forServiceId:(NSString *)inServiceId;


/**
 How often should we retry to connect to the VPN?
 Default is 60s
 */
-(NSInteger)autoConnectInterval;


@end

