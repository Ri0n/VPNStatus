//
//  AppDelegate.m
//  VPNStatus
//
//  Created by Alexandre Colucci on 07.07.2018.
//  Copyright © 2018 Timac. All rights reserved.
//

#import "AppDelegate.h"

#import "ACDefines.h"
#import "ACNEService.h"
#import "ACNEServicesManager.h"
#import "ACCWManager.h"

@interface AppDelegate ()

@property (strong) NSStatusItem *statusItem;

@end

@implementation AppDelegate

- (ACNEService *) findService:(id) sender {
    NSInteger selectedItemIndex = [(NSMenuItem *)sender tag];
    
    // Get all services
    NSArray <ACNEService*>* services = [[ACNEServicesManager sharedNEServicesManager] services];
    
    // Find the currently selected service
    if(selectedItemIndex >= 0 && selectedItemIndex < [services count]) {
        return services[selectedItemIndex];
    }
    return nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	// Create the NSStatusItem
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	[self updateStatusItemIcon];
    [ACCWManager sharedACCWManager];
	
	// Refresh the menu
	[self refreshMenu];
	
	// Register for notifications to refresh the UI
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(refreshMenu)
     name:kSessionStateChangedNotification
     object:nil];

	// Make sure that the ACNEServicesManager singleton is created and load the configurations
	[[ACNEServicesManager sharedNEServicesManager]
     loadConfigurationsWithHandler:^(NSError * error) {
		if(error != nil) {
			NSLog(@"Failed to load the configurations - %@", error);
		}
		[self refreshMenu];
	}];
}

- (void) updateStatusItemIcon {
	NSButton *statusItemButton = [self.statusItem button];
	if(statusItemButton != nil) {
		NSImage *image = [NSImage imageNamed:@"VPNStatusItemOffImage"];
		
		BOOL oneConnected = NO;
        BOOL oneConnecting = NO;
		NSArray <ACNEService*>* services =
            [[ACNEServicesManager sharedNEServicesManager] services];
		for (ACNEService *service in services) {
			if([service state] == kSCNetworkConnectionConnected)
				oneConnected = YES;
            if([service state] == kSCNetworkConnectionConnecting)
                oneConnecting = YES;
		}
		
		if (oneConnected) {
			image = [NSImage imageNamed:@"VPNStatusItemOnImage"];
		} else if (oneConnecting) {
			image = [NSImage imageNamed:@"VPNStatusItemPauseImage"];;
        } else {
			image = [NSImage imageNamed:@"VPNStatusItemOffImage"];
		}
		
		[statusItemButton setImage:image];
	}
}

-(void) refreshMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	
	NSArray <ACNEService*>* services =
        [[ACNEServicesManager sharedNEServicesManager] services];
	
	if([services count] == 0) {
		// Handle the case where there is no VPN service set up
		[menu addItem:[[NSMenuItem alloc]
                       initWithTitle:@"No VPN available"
                       action:nil
                       keyEquivalent:@""]];
		[menu addItem:[NSMenuItem separatorItem]];
	} else {
		NSUInteger connectServiceIndex = 0;
		for(ACNEService *service in services) {
			// Update the controls based on the state
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
			
            NSString * format;
            
			// Update the state
			switch([service state]) {
				case kSCNetworkConnectionDisconnected:
					[menuItem setAction:@selector(connectService:)];
                    format = @"Connect %@";
                    break;
				
				case kSCNetworkConnectionConnected:
					[menuItem setAction:@selector(disconnectService:)];
                    format = @"Disconnect %@";
                    break;
				
				case kSCNetworkConnectionConnecting:
                    [menuItem setAction:@selector(disconnectService:)];
                    format = @"Stop Connecting %@...";
                    break;
				
				case kSCNetworkConnectionDisconnecting:
                    format = @"Disconnecting %@...";
                    break;
				
				case kSCNetworkConnectionInvalid:
				default:
                    format = @"%@ is invalid";
                    break;
			}
            
            [menuItem setTitle:[NSString stringWithFormat: format, service.name]];
			[menuItem setTag:connectServiceIndex];
			[menu addItem:menuItem];
			connectServiceIndex++;
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSUInteger serviceIndex = 0;
		for (ACNEService *service in services) {
			if (serviceIndex > 0) [menu addItem:[NSMenuItem separatorItem]];
			
			[menu addItem:[[NSMenuItem alloc] initWithTitle:service.name
                                                     action:nil
                                              keyEquivalent:@""]];
			
			// Update the information
			[menu addItem:[[NSMenuItem alloc]
                           initWithTitle:[NSString stringWithFormat:@"%@ (%@)",
                                          [service serverAddress],
                                          [service protocol]]
                           action:nil
                           keyEquivalent:@""]];
			
			NSMenuItem *autoConnectVPNMenuItem =
                [[NSMenuItem alloc]
                 initWithTitle:@"Auto reconnect"
                 action:@selector(changeVPNAutoConnect:)
                 keyEquivalent:@""];
			[autoConnectVPNMenuItem setTag:serviceIndex];
            [autoConnectVPNMenuItem setState:[service getVPNAutoConnect] ? NSOnState : NSOffState];
			[menu addItem:autoConnectVPNMenuItem];
            
            if ([[ACCWManager sharedACCWManager] networkConnected]){
                NSMenuItem *autoConnectWifiMenuItem =
                [[NSMenuItem alloc]
                 initWithTitle:@"Auto connect on this wifi"
                 action:@selector(changeWifiAutoConnect:)
                 keyEquivalent:@""];
                [autoConnectWifiMenuItem setTag:serviceIndex];
                [autoConnectWifiMenuItem setState:[service getWifiAutoConnect] ? NSOnState : NSOffState];
                [menu addItem:autoConnectWifiMenuItem];
            }
                
			serviceIndex++;
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	// Other menu items
	[menu addItem:[[NSMenuItem alloc] initWithTitle:@"About VPNStatus" action:@selector(showAbout:) keyEquivalent:@"i"]];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit VPNStatus" action:@selector(quit:) keyEquivalent:@"q"]];
	
	self.statusItem.menu = menu;
	[self updateStatusItemIcon];
}

- (IBAction)connectService:(id)sender {
    ACNEService *service = [self findService:sender];
    if (service != nil) [service connect];
}

-(IBAction) disconnectService:(id)sender {
    ACNEService *service = [self findService:sender];
    if (service != nil) [service disconnect];
}

-(IBAction) showAbout:(id)sender {
	[NSApp orderFrontStandardAboutPanel:self];
}

-(IBAction) quit:(id)sender {
	[NSApp terminate:self];
}

-(IBAction) changeVPNAutoConnect:(id)sender {
    ACNEService *service = [self findService:sender];
    if (service != nil)[service setVPNAutoConnect:![service getVPNAutoConnect]];
	[self refreshMenu];
}

-(IBAction) changeWifiAutoConnect:(id)sender {
    ACNEService *service = [self findService:sender];
    if (service != nil)[service setWifiAutoConnect:![service getWifiAutoConnect]];
    [self refreshMenu];
}

@end
