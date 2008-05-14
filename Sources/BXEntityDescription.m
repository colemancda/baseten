//
// BXEntityDescription.m
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

#import "BXEntityDescription.h"
#import "BXEntityDescriptionPrivate.h"
#import "BXDatabaseAdditions.h"
#import "BXDatabaseContext.h"
#import "BXAttributeDescription.h"
#import "BXRelationshipDescription.h"
#import "BXAttributeDescriptionPrivate.h"
#import "BXPropertyDescriptionPrivate.h"
#import "BXDatabaseObject.h"
#import "BXConstantsPrivate.h"

#import <MKCCollections/MKCCollections.h>
#import <Log4Cocoa/Log4Cocoa.h>


static id gEntities;


/**
 * An entity description contains information about a specific table
 * in a given database.
 * Only one entity description instance is created for a combination of a database
 * URI, a schema and a table.
 *
 * \note This class is not thread-safe, i.e. 
 *       if methods of an BXEntityDescription instance will be called from 
 *       different threads the result is undefined.
 * \ingroup Descriptions
 */
@implementation BXEntityDescription

+ (void) initialize
{
    static BOOL tooLate = NO;
    if (NO == tooLate)
    {
        tooLate = YES;
        gEntities = [MKCDictionary copyDictionaryWithKeyType: kMKCCollectionTypeObject
												   valueType: kMKCCollectionTypeWeakObject];
    }
}

- (id) init
{
	log4Error (@"This initializer should not have been called.");
    [self release];
    return nil;
}

- (id) initWithName: (NSString *) aName
{
	log4Error (@"This initializer should not have been called (name: %@).", aName);
    [self release];
    return nil;
}

/** \note Override -dealloc2 in subclasses instead! */
- (void) dealloc
{
	@synchronized (gEntities)
	{
		[gEntities removeObjectForKey: [self entityKey]];
	}
    
    @synchronized (mRelationships)
    {
        TSEnumerate (currentRel, e, [mRelationships objectEnumerator])
        {
            [currentRel setEntity: nil];
            [[currentRel inverseRelationship] setDestinationEntity: nil];
        }
    }
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: kBXEntityDescriptionWillDeallocNotification
                      object: self];
    
	[self dealloc2];
	[super dealloc];
}

/** 
 * Deallocation helper. 
 * Subclasses should override this instead of dealloc and then call 
 * super's implementation of dealloc2. This is because BXEntityDescriptions 
 * will be stored into a non-retaining collection on creation and removed from 
 * it on dealloc.
 */
- (void) dealloc2
{
	[mRelationships release];
	mRelationships = nil;
	
	[mAttributes release];
	mAttributes = nil;
	
	[mDatabaseURI release];
	mDatabaseURI = nil;
	
	[mSchemaName release];
	mSchemaName = nil;
    
    [mSuperEntities release];
    mSuperEntities = nil;
    
    [mSubEntities release];
    mSubEntities = nil;
	
	[mValidationLock release];
	mValidationLock = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

/** The schema name. */
- (NSString *) schemaName
{
    return [[mSchemaName retain] autorelease];
}

/** The database URI. */
- (NSURL *) databaseURI
{
    return mDatabaseURI;
}

- (id) initWithCoder: (NSCoder *) decoder
{
    NSURL* databaseURI = [decoder decodeObjectForKey: @"databaseURI"];
    NSString* schemaName = [decoder decodeObjectForKey: @"schemaName"];
    NSString* name = [decoder decodeObjectForKey: @"name"];
    id rval = [[[self class] entityWithDatabaseURI: databaseURI table: name inSchema: schemaName] retain];
    
    Class cls = NSClassFromString ([decoder decodeObjectForKey: @"databaseObjectClassName"]);
    if (Nil != cls)
        [rval setDatabaseObjectClass: cls];
		
	[self setAttributes: [decoder decodeObjectForKey: @"attributes"]];
	//FIXME: relationships as well?
 	        
    return rval;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
    [encoder encodeObject: mName forKey: @"name"];
    [encoder encodeObject: mSchemaName forKey: @"schemaName"];
    [encoder encodeObject: mDatabaseURI forKey: @"databaseURI"];
    [encoder encodeObject: NSStringFromClass (mDatabaseObjectClass) forKey: @"databaseObjectClassName"];
	[encoder encodeObject: mAttributes forKey: @"attributes"];
	//FIXME: relationships as well?
}

/** Retain on copy. */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}

