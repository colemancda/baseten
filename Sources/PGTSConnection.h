//
// PGTSConnection.h
// BaseTen
//
// Copyright (C) 2008 Marko Karppinen & Co. LLC.
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

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <BaseTen/BXOpenSSLCompatibility.h>
#import <BaseTen/libpq-fe.h>
#import <BaseTen/PGTSCertificateVerificationDelegate.h>
#import <BaseTen/BXConnectionMonitor.h>
@class PGTSConnection;
@class PGTSResultSet;
@class PGTSConnector;
@class PGTSQueryDescription;
@class PGTSMetadataContainer;
@class PGTSDatabaseDescription;
@class PGTSNotification;
@class PGTSQuery;
@class BXSocketDescriptor;
@protocol PGTSConnectorDelegate;


@protocol PGTSConnectionDelegate <NSObject>
- (void) PGTSConnectionFailed: (PGTSConnection *) connection;
- (void) PGTSConnectionEstablished: (PGTSConnection *) connection;
- (void) PGTSConnectionLost: (PGTSConnection *) connection error: (NSError *) error;
- (void) PGTSConnection: (PGTSConnection *) connection gotNotification: (PGTSNotification *) notification;
- (void) PGTSConnection: (PGTSConnection *) connection receivedNotice: (NSError *) notice;
- (FILE *) PGTSConnectionTraceFile: (PGTSConnection *) connection;
- (void) PGTSConnection: (PGTSConnection *) connection networkStatusChanged: (SCNetworkConnectionFlags) newFlags;

//Optional section of the protocol either as an interface or @optional.
#if __MAC_OS_X_VERSION_10_5 <= __MAC_OS_X_VERSION_MAX_ALLOWED
@optional
#else
@end
@interface NSObject (PGTSConnectionDelegate)
#endif
- (void) PGTSConnection: (PGTSConnection *) connection sentQueryString: (const char *) queryString;
- (void) PGTSConnection: (PGTSConnection *) connection sentQuery: (PGTSQuery *) query;
- (void) PGTSConnection: (PGTSConnection *) connection receivedResultSet: (PGTSResultSet *) res;
@end


enum PGTSConnectionError
{
	kPGTSConnectionErrorNone = 0,
	kPGTSConnectionErrorUnknown,
	kPGTSConnectionErrorSSLUnavailable,
	kPGTSConnectionErrorPasswordRequired,
	kPGTSConnectionErrorInvalidPassword,
	kPGTSConnectionErrorSSLError,
	kPGTSConnectionErrorSSLCertificateVerificationFailed
};


@interface PGTSConnection : NSObject
{
	PGconn* mConnection;
	NSMutableArray* mQueue;
	id mConnector;
    PGTSMetadataContainer* mMetadataContainer;
    NSMutableDictionary* mPGTypes;
	id <PGTSCertificateVerificationDelegate> mCertificateVerificationDelegate; //Weak	
	BXSocketDescriptor *mSocketDescriptor;
	
    id <PGTSConnectionDelegate> mDelegate; //Weak
	
	BOOL mDidDisconnectOnSleep;
	volatile BOOL mLogsQueries;
}
- (id) init;
- (void) dealloc;
- (void) connectAsync: (NSDictionary *) connectionDictionary;
- (BOOL) connectSync: (NSDictionary *) connectionDictionary;
- (void) resetAsync;
- (BOOL) resetSync;
- (void) disconnect;
- (id <PGTSConnectionDelegate>) delegate;
- (void) setDelegate: (id <PGTSConnectionDelegate>) anObject;
- (PGTSDatabaseDescription *) databaseDescription;
- (void) reloadDatabaseDescription;
- (id) deserializationDictionary;
- (NSError *) connectionError;
- (NSString *) errorString;
- (ConnStatusType) connectionStatus;
- (PGTransactionStatusType) transactionStatus;
- (BOOL) usedPassword;
- (PGconn *) pgConnection;
- (int) backendPID;
- (int) socket;
- (SSL *) SSLStruct;
- (BOOL) canSend;
- (BXSocketDescriptor *) socketDescriptor;

- (id <PGTSCertificateVerificationDelegate>) certificateVerificationDelegate;
- (void) setCertificateVerificationDelegate: (id <PGTSCertificateVerificationDelegate>) anObject;

- (BOOL) logsQueries;
- (void) setLogsQueries: (BOOL) flag;

- (void) logQueryIfNeeded: (PGTSQuery *) query;
- (void) logResultIfNeeded: (PGTSResultSet *) res;
@end



@interface PGTSConnection (BXConnectionMonitorClient) <BXConnectionMonitorClient>
@end



@interface PGTSConnection (Queries)
- (PGTSResultSet *) executeQuery: (NSString *) queryString;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameters: (id) p1, ...;
- (PGTSResultSet *) executeQuery: (NSString *) queryString parameterArray: (NSArray *) parameters;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback parameters: (id) p1, ...;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback parameterArray: (NSArray *) parameters;
- (int) sendQuery: (NSString *) queryString delegate: (id) delegate callback: (SEL) callback 
   parameterArray: (NSArray *) parameters userInfo: (id) userInfo;
@end
