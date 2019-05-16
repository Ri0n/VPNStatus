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
#import "ACPreferences.h"
#import "ACConnectionManager.h"

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
	// Create the ACConnectionManager singleton
	[ACConnectionManager sharedManager];
	
	// Create the NSStatusItem
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	[self updateStatusItemIcon];
	
	// Refresh the menu
	[self refreshMenu];
	
	// Register for notifications to refresh the UI
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(refresh)
     name:kSessionStateChangedNotification
     object:nil];

	// Make sure that the ACNEServicesManager singleton is created and load the configurations
	[[ACNEServicesManager sharedNEServicesManager]
     loadConfigurationsWithHandler:^(NSError * error) {
		if(error != nil) {
			NSLog(@"Failed to load the configurations - %@", error);
		}
		[self refresh];
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

-(void) refresh{
    [[ACConnectionManager sharedManager] connectAllAutoConnectedServices];
    [self refreshMenu];
}

-(void) refreshMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	
	NSArray <ACNEService*>* neServices =
        [[ACNEServicesManager sharedNEServicesManager] services];
	
	if([neServices count] == 0) {
		// Handle the case where there is no VPN service set up
		[menu addItem:[[NSMenuItem alloc]
                       initWithTitle:@"No VPN available"
                       action:nil
                       keyEquivalent:@""]];
		[menu addItem:[NSMenuItem separatorItem]];
	} else {
		NSUInteger connectServiceIndex = 0;
		for(ACNEService *neService in neServices) {
			// Update the controls based on the state
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
			
            NSString * format;
            
			// Update the state
			switch([neService state]) {
				case kSCNetworkConnectionDisconnected:
					[menuItem setAction:@selector(connectService:)];
                    format = @"Connect %@";
                    break;
				
				case kSCNetworkConnectionConnected:
					[menuItem setAction:@selector(disconnectService:)];
                    format = @"Disconnect %@";
                    break;
				
				case kSCNetworkConnectionConnecting:
                    format = @"Connecting %@...";
                    break;
				
				case kSCNetworkConnectionDisconnecting:
                    format = @"Disconnecting %@...";
                    break;
				
				case kSCNetworkConnectionInvalid:
				default:
                    format = @"%@ is invalid";
                    break;
			}
            
            [menuItem setTitle:[NSString stringWithFormat: format, neService.name]];
			[menuItem setTag:connectServiceIndex];
			[menu addItem:menuItem];
			connectServiceIndex++;
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSUInteger neServiceIndex = 0;
		for (ACNEService *neService in neServices) {
			if (neServiceIndex > 0) {
				[menu addItem:[NSMenuItem separatorItem]];
			}
			
			[menu addItem:[[NSMenuItem alloc] initWithTitle:neService.name
                                                     action:nil
                                              keyEquivalent:@""]];
			
			// Update the information
			[menu addItem:[[NSMenuItem alloc]
                           initWithTitle:[NSString stringWithFormat:@"%@ (%@)",
                                          [neService serverAddress],
                                          [neService protocol]]
                           action:nil
                           keyEquivalent:@""]];
			
			NSMenuItem *autoConnectMenuItem =
                [[NSMenuItem alloc]
                 initWithTitle:@"Auto connect"
                 action:@selector(changeAutoConnect:)
                 keyEquivalent:@""];
			[autoConnectMenuItem setTag:neServiceIndex];
			NSArray <NSString *> * alwaysConnectedServices =
                [[ACPreferences sharedPreferences]
                 autoConnectServicesIds];
			if ([alwaysConnectedServices containsObject:[neService.configuration.identifier UUIDString]]) {
				[autoConnectMenuItem setState: NSOnState];
			} else {
				[autoConnectMenuItem setState: NSOffState];
			}
			
			[menu addItem:autoConnectMenuItem];
			neServiceIndex++;
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	// Other menu items
	[menu addItem:[[NSMenuItem alloc] initWithTitle:@"About VPNStatus" action:@selector(showAbout:) keyEquivalent:@""]];
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
    
    if (service != nil) {
        [self setAutoConnect:service to:NO];
        [service disconnect];
    }
}

-(IBAction) showAbout:(id)sender {
	[NSApp orderFrontStandardAboutPanel:self];
}

-(IBAction) quit:(id)sender {
	[NSApp terminate:self];
}

-(IBAction) changeAutoConnect:(id)sender {
    ACNEService *service = [self findService:sender];
    
    if (service != nil){
        NSArray<NSString *>* alwaysConnectedServices = [[ACPreferences sharedPreferences] autoConnectServicesIds];
        BOOL autoConnect = [alwaysConnectedServices containsObject:[service.configuration.identifier UUIDString]];
        
        [self setAutoConnect:service to:!autoConnect];
    }
	
	[self refresh];
}

-(void) setAutoConnect: (ACNEService *)service
                    to: (BOOL)autoConnect {
    [[ACConnectionManager sharedManager] setAutoConnect:autoConnect
                                             forService:service];
    [self refresh];
}

@end
