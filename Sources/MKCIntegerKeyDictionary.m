//
// MKCIntegerKeyDictionary.m
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


#import "MKCDictionaryPrivate.h"
#import "MKCDictionaryEnumerators.h"


#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_4
#define CALLBACKS NSIntMapKeyCallBacks
#else
#define CALLBACKS NSIntegerMapKeyCallBacks
#endif


@implementation MKCIntegerKeyDictionary

- (id) initWithCapacity: (NSUInteger) capacity
{
	return [self initWithMapTable: NSCreateMapTableWithZone (CALLBACKS, NSObjectMapValueCallBacks, capacity, [self zone])];
}

- (id) objectAtIndex: (NSUInteger) anIndex
{
	id retval = nil;
	if (NSNotFound != anIndex)
		retval = NSMapGet (mMapTable, (void *) anIndex);
	return retval;
}

- (void) setObject: (id) anObject atIndex: (NSUInteger) anIndex
{
	NSMapInsert (mMapTable, (void *) anIndex, anObject);
}

- (id) keyEnumerator
{
	return [[[MKCIntegerDictionaryKeyEnumerator allocWithZone: [self zone]] initWithEnumerator: NSEnumerateMapTable (mMapTable)] autorelease];
}

- (id) objectForKey: (id) aKey
{
	return [self objectAtIndex: [aKey unsignedIntValue]];
}

- (id) allObjects
{
    return NSAllMapTableValues (mMapTable);
}

@end
