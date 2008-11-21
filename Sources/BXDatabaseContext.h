//
// BXDatabaseContext.h
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
#import <Security/Security.h>
#import <BaseTen/BXConstants.h>
#import <BaseTen/BXDatabaseContextDelegateProtocol.h>

#ifndef IBAction
#define IBAction void
#endif

#ifndef IBOutlet
#define IBOutlet
#endif

//Hide from Interface Builder
#define BXHiddenId id


@class NSWindow;


@protocol BXInterface;
@protocol BXObjectAsynchronousLocking;
@protocol BXConnectionSetupManager;
@class BXDatabaseObject;
@class BXEntityDescription;
@class BXDatabaseObjectID;
@class NSEntityDescription;


@interface BXDatabaseContext : NSObject
{
    BXHiddenId <BXInterface>				mDatabaseInterface;
    NSURL*									mDatabaseURI;
    id										mObjects;
    NSMutableDictionary*                    mModifiedObjectIDs;
    NSUndoManager*							mUndoManager;
	NSMutableSet*							mLazilyValidatedEntities;
	NSMutableIndexSet*						mUndoGroupingLevels;
	BXHiddenId <BXConnectionSetupManager>	mConnectionSetupManager;
	
    SecKeychainItemRef                      mKeychainPasswordItem;
    NSNotificationCenter*                   mNotificationCenter;
    NSMutableSet*                           mEntities;
    NSMutableSet*                           mRelationships;
	NSMutableDictionary*					mEntitiesBySchema;
	id <BXDatabaseContextDelegate>			mDelegateProxy;
	NSError*								mLastConnectionError;
	
	/** \brief An NSWindow to which sheets are attached. \see -modalWindow */
	IBOutlet NSWindow*						modalWindow;
	IBOutlet id	<BXDatabaseContextDelegate>	delegate;
	
	enum BXConnectionErrorHandlingState		mConnectionErrorHandlingState;

    BOOL									mAutocommits;
    BOOL									mDeallocating;
	BOOL									mDisplayingSheet;
	BOOL									mRetryingConnection;
    BOOL									mRetainRegisteredObjects;
	BOOL									mUsesKeychain;
	BOOL									mCanConnect;
	BOOL									mDidDisconnect;
	BOOL									mConnectsOnAwake;
	BOOL									mSendsLockQueries;
}

+ (BOOL) setInterfaceClass: (Class) aClass forScheme: (NSString *) scheme;
+ (Class) interfaceClassForScheme: (NSString *) scheme;

+ (id) contextWithDatabaseURI: (NSURL *) uri;
- (id) initWithDatabaseURI: (NSURL *) uri;
- (void) setDatabaseURI: (NSURL *) uri;
- (NSURL *) databaseURI;
- (BOOL) isConnected;

- (BOOL) retainsRegisteredObjects;
- (void) setRetainsRegisteredObjects:(BOOL)flag;

- (void) setAutocommits: (BOOL) aBool;
- (BOOL) autocommits;
- (void) rollback;
- (BOOL) save: (NSError **) error;

- (BOOL) connectSync: (NSError **) error;
- (void) connectAsync;
- (void) disconnect;

- (BOOL) connectIfNeeded: (NSError **) error;

- (NSArray *) faultsWithIDs: (NSArray *) anArray;
- (BXDatabaseObject *) registeredObjectWithID: (BXDatabaseObjectID *) objectID;
- (NSArray *) registeredObjectsWithIDs: (NSArray *) objectIDs;
- (NSArray *) registeredObjectsWithIDs: (NSArray *) objectIDs nullObjects: (BOOL) returnNullObjects;

- (NSUndoManager *) undoManager;
- (BOOL) setUndoManager: (NSUndoManager *) aManager;

- (NSWindow *) modalWindow;
- (void) setModalWindow: (NSWindow *) aWindow;
- (id <BXDatabaseContextDelegate>) delegate;
- (void) setDelegate: (id <BXDatabaseContextDelegate>) anObject;

- (BOOL) usesKeychain;
- (void) setUsesKeychain: (BOOL) usesKeychain;
- (void) storeURICredentials;

- (BOOL) canConnect;

- (void) setConnectsOnAwake: (BOOL) aBool;
- (BOOL) connectsOnAwake;

- (void) setSendsLockQueries: (BOOL) aBool;
- (BOOL) sendsLockQueries;

- (void) refreshObject: (BXDatabaseObject *) object mergeChanges: (BOOL) flag;

- (NSNotificationCenter *) notificationCenter;

- (void) setAllowReconnecting: (BOOL) shouldAllow;
- (BOOL) isSSLInUse;

- (BOOL) logsQueries;
- (void) setLogsQueries: (BOOL) shouldLog;
@end


@interface BXDatabaseContext (Queries)
- (id) objectWithID: (BXDatabaseObjectID *) anID error: (NSError **) error;
- (NSSet *) objectsWithIDs: (NSArray *) anArray error: (NSError **) error;

- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) 
                    predicate error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    returningFaults: (BOOL) returnFaults error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    excludingFields: (NSArray *) excludedFields error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    returningFaults: (BOOL) returnFaults updateAutomatically: (BOOL) shouldUpdate error: (NSError **) error;
- (NSArray *) executeFetchForEntity: (BXEntityDescription *) entity withPredicate: (NSPredicate *) predicate 
                    excludingFields: (NSArray *) excludedFields updateAutomatically: (BOOL) shouldUpdate error: (NSError **) error;

- (id) createObjectForEntity: (BXEntityDescription *) entity withFieldValues: (NSDictionary *) fieldValues error: (NSError **) error;

- (BOOL) executeDeleteObject: (BXDatabaseObject *) anObject error: (NSError **) error;

- (BOOL) fireFault: (BXDatabaseObject *) anObject key: (id) aKey error: (NSError **) error;

/* These methods should only be used for purposes which the ones above are not suited. */
- (NSArray *) executeQuery: (NSString *) queryString error: (NSError **) error;
- (NSArray *) executeQuery: (NSString *) queryString parameters: (NSArray *) parameters error: (NSError **) error;
- (unsigned long long) executeCommand: (NSString *) commandString error: (NSError **) error;
@end


@interface BXDatabaseContext (HelperMethods)
- (BOOL) canGiveEntities;
- (NSArray *) objectIDsForEntity: (BXEntityDescription *) anEntity error: (NSError **) error;
- (NSArray *) objectIDsForEntity: (BXEntityDescription *) anEntity predicate: (NSPredicate *) predicate error: (NSError **) error;
- (BXEntityDescription *) entityForTable: (NSString *) tableName inSchema: (NSString *) schemaName error: (NSError **) error;
- (BXEntityDescription *) entityForTable: (NSString *) tableName error: (NSError **) error;
- (NSDictionary *) entitiesBySchemaAndName: (BOOL) reload error: (NSError **) error;
- (BOOL) entity: (NSEntityDescription *) entity existsInSchema: (NSString *) schemaName error: (NSError **) error;
- (BXEntityDescription *) matchingEntity: (NSEntityDescription *) entity inSchema: (NSString *) schemaName error: (NSError **) error;
@end


@interface BXDatabaseContext (NSCoding) <NSCoding> 
/* Only basic support for Interface Builder. */
@end


@interface BXDatabaseContext (IBActions)
- (IBAction) saveDocument: (id) sender;
- (IBAction) revertDocumentToSaved: (id) sender;
- (IBAction) connect: (id) sender;
@end
