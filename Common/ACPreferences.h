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
 Enable or disable auto connect for the VPN service
 */
-(void) setAutoConnect:(BOOL)autoConnect forId:(NSString *)serviceId;

-(BOOL) getAutoConnect:(NSString *)serviceId;


@end

