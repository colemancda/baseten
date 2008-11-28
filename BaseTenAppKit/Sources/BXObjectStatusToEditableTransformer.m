//
// BXObjectStatusToEditableTransformer.m
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

#import "BXObjectStatusToEditableTransformer.h"
#import <BaseTen/BXDatabaseObject.h>

/**
 * \brief Transforms and object's status into a boolean indicating, whether it's editable or not.
 *
 * If object has been edited or deleted in another transaction, it won't be editable.
 * \ingroup value_transformers
 */
@implementation BXObjectStatusToEditableTransformer

+ (Class) transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation
{
    return NO;
}

- (id) transformedValue: (NSValue *) objectStatus
{
    BOOL rval = NO;
    enum BXObjectLockStatus status = kBXObjectNoLockStatus;
    [objectStatus getValue: &status];
    
    switch (status)
    {
        case kBXObjectNoLockStatus:
            rval = YES;
        case kBXObjectLockedStatus:
        case kBXObjectDeletedStatus:
        default:
            break;
    }
    
    return [NSNumber numberWithBool: rval];
}

@end
