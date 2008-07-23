//
// BXConnectionPanel.m
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

#import "BXConnectionPanel.h"
#import "BXAppKitAdditions.h"


__strong static NSArray* gManuallyNotifiedKeys = nil;


@implementation BXConnectionPanel

+ (void) initialize
{
    static BOOL tooLate = NO;
    if (NO == tooLate)
    {
        tooLate = YES;
        gManuallyNotifiedKeys = [[NSArray alloc] initWithObjects: @"displayedAsSheet", nil];
    }
}

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) aKey
{
    BOOL rval = NO;
    if (NO == [gManuallyNotifiedKeys containsObject: aKey])
        rval = [super automaticallyNotifiesObserversForKey: aKey];
    return rval;
}

+ (id) connectionPanel
{
	return [[[self alloc] initWithContentRect: NSZeroRect styleMask: NSClosableWindowMask | NSTitledWindowMask | NSResizableWindowMask
									  backing: NSBackingStoreBuffered defer: YES] autorelease];
}

- (id) initWithContentRect: (NSRect) contentRect styleMask: (unsigned int) styleMask
                   backing: (NSBackingStoreType) bufferingType defer: (BOOL) deferCreation
{
    if ((self = [super initWithContentRect: contentRect styleMask: styleMask 
                                   backing: bufferingType defer: deferCreation]))
    {  
        mViewManager = [[BXConnectionViewManager alloc] init];
        [mViewManager setDelegate: self];
        [mViewManager setShowsOtherButton: YES];

        NSView* bonjourListView = [mViewManager bonjourListView];
        NSSize contentSize = [bonjourListView frame].size;
        
        mByHostnameViewMinSize = [[mViewManager byHostnameView] frame].size;
        mBonjourListViewMinSize = contentSize;

        [self setContentSize: contentSize];
        [self setContentView: bonjourListView];
        [self setMinSize: mBonjourListViewMinSize];

		if (NSIsEmptyRect (contentRect) && 0.0 == contentRect.origin.x && 0.0 == contentRect.origin.y)
		{
			NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
			NSPoint origin = NSZeroPoint;
			origin.x = (screenFrame.size.width - contentSize.width) / 2.0;
			origin.y = (screenFrame.size.height - contentSize.height) / 2.0;
			[self setFrameOrigin: origin];
		}
		
        [self setDelegate: self];
    }
    return self;
}

- (void) dealloc
{
	[mViewManager release];
    [mAuxiliaryPanel release];
	[super dealloc];
}

- (void) setConnectionViewManager: (BXConnectionViewManager *) anObject
{
	if (mViewManager != anObject)
	{
		[mViewManager release];
		mViewManager = [anObject retain];
	}
}

- (void) beginSheetModalForWindow: (NSWindow *) docWindow modalDelegate: (id) modalDelegate 
				   didEndSelector: (SEL) didEndSelector contextInfo: (void *) contextInfo
{
    [self willChangeValueForKey: @"displayedAsSheet"];
	mDisplayedAsSheet = YES;
    [self didChangeValueForKey: @"displayedAsSheet"];
	
    [super beginSheetModalForWindow: docWindow modalDelegate: modalDelegate
                     didEndSelector: didEndSelector contextInfo: contextInfo];
}

- (void) becomeKeyWindow
{
	if (NO == mFirstTime)
	{
		mFirstTime = YES;
		[mViewManager startDiscovery];
        if (NO == mDisplayedAsSheet)
        {
            [[mViewManager bonjourCancelButton] bind: @"enabled" toObject: mViewManager
                                         withKeyPath: @"isConnecting" options: nil];
        }
	}
	[super becomeKeyWindow];
}

- (void) auxiliarySheetDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
    mDisplayingAuxiliarySheet = NO;
}

- (BOOL) displayedAsSheet
{
	return mDisplayedAsSheet;
}

- (void) setDatabaseContext: (BXDatabaseContext *) ctx
{
	[mViewManager setDatabaseContext: ctx];
}

- (BXDatabaseContext *) databaseContext
{
	return [mViewManager databaseContext];
}

- (void) setShowsCancelButton: (BOOL) aBool
{
	[mViewManager setShowsCancelButton: aBool];
}

