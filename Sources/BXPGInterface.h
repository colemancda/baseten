//
// BXPGInterface.h
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

#import <Foundation/Foundation.h>
#import <BaseTen/BXInterface.h>
#import <BaseTen/BXEntityDescription.h>
#import <BaseTen/BXAttributeDescription.h>
#import <BaseTen/BXDatabaseObject.h>

@protocol BXObjectAsynchronousLocking;
@protocol PGTSConnectionDelegate;
@protocol PGTSResultRowProtocol;
@class PGTSConnection;
@class PGTSModificationNotifier;
@class PGTSLockNotifier;
@class PGTSTableInfo;
@class PGTSResultSet;
@class BXDatabaseContext;
@class BXDatabaseObjectID;
@class BXPGCertificateVerificationDelegate;

enum BXPGQueryState
{
    kBXPGQueryIdle = 0,
    kBXPGQueryBegun,
    kBXPGQueryLock,
};


@interface NSString (BXPGInterfaceAdditions)
- (NSArray *) BXPGKeyPathComponents;
@end


@interface BXEntityDescription (BXPGInterfaceAdditions)
- (NSString *) PGTSQualifiedName: (PGTSConnection *) connection;
@end


@interface BXAttributeDescription (BXPGInterfaceAdditions)
- (id) PGTSConstantExpressionValue: (NSMutableDictionary *) context;
- (NSString *) PGTSEscapedName: (PGTSConnection *) connection;
@end


@interface BXDatabaseObject (BXPGInterfaceAdditions) <PGTSResultRowProtocol>
@end


@interface BXPGInterface : NSObject <BXInterface, PGTSConnectionDelegate> 
{
    BXDatabaseContext* context; //Weak
    NSURL* databaseURI;
    PGTSConnection* connection;
    PGTSConnection* notifyConnection;
    PGTSModificationNotifier* mChangeNotifier;
	PGTSModificationNotifier* mExternalChangeNotifier;
    PGTSLockNotifier* lockNotifier;
 	BXPGCertificateVerificationDelegate* cvDelegate;
	NSMutableDictionary* mForeignKeys;
    NSMutableSet* mObservedEntities;
   
    enum BXPGQueryState state; /** What kind of query has been sent recently? */
    id <BXObjectAsynchronousLocking> locker;
    NSString* lockedKey;
    BXDatabaseObjectID* lockedObjectID;
	
	BOOL autocommits;
    BOOL logsQueries;
    BOOL clearedLocks;	
	volatile BOOL invalidCertificate;
}

- (NSMutableArray *) executeFetchForEntity: (BXEntityDescription *) entity 
                             withPredicate: (NSPredicate *) predicate 
                           returningFaults: (BOOL) returnFaults 
                                     class: (Class) aClass
								 forUpdate: (BOOL) forUpdate
                                     error: (NSError **) error;
@end


@interface BXPGInterface (Helpers)
- (PGTSModificationNotifier *) changeNotifierForEntity: (BXEntityDescription *) entity;
- (void) checkSuperEntities: (BXEntityDescription *) entity;
- (NSMutableArray *) objectIDsFromResult: (PGTSResultSet *) res 
								  entity: (BXEntityDescription *) entity;
- (BOOL) observeIfNeeded: (BXEntityDescription *) entity error: (NSError **) error;
- (void) lockAndNotifyForEntity: (BXEntityDescription *) entity 
                    whereClause: (NSString *) whereClause
                     parameters: (NSArray *) parameters
                     willDelete: (BOOL) willDelete;

- (void) packError: (NSError **) error exception: (NSException *) exception;
- (void) packPGError: (NSError **) error exception: (PGTSException *) exception;

- (NSDictionary *) lastModificationForEntity: (BXEntityDescription *) entity;
- (NSArray *) notificationObjectIDs: (NSNotification *) notification relidKey: (NSString *) relidKey;
- (NSArray *) notificationObjectIDs: (NSNotification *) notification relidKey: (NSString *) relidKey
                             status: (enum BXObjectLockStatus *) status;

- (BXEntityDescription *) entityForTable: (PGTSTableInfo *) table error: (NSError **) error;

- (void) prepareConnection: (enum BXSSLMode) mode;
- (void) checkConnectionStatusAndAutocommit: (NSError **) error;
- (BOOL) checkConnectionStatus: (PGTSConnection *) conn error: (NSError **) error;

- (void) fetchForeignKeys;
@end


@interface BXPGInterface (Accessors)
- (void) setLocker: (id <BXObjectAsynchronousLocking>) anObject;
- (void) setLockedKey: (NSString *) aKey;
- (void) setLockedObjectID: (BXDatabaseObjectID *) lockedObjectID;
- (void) setHasInvalidCertificate: (BOOL) aBool;
@end


@interface BXPGInterface (Transactions)
- (void) beginIfNeeded;
- (void) beginSubtransactionIfNeeded;
- (void) internalRollback;
- (void) endSubtransactionIfNeeded;
- (void) internalCommit;
@end