- (BOOL) isEqual: (id) anObject
{
    BOOL retval = NO;
    
    if (self == anObject)
        retval = YES;
    else if ([anObject isKindOfClass: [self class]] && [super isEqual: anObject])
	{
		
		BXEntityDescription* aDesc = (BXEntityDescription *) anObject;
        
		log4AssertValueReturn (nil != mName && nil != mSchemaName && nil != mDatabaseURI, NO, 
							   @"Properties should not be nil in -isEqual:.");
		log4AssertValueReturn (nil != aDesc->mName && nil != aDesc->mSchemaName && nil != aDesc->mDatabaseURI, NO, 
							   @"Properties should not be nil in -isEqual:.");
		
		
		if (![mSchemaName isEqualToString: aDesc->mSchemaName])
			goto bail;
		
		if (![mDatabaseURI isEqual: aDesc->mDatabaseURI])
			goto bail;
			
		retval = YES;
	}
bail:
    return retval;
}

- (unsigned int) hash
{
    if (0 == mHash)
    {
        //We use a real hash function with the URI.
        mHash = ([super hash] ^ [mSchemaName hash] ^ [mDatabaseURI BXHash]);
    }
    return mHash;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"<%@ %@ (%p)>", mDatabaseURI, [self name], self];
}

/**
 * Set the class for this entity.
 * Objects fetched using this entity will be instances of
 * the given class, which needs to be a subclass of BXDatabaseObject.
 * \param       cls         The object class.
 */
- (void) setDatabaseObjectClass: (Class) cls
{
    if (YES == [cls isSubclassOfClass: [BXDatabaseObject class]])
	{
        mDatabaseObjectClass = cls;
	}
    else
    {
        NSString* reason = [NSString stringWithFormat: @"Expected %@ to be a subclass of BXDatabaseObject.", cls];
        [NSException exceptionWithName: NSInternalInconsistencyException
                                reason: reason userInfo: nil];
    }
}

/**
 * The class for this entity
 * \return          The default class is BXDatabaseObject.
 */
- (Class) databaseObjectClass
{
    return mDatabaseObjectClass;
}

/**
 * Set the primary key fields for this entity.
 * Normally the database context determines the primary key, when
 * an entity is used in a database query. However, when an entity is a view, the fields
 * may need to be set manually before using the entity in a query.
 * \param   anArray     An NSArray of NSStrings.
 * \internal
 * \note BXAttributeDescriptions should only be created here and in -[BXInterface validateEntity:]
 */
- (void) setPrimaryKeyFields: (NSArray *) anArray
{
	if (nil != anArray)
	{
		NSMutableDictionary* attributes = [[mAttributes mutableCopy] autorelease];
		TSEnumerate (currentField, e, [anArray objectEnumerator])
		{
			BXAttributeDescription* attribute = nil;
			if ([currentField isKindOfClass: [BXAttributeDescription class]])
			{
				log4AssertVoidReturn ([currentField entity] == self, 
									  @"Expected to receive only attributes in which entity is self (self: %@ currentField: %@).",
									  self, currentField);
				attribute = currentField;
			}
			else if ([currentField isKindOfClass: [NSString class]])
			{
                attribute = [BXAttributeDescription attributeWithName: currentField entity: self];
			}
			[attribute setPrimaryKey: YES];
			[attribute setOptional: NO];
			[attributes setObject: attribute forKey: [attribute name]];
		}
		[self setAttributes: attributes];
	}
}

