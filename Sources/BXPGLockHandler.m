//
// BXPGLockHandler.m
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

#import "BXPGLockHandler.h"
#import "BXDatabaseObjectIDPrivate.h"
#import <PGTS/PGTSAdditions.h>
#import <tr1/unordered_map>

struct LockStruct 
{
	NSMutableArray* forUpdate;
	NSMutableArray* forDelete;
};
typedef std::tr1::unordered_map <Oid, LockStruct> LockMap;


@implementation BXPGLockHandler
- (void) handleNotification: (PGTSNotification *) notification
{
	int backendPID = [mConnection backendPID];
	if ([notification backendPID] != backendPID)
	{
		NSString* query = 
		@"SELECT * FROM %@ "
		@"WHERE baseten_lock_cleared = false "
		@" AND baseten_lock_timestamp > $1::timestamp "
		@" AND baseten_lock_backend_pid != $2 "
		@"ORDER BY baseten_lock_timestamp ASC";
		PGTSResultSet* res = [mConnection executeQuery: query parameters: mLastCheck, [NSNumber numberWithInt: backendPID]];
		
		//Update the timestamp.
		while ([res advanceRow]) 
			[self setLastCheck: [res valueForKey: @"baseten_lock_timestamp"]];
		
		//Sort the locks.
		LockMap* locks = new LockMap ([res count]);
		while ([res advanceRow])
		{
			NSDictionary* row = [res currentRowAsDictionary];
			unichar lockType = [[row valueForKey: @"baseten_lock_query_type"] characterAtIndex: 0];
			Oid tableOid = [[row valueForKey: @"baseten_lock_relid"] PGTSOidValue];
			
			struct LockStruct ls = (* locks) [tableOid];
			
			NSMutableArray* ids = nil;
			switch (lockType) 
			{
				case 'U':
					ids = ls.forUpdate;
					break;
				case 'D':
					ids = ls.forDelete;
					break;
			}
			
			if (! ids)
			{
				ids = [NSMutableArray arrayWithCapacity: [res count]];
				switch (lockType) 
				{
					case 'U':
						ls.forUpdate = ids;
						break;
					case 'D':
						ls.forDelete = ids;
						break;
				}
			}
			
			BXDatabaseObjectID* objectID = [BXDatabaseObjectID IDWithEntity: mEntity primaryKeyFields: row];
			[ids addObject: objectID];
		}
		
		//Send changes.
		LockMap::iterator iterator = locks->begin ();
		BXDatabaseContext* ctx = [mInterface databaseContext];
		while (locks->end () != iterator)
		{
			LockStruct ls = iterator->second;
			if (ls.forUpdate) [ctx lockedObjectsInDatabase: ls.forUpdate status: kBXObjectLockedStatus];
			if (ls.forDelete) [ctx lockedObjectsInDatabase: ls.forDelete status: kBXObjectDeletedStatus];
		}
		
		delete locks;
	}
}
@end
