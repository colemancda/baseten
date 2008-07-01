//
// BXConnectionViewManager.h
// BaseTen
//
// Copyright (C) 2006-2008 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://basetenframework.org/licensing/ or by contacting
// us at sales@karppinen.fi. Without an additional license, this software
// may be distributed only in compliance with the GNU General Public License.
//
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License, version 2.0,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
// $Id$
//

#import <Cocoa/Cocoa.h>


@class BXDatabaseContext;


@protocol BXConnectionViewManagerDelegate
- (void) BXShowByHostnameView: (NSView *) aView;
- (void) BXShowBonjourListView: (NSView *) aView;
- (void) BXHandleError: (NSError *) error;
- (void) BXBeginConnecting;
- (void) BXCancelConnecting;
@end


@interface BXConnectionViewManager : NSObject 
{
    IBOutlet id <BXConnectionViewManagerDelegate>   mDelegate;

    //Top-level objects
	IBOutlet NSView*                                mBonjourListView;
	IBOutlet NSView*                                mByHostnameView;
	IBOutlet NSArrayController*                     mBonjourArrayController;
    
    //Others
	IBOutlet NSProgressIndicator*                   mBonjourListProgressIndicator;
	IBOutlet NSProgressIndicator*                   mByHostnameProgressIndicator;
    IBOutlet NSTextField*                           mHostnameField;
	IBOutlet NSTableView*							mBonjourList;
	IBOutlet NSButtonCell*							mHostnameCancelButton;
	IBOutlet NSButton*								mBonjourCancelButton;
	
	//Retained
	NSNetServiceBrowser*                            mNetServiceBrowser;
	BXDatabaseContext*                              mDatabaseContext;
	NSString*										mDatabaseName;
	NSTimer*										mNetServiceTimer;
	NSString*										mGivenHostname;
	NSMutableSet*									mNetServices;
	
	BOOL                                            mShowsOtherButton;
	BOOL											mShowsBonjourButton;
	BOOL                                            mIsConnecting;
    BOOL                                            mUseHostname;
	BOOL											mShowsCancelButton;
}

- (BOOL) canConnect;
- (BOOL) isConnecting;
- (void) setConnecting: (BOOL) aBool;
- (BOOL) showsOtherButton;
- (BOOL) showsCancelButton;
- (void) setShowsCancelButton: (BOOL) aBool;
- (void) setShowsOtherButton: (BOOL) aBool;
- (void) setShowsBonjourButton: (BOOL) aBool;
- (void) setDelegate: (id <BXConnectionViewManagerDelegate>) anObject;
- (void) setDatabaseName: (NSString *) aName;
- (NSString *) givenHostname;
- (void) setGivenHostname: (NSString *) aName;

- (void) startDiscovery;
- (void) setDatabaseContext: (BXDatabaseContext *) ctx;
- (BXDatabaseContext *) databaseContext;

- (NSView *) bonjourListView;
- (NSView *) byHostnameView;
- (NSButton *) bonjourCancelButton;
@end


@interface BXConnectionViewManager (IBActions)
- (IBAction) connect: (id) sender;
- (IBAction) cancelConnecting: (id) sender;
- (IBAction) showBonjourList: (id) sender;
- (IBAction) showHostnameView: (id) sender;
@end
