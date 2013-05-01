/*
	Copyright (C) 2013 Muhammad Hussein Nasrollahpour

	Author:  Muhammad Hussein Nasrollahpour <iapplechocolate@me.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "DocSourceCodeParser.h"
#import "DocHeader.h"
#import "DocMethod.h"

@implementation DocSourceCodeParser

- (id) init
{
	return [self initWithSourceFile: nil];
}

- (id) initWithSourceFile: (NSString *)aSourceCodePath
{
	NILARG_EXCEPTION_TEST(aSourceCodePath);

	SUPERINIT;
	sourceCollection = [SCKSourceCollection new];
	sourceFile = (SCKClangSourceFile *)[sourceCollection sourceFileForPath: aSourceCodePath];
	return self;
}

- (void) dealloc
{
	sourceCollection = nil;
	sourceFile = nil;
}

- (void) parseAndWeave
{
	for (SCKClass *class in [sourceFile classes])
	{
		DocHeader *header = [DocHeader new];

		[header setClassName: [class name]];
		[pageWeaver weaveHeader: header];

		[pageWeaver weaveClassNamed: [class name]
		             superclassName: [[class superclass] name]];

		for (SCKMethod *method in [class methods])
		{
			DocMethod *docMethod = [DocMethod new];
			[pageWeaver weaveMethod: docMethod];
			// FIXME: [docMethod parseProgramComponent: method];
		}
	}
}

- (id <DocWeaving>)weaver
{
	return pageWeaver;
}

- (void)setWeaver: (id <DocWeaving>)aDocWeaver
{
	pageWeaver = aDocWeaver;
}

@end
