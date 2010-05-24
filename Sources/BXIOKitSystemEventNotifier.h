//
// BXIOKitSystemEventNotifier.h
// BaseTen
//
// Copyright (C) 2010 Marko Karppinen & Co. LLC.
//
// Before using this software, please review the available licensing options
// by visiting http://www.karppinen.fi/baseten/licensing/ or by contacting
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

#import <BaseTen/BXSystemEventNotifier.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>


@interface BXIOKitSystemEventNotifier : BXSystemEventNotifier
{
	CFRunLoopRef mRunLoop;
	CFRunLoopSourceRef mRunLoopSource;
	IONotificationPortRef mIONotificationPort;
	io_object_t mIONotifier;
	io_connect_t mIOPowerSession;
}
- (void) invalidate;
- (io_connect_t) IOPowerSession;
@end