/**
 * Registered object IDs for this entity.
 */
- (NSArray *) objectIDs
{
	return [mObjectIDs allObjects];
}

/**
 * Primary key fields for this entity.
 * The fields get determined automatically after database connection has been made.
 * \return          An array of BXAttributeDescriptions
 * \see #isValidated
 */
- (NSArray *) primaryKeyFields
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"YES == isPrimaryKey"];
	NSArray* rval = [[[mAttributes allValues] filteredArrayUsingPredicate: predicate] 
			sortedArrayUsingSelector: @selector (caseInsensitiveCompare:)];
	if (0 == [rval count]) rval = nil;
	return rval;
}

/** 
 * Non-primary key fields for this entity.
 * \return          An array of BXAttributeDescriptions
 * \see #isValidated
 */
- (NSArray *) fields
{
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"NO == isPrimaryKey"];
	NSArray* rval = [[[mAttributes allValues] filteredArrayUsingPredicate: predicate] 
			sortedArrayUsingSelector: @selector (caseInsensitiveCompare:)];
	if (0 == [rval count]) rval = nil;
	return rval;
}

/** Whether this entity is marked as a view or not. */
- (BOOL) isView
{
    return mFlags & kBXEntityIsView;
}

- (NSComparisonResult) caseInsensitiveCompare: (BXEntityDescription *) anotherEntity
{
    log4AssertValueReturn ([anotherEntity isKindOfClass: [BXEntityDescription class]], NSOrderedSame, 
					 @"Entity descriptions can only be compared with other similar objects for now.");
    NSComparisonResult rval = NSOrderedSame;
    if (self != anotherEntity)
    {
        rval = [mSchemaName caseInsensitiveCompare: [anotherEntity schemaName]];
        if (NSOrderedSame == rval)
        {
            rval = [mName caseInsensitiveCompare: [anotherEntity name]];
        }
    }
    return rval;
}

/** 
 * Attributes for this entity.
 * Primary key fields and other fields for this entity.
 * \return          An NSDictionary with NSStrings as keys and BXAttributeDescriptions as objects.
 * \see #isValidated
 */
- (NSDictionary *) attributesByName
{
	return mAttributes;
}

/**
 * Entity validation.
 * The entity will be validated after a database connection has been made. Afterwards, 
 * #fields, #primaryKeyFields, #attributesByName and #relationshipsByName return meaningful values.
 */
- (BOOL) isValidated
{
	return mFlags & kBXEntityIsValidated;
}

/**
 * Relationships for this entity.
 * \return An NSDictionary with NSStrings as keys and BXRelationshipDescriptions as objects.
 */
- (NSDictionary *) relationshipsByName
{
	return [mRelationships dictionaryRepresentation];
}
@end


@implementation BXEntityDescription (PrivateMethods)

- (NSURL *) entityKey
{
	return [[self class] entityKeyForDatabaseURI: mDatabaseURI schema: mSchemaName table: mName];
}

+ (NSURL *) entityKeyForDatabaseURI: (NSURL *) databaseURI schema: (NSString *) schemaName table: (NSString *) tableName
{
    databaseURI = [databaseURI BXURIForHost: nil database: nil username: @"" password: @""];
	return [NSURL URLWithString: [NSString stringWithFormat: @"%@/%@", schemaName, tableName] relativeToURL: databaseURI];
}

/**
 * \internal
 * \name Retrieving an entity description
 */
//@{
/**
 * \internal
 * Create the entity.
 * \param       anURI   The database URI
 * \param       tName   Table name
 * \param       sName   Schema name
 */
