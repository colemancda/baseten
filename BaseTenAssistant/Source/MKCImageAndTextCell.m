//
// MKCImageAndTextCell.m
// BaseTen Setup
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

#import "MKCImageAndTextCell.h"


@implementation MKCImageAndTextCell
@synthesize image = mImage;

- (id) init 
{
    if ((self = [super init])) 
	{
        [self setLineBreakMode: NSLineBreakByTruncatingTail];
    }
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSRect) titleRectForBounds: (NSRect) bounds
{
	NSRect retval = [super titleRectForBounds: bounds];
	retval.origin.y += 2.0;
	retval.size.height -= 2.0;
	if (nil != [self image])
	{
		NSRect imageRect = [self imageRectForBounds: bounds];
		CGFloat delta = 2 * (imageRect.origin.x - bounds.origin.x);
		delta += imageRect.size.width;
		retval.origin.x += delta;
		retval.size.width -= delta;
	}
	return retval;
}

- (NSRect) imageRectForBounds: (NSRect) bounds
{
	NSSize imageSize = [[self image] size];
	CGFloat delta = MIN (bounds.size.width - imageSize.width, bounds.size.height - imageSize.height) / 2.0;
	delta = MAX (1.5, delta);
	
	NSRect retval = NSInsetRect (bounds, delta, delta);
	retval.size.width  = MIN (retval.size.width,  imageSize.width);
	retval.size.height = MIN (retval.size.height, imageSize.height);
	return retval;
}

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView
{
	NSRect titleFrame = [self titleRectForBounds: cellFrame];
	[super drawWithFrame: titleFrame inView: controlView];
	if (nil != [self image])
	{
		NSRect imageRect = [self imageRectForBounds: cellFrame];
		NSPoint origin = imageRect.origin;
		if ([controlView isFlipped])
			origin.y += imageRect.size.height;
		imageRect.origin = NSZeroPoint;
		[[self image] compositeToPoint: origin fromRect: imageRect operation: NSCompositeSourceOver];		
	}
}
@end