- (void) setShowsOtherButton: (BOOL) aBool
{
	[mViewManager setShowsOtherButton: aBool];
}

- (void) setDatabaseName: (NSString *) aName
{
	[mViewManager setDatabaseName: aName];
}

- (void) end
{
	[super end];
	[mViewManager setConnecting: NO];
}

@end


@implementation BXConnectionPanel (BXConnectionViewManagerDelegate)
- (void) BXShowByHostnameView: (NSView *) hostnameView
{
    NSRect frame = [self frame];
    NSRect contentRect = [hostnameView frame];

	if (mDisplayedAsSheet)
	{		
        contentRect.origin = frame.origin;
        contentRect.origin.y -= contentRect.size.height - frame.size.height;
        contentRect.size.width = frame.size.width;
        
        [mViewManager setShowsBonjourButton: YES];
        [self setContentView: [NSView BXEmptyView]];
        [self display];
		[self setFrame: contentRect display: YES animate: YES];
		[self setContentView: hostnameView];
        [self setMinSize: mByHostnameViewMinSize];
        [hostnameView setNeedsDisplay: YES];
        
        mDisplayingByHostnameView = YES;
	}
	else
	{
		[mViewManager setShowsBonjourButton: NO];
        if (nil == mAuxiliaryPanel)
        {
            mAuxiliaryPanel = [[NSPanel alloc] initWithContentRect: contentRect 
                                                         styleMask: NSTitledWindowMask | NSResizableWindowMask 
                                                           backing: NSBackingStoreBuffered defer: YES];
			
            [mAuxiliaryPanel setReleasedWhenClosed: NO];
            [mAuxiliaryPanel setContentView: hostnameView];
			[mAuxiliaryPanel setMinSize: mByHostnameViewMinSize];
            [mAuxiliaryPanel setDelegate: self];
        }        
        
		[NSApp beginSheet: mAuxiliaryPanel modalForWindow: self modalDelegate: self 
           didEndSelector: @selector (auxiliarySheetDidEnd:returnCode:contextInfo:) 
              contextInfo: NULL];
        mDisplayingAuxiliarySheet = YES;
	}
}

- (void) BXShowBonjourListView: (NSView *) bonjourListView
{
    NSRect frame = [self frame];
    NSRect contentRect = [bonjourListView frame];
    contentRect.origin = frame.origin;
    contentRect.origin.y -= contentRect.size.height - frame.size.height;
    contentRect.size.width = frame.size.width;

    [self setContentView: [NSView BXEmptyView]];
    [self display];
    [self setFrame: contentRect display: YES animate: YES];
    [self setContentView: bonjourListView];
    [self setMinSize: mBonjourListViewMinSize];
    [bonjourListView setNeedsDisplay: YES];

    mDisplayingByHostnameView = NO;
}

- (void) BXHandleError: (NSError *) error
{
	if (YES == mDisplayingAuxiliarySheet)
	{
		[NSApp endSheet: mAuxiliaryPanel];
		[mAuxiliaryPanel close];
	}
	
    [[NSAlert alertWithError: error] beginSheetModalForWindow: nil modalDelegate: nil 
                                               didEndSelector: NULL contextInfo: NULL];
	
	[self continueWithReturnCode: NSCancelButton];		
}

- (void) BXBeginConnecting
{
    if (YES == mDisplayingAuxiliarySheet)
    {
        [NSApp endSheet: mAuxiliaryPanel];
        [mAuxiliaryPanel close];
    }

	[self continueWithReturnCode: NSOKButton];
}

- (void) BXCancelConnecting
{
    if (YES == mDisplayingAuxiliarySheet)
	{
		[NSApp endSheet: mAuxiliaryPanel];
		[mAuxiliaryPanel close];
	}
	else
	{
        [self continueWithReturnCode: NSCancelButton];
	}
}

- (NSSize) windowWillResize: (NSWindow *) sender toSize: (NSSize) proposedFrameSize
{
    if (mDisplayingByHostnameView || sender != self)
    {
        NSSize size = [sender frame].size;
        proposedFrameSize.height = size.height;
    }
    return proposedFrameSize;
}

@end