+ (id) entityWithDatabaseURI: (NSURL *) anURI table: (NSString *) tName inSchema: (NSString *) sName
{
	id retval = nil;
	@synchronized (gEntities)
	{
		if (nil == sName)
			sName = @"public";
		
		NSURL* uri = [self entityKeyForDatabaseURI: anURI schema: sName table: tName];
		
		retval = [gEntities objectForKey: uri];
		if (nil == retval)
		{
			retval = [[[self alloc] initWithDatabaseURI: anURI table: tName inSchema: sName] autorelease];
			[gEntities setObject: retval forKey: uri];
		}		
	}
	
	return retval;
}

/**
 * \internal
 * The designated initializer.
 * Create the entity.
 * \param       anURI   The database URI
 * \param       tName   Table name
 * \param       sName   Schema name
 */
- (id) initWithDatabaseURI: (NSURL *) anURI table: (NSString *) tName inSchema: (NSString *) sName
{
	log4AssertValueReturn (nil != sName, nil, @"Expected sName not to be nil.");
	log4AssertValueReturn (nil != anURI, nil, @"Expected anURI to be set.");
	
    if ((self = [super initWithName: tName]))
    {
        mDatabaseObjectClass = [BXDatabaseObject class];
        mDatabaseURI = [anURI copy];
        mSchemaName = [sName copy];
		mRelationships = [MKCDictionary copyDictionaryWithKeyType: kMKCCollectionTypeObject
														valueType: kMKCCollectionTypeWeakObject];
		mObjectIDs = [[MKCHashTable alloc] init];
        mSuperEntities = [[MKCHashTable alloc] init];
        mSubEntities = [[MKCHashTable alloc] init];
		mValidationLock = [[NSLock alloc] init];
    }
    return self;
}
//@}

- (void) registerObjectID: (BXDatabaseObjectID *) anID
{
	@synchronized (mObjectIDs)
	{
		log4AssertVoidReturn ([anID entity] == self, 
							  @"Attempted to register an object ID the entity of which is other than self.\n"
							  "\tanID:\t%@ \n\tself:\t%@", anID, self);
		if (self == [anID entity])
			[mObjectIDs addObject: anID];
	}
}

- (void) unregisterObjectID: (BXDatabaseObjectID *) anID
{
	@synchronized (mObjectIDs)
	{
		[mObjectIDs removeObject: anID];
	}
}

- (void) setAttributes: (NSDictionary *) attributes
{
	if (attributes != mAttributes)
	{
		[mAttributes release];
		mAttributes = [attributes copy];
	}
}

- (void) setDatabaseURI: (NSURL *) anURI
{
	//In case we really modify the URI, remove self from collections and have the hash calculated again.
	if (anURI != mDatabaseURI && NO == [anURI isEqual: mDatabaseURI])
	{
		@synchronized (gEntities)
		{
			[gEntities removeObjectForKey: [self entityKey]];
			mHash = 0;
			
			[mDatabaseURI release];
			mDatabaseURI = [anURI retain];
			
			[gEntities setObject: self forKey: [self entityKey]];
		}
	}
}

- (void) resetAttributeExclusion
{
	TSEnumerate (currentProp, e, [mAttributes objectEnumerator])
		[currentProp setExcluded: NO];
}

- (NSArray *) attributes: (NSArray *) strings
{
	NSMutableArray* rval = nil;
	if (0 < [strings count])
	{
		rval = [NSMutableArray arrayWithCapacity: [strings count]];
		TSEnumerate (currentField, e, [strings objectEnumerator])
		{
			if ([currentField isKindOfClass: [NSString class]])
				currentField = [mAttributes objectForKey: currentField];
			log4AssertValueReturn ([currentField isKindOfClass: [BXAttributeDescription class]], nil, 
								   @"Expected to receive NSStrings or BXAttributeDescriptions (%@ was a %@).",
								   currentField, [currentField class]);
			
			[rval addObject: currentField];
		}
	}
	return rval;
}

- (void) setValidated: (BOOL) flag
{
	if (flag)
		mFlags |= kBXEntityIsValidated;
	else
		mFlags &= ~kBXEntityIsValidated;
}

