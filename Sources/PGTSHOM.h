//
// PGTSHOM.h
// BaseTen
//
// Copyright (C) 2008-2010 Marko Karppinen & Co. LLC.
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

#import <Foundation/Foundation.h>


@protocol PGTSHOM <NSObject>
- (id) PGTSAny;
- (id) PGTSDo;
- (id) PGTSCollect;
- (id) PGTSCollectReturning: (Class) aClass;

/**
 * \internal
 * \brief Make a dictionary of collected objects.
 *
 * Make existing objects values and collected objects keys.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) PGTSCollectD;

/**
 * \internal
 * \brief Make a dictionary of collected objects.
 *
 * Make existing objects keys and collected objects values.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) PGTSCollectDK;

/**
 * \internal
 * \brief Visit each item.
 *
 * The first parameter after self and _cmd will be replaced with the visited object.
 * \param visitor The object that will be called.
 * \return An invocation recorder.
 */
- (id) PGTSVisit: (id) visitor;
@end


@interface NSSet (PGTSHOM) <PGTSHOM>
- (id) PGTSSelectFunction: (int (*)(id)) fptr;
- (id) PGTSSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end


@interface NSArray (PGTSHOM) <PGTSHOM>
- (NSArray *) PGTSReverse;
- (id) PGTSSelectFunction: (int (*)(id)) fptr;
- (id) PGTSSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end


@interface NSDictionary (PGTSHOM) <PGTSHOM>
/**
 * \internal
 * \brief Make a dictionary of objects collected from keys.
 *
 * Make existing objects values and collected objects keys.
 * \return An invocation recorder that creates an NSDictionary.
 */
- (id) PGTSKeyCollectD;

- (id) PGTSValueSelectFunction: (int (*)(id)) fptr;
- (id) PGTSValueSelectFunction: (int (*)(id, void*)) fptr argument: (void *) arg;
@end
