//
//  ACNEServicesManager.m
//  VPN
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "ACNEServicesManager.h"

#import "ACDefines.h"
#import "ACNEService.h"

@implementation ACNEServicesManager

+ (ACNEServicesManager *)sharedNEServicesManager {
	static ACNEServicesManager *sSharedNEServicesManager = nil;
	if (sSharedNEServicesManager == nil) {
		sSharedNEServicesManager = [[ACNEServicesManager alloc] init];
	}
	
	return sSharedNEServicesManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
    	// Create the dispatch queue
        _neServiceQueue = dispatch_queue_create("Network Extension service Queue", NULL);
		
        // Allocate the NEServices array
        _services = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) loadConfigurationsWithHandler:(void (^)(NSError * error))handler {
	// Load the NEConfigurations
    [[NEConfigurationManager sharedManager] loadConfigurationsWithCompletionQueue:[self neServiceQueue] handler:^(NSArray<NEConfiguration *> * configs, NSError * error) {
		if(error != nil) {
			NSLog(@"ERROR loading configurations - %@", error);
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			// Process the configurations
			[self processConfigs:configs];
			
			handler(error);
		});
	}];
}

- (void)processConfigs:(NSArray <NEConfiguration*>*)configs{
	// Fill the array
	[self.services removeAllObjects];
	
	for(NEConfiguration *config in configs) {
		ACNEService *service = [[ACNEService alloc] initWithConfig:config];
		[self.services addObject:service];
	}
	
	// Sort by name
	[self.services sortUsingComparator:^NSComparisonResult(ACNEService *obj1, ACNEService *obj2) {
		return [obj1.name compare:obj2.name];
	}];
	
	// Refresh the states
	for(ACNEService *service in self.services) {
		[service refreshSession];
	}
}

@end