- (void) setIsView: (BOOL) flag
{
	if (flag)
		mFlags |= kBXEntityIsView;
	else
		mFlags &= ~kBXEntityIsView;
}

- (void) setRelationships: (NSDictionary *) aDict
{
    @synchronized (mRelationships)
    {
        TSEnumerate (currentKey, e, [mRelationships keyEnumerator])
            [mRelationships removeObjectForKey: currentKey];
	
        TSEnumerate (currentKey, e, [aDict keyEnumerator])
        {
            [mRelationships setObject: [aDict objectForKey: currentKey]
                               forKey: currentKey];
        }
    }
}

- (NSLock *) validationLock
{
	return mValidationLock;
}

- (void) removeRelationship: (BXRelationshipDescription *) aRelationship;
{
    @synchronized (mRelationships)
    {
        //FIXME: this is a bit bad but there seems to be an over-retain for BXEntityDescription somewhere.
        [self setValidated: NO];
        
        [mRelationships removeObjectForKey: [aRelationship name]];
    }
}

- (void) viewGetsUpdatedWith: (NSArray *) entities
{
	log4AssertVoidReturn ([self isView], @"Expected entity %@ to be a view.", self);
	[self inherits: entities];
}

- (id) viewsUpdated
{
	log4AssertValueReturn ([self isView], nil, @"Expected entity %@ to be a view.", self);
	return [self inheritedEntities];
}

- (void) inherits: (NSArray *) entities
{
    @synchronized (mSuperEntities)
    {
        //FIXME: We only implement cascading notifications from "root tables" to 
        //inheriting tables and not vice-versa.
        //FIXME: only single entity supported for now.
        log4AssertVoidReturn (0 == [mSuperEntities count], @"Expected inheritance/dependant relations not to have been set.");
        log4AssertVoidReturn (1 == [entities count], @"Multiple inheritance/dependant relations is not supported.");
        TSEnumerate (currentEntity, e, [entities objectEnumerator])
        {
            [mSuperEntities addObject: currentEntity];
            [currentEntity addSubEntity: self];
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector (superEntityWillDealloc:)
                                                         name: kBXEntityDescriptionWillDeallocNotification
                                                       object: currentEntity];
        }
    }
}

- (void) addSubEntity: (BXEntityDescription *) entity
{
    @synchronized (mSubEntities)
    {
        //FIXME: We only implement cascading notifications from "root tables" to 
        //inheriting tables and not vice-versa.
        [mSubEntities addObject: entity];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector (subEntityWillDealloc:)
                                                     name: kBXEntityDescriptionWillDeallocNotification
                                                   object: entity];        
    }
}

- (id) inheritedEntities
{
    id retval = nil;
    @synchronized (mSuperEntities)
    {
        retval = [mSuperEntities allObjects];
    }
    return retval;
}

- (id) subEntities
{
    id retval = nil;
    @synchronized (mSubEntities)
    {
        retval = [mSubEntities allObjects];
    }
    return retval;
}

- (void) superEntityWillDealloc: (NSNotification *) n
{
    @synchronized (mSuperEntities)
    {
        [mSuperEntities removeObject: [n object]];
    }
}

- (void) subEntityWillDealloc: (NSNotification *) n
{
    @synchronized (mSubEntities)
    {
        [mSubEntities removeObject: [n object]];
    }
}

/**
 * \internal
 * Whether this entity gets changed by triggers, rules etc.
 * If the entity gets changed only directly, some queries may possibly be optimized.
 */
- (BOOL) getsChangedByTriggers
{
	return mFlags & kBXEntityGetsChangedByTriggers;
}

- (void) setGetsChangedByTriggers: (BOOL) flag
{
	if (flag)
		mFlags |= kBXEntityGetsChangedByTriggers;
	else
		mFlags &= ~kBXEntityGetsChangedByTriggers;
}

@end