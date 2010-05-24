//
// BXEntityDescription.h
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
#import <BaseTen/BXAbstractDescription.h>
#import <BaseTen/BXConstants.h>


@class BXDatabaseContext;
@class BXDatabaseObjectID;


enum BXEntityFlag
{
	kBXEntityNoFlag					= 0,
	kBXEntityIsEnabled				= 1 << 0, //BaseTen enabling
	kBXEntityIsValidated			= 1 << 1,
	kBXEntityIsView					= 1 << 2,
	kBXEntityGetsChangedByTriggers	= 1 << 3  //Testing for now
};

@interface BXEntityDescription : BXAbstractDescription <NSCopying, NSCoding>
{
    NSURL*                  mDatabaseURI;
    NSString*               mSchemaName;
    Class                   mDatabaseObjectClass;
	NSDictionary*			mAttributes;
    NSDictionary*			mRelationships;
	NSLock*					mValidationLock;

    id                      mObjectIDs;    
    id                      mSuperEntities;
    id                      mSubEntities;
	id						mFetchedSuperEntities; //FIXME: merge with the previous two.
    enum BXEntityFlag       mFlags;
	enum BXEntityCapability mCapabilities;
}

- (NSURL *) databaseURI;
- (NSURL *) entityURI;
- (NSString *) schemaName;
- (BOOL) isEqual: (BXEntityDescription *) desc;
- (NSUInteger) hash;
- (void) setDatabaseObjectClass: (Class) cls;
- (Class) databaseObjectClass;
- (NSDictionary *) attributesByName;
- (NSArray *) primaryKeyFields;
- (NSArray *) fields;
- (BOOL) isView;
- (NSArray *) objectIDs;
- (NSComparisonResult) caseInsensitiveCompare: (BXEntityDescription *) anotherEntity;
- (BOOL) isValidated;
- (NSDictionary *) relationshipsByName;
- (NSDictionary *) propertiesByName;
- (BOOL) hasCapability: (enum BXEntityCapability) aCapability;
- (BOOL) isEnabled;
   
- (void) inherits: (NSArray *) entities;
- (void) addSubEntity: (BXEntityDescription *) entity;
- (id) inheritedEntities;
- (id) subEntities;
- (void) viewGetsUpdatedWith: (NSArray *) entities;
- (id) viewsUpdated;
- (BOOL) getsChangedByTriggers;
- (void) setGetsChangedByTriggers: (BOOL) flag DEPRECATED_ATTRIBUTE;
@end
