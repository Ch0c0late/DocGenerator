/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocHeader.h"
#import "DocIndex.h"
#import "HtmlElement.h"

@implementation DocHeader

@synthesize title, abstract, authors, overview, fileOverview , group;
@synthesize className, superclassName, protocolName, categoryName, adoptedProtocolNames, declaredIn;

- (id) init
{
	SUPERINIT;
	authors = [NSMutableArray new];
	adoptedProtocolNames = [NSMutableArray new];
	return self;
}

- (void) dealloc
{
	[title release];
	[abstract release];
	[authors release];
	[overview release];
	[fileOverview release];

	[className release];
	[protocolName release];
	[categoryName release];
	[superclassName release];
	[adoptedProtocolNames release];
	[declaredIn release];

	[group release];

	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone
{
	DocHeader *copy = [super copyWithZone: aZone];

	copy->authors = [authors mutableCopyWithZone: aZone];

	/* We are not interested in copying the properties that would need to be  
	   reset to nil. e.g. when weaving a new page per class and the classes 
	   belongs to a single gsdoc file.

	ASSIGN(copy->className, className);
	ASSIGN(copy->protocolName, protocolName);
	ASSIGN(copy->categoryName, categoryName);
	ASSIGN(copy->superClassName, superClassName);
	copy->adoptedProtocolNames = [adoptedProtocolNames mutableCopyWithZone: aZone];*/

	copy->adoptedProtocolNames = [[NSMutableArray alloc] init];
	ASSIGN(copy->abstract, abstract);
	ASSIGN(copy->overview, overview);
	ASSIGN(copy->title, title);
	ASSIGN(copy->group, group);

	return copy;
}

- (NSString *) name
{
	if ([super name] != nil)
	{
		return [[[super name] componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] 
			componentsJoinedByString: @""];
	}
	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		return className;
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		return [NSString stringWithFormat: @"%@+%@", className, categoryName];
	}
	if (protocolName != nil)
	{
		return [NSString stringWithFormat: @"_%@", protocolName];	
	}

	return nil;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
			title, className];
}

- (NSArray *) authors
{
	return AUTORELEASE([authors copy]);
}

- (void) addAuthor: (NSString *)aName
{
	if (aName != nil)
		[authors addObject: aName];
}

- (NSString *) group
{
	if (IS_NIL_OR_EMPTY_STR(group) == NO)
	{
		return group;
	}
	else
	{
		return @"Misc";
	}
}

- (NSArray *) adoptedProtocolNames
{
	return AUTORELEASE([adoptedProtocolNames copy]);
}

- (void) addAdoptedProtocolName: (NSString *)aName
{
	[adoptedProtocolNames addObject: aName];
}

- (void) setOverview: (NSString *)aDescription
{
	NSString *validDesc = aDescription;

	if ([aDescription isEqual: [[self class] forthcomingDescription]])
	{
		validDesc = nil;
	}

	ASSIGN(overview, validDesc);
	// FIXME: redundancy
	[self setFilteredDescription: aDescription];
}

- (HtmlElement *) HTMLOverviewRepresentation
{
	H hOverview = [DIV id: @"overview" with: [H3 with: @"Overview"]];
	BOOL noOverview = (IS_NIL_OR_EMPTY_STR(fileOverview) && IS_NIL_OR_EMPTY_STR(overview));

	if (noOverview)
		return [HtmlElement blankElement];

	if (fileOverview != nil)
	{
		NSString *fo = [NSString stringWithContentsOfFile: fileOverview 
		                                         encoding: NSUTF8StringEncoding 
		                                            error: NULL];
		[hOverview and: fo];
	}
	else if (overview != nil)
	{
		[hOverview and: [P with: [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]]]];
	}

	return hOverview;
}

- (HtmlElement *) HTMLRepresentation
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H h_title = [DIV id: @"classname"];
	if (title)
	{
		[h_title with: [H2 with: title]];
	}

	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: className and: @" : " and: [docIndex linkForClassName: superclassName]];
	}
	if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		[h_title with: [docIndex linkForClassName: className] 
		          and: @" (" and: categoryName and: @")"];
	}
	if (protocolName != nil)
	{
		[h_title with: protocolName];	
	}

	/* Insert adopted protocols */
	if ([adoptedProtocolNames isEmpty] == NO)
	{
		BOOL isFirstProtocol = YES;
		
		[h_title addText: @" &lt;"];
		
		for (NSString *adoptedProtocol in adoptedProtocolNames)
		{
			if (isFirstProtocol == NO)
				[h_title addText: @", "];
			
			[h_title addText: [docIndex linkForProtocolName: adoptedProtocol]];
			isFirstProtocol = NO;
		}
		[h_title addText: @"&gt;"];
	}

	/* Build authors and declared in table */
	H table = TABLE;
	H tdAuthors = TD;

	for (NSString *author in authors)
	{
		[tdAuthors with: author and: @" "];
	}
	if ([authors isEmpty] == NO)
	{
		[table add: [TR with: [TH with: @"Authors"] and: tdAuthors]];
	}
	if (declaredIn != nil)
	{
		[table add: [TR with: [TH with: @"Declared in"] and: [TD with: declaredIn]]];
	}

	NSString *formattedAbstract = [self insertLinksWithDocIndex: docIndex forString: abstract];
	// TODO: Could be better not to insert an empty table when authors is empty and declared is nil
	H hMeta = [DIV id: @"meta" with: [P id: @"metadesc" with: [EM with: formattedAbstract]] 
	                           and: table];

	/* Pack title, meta and overview in a header html element */
	H hOverview = [self HTMLOverviewRepresentation];
	H hHeader = [DIV id: @"header" with: h_title and: hMeta and: hOverview];

	if ([hOverview isEqual: [HtmlElement blankElement]])
	{
		return hHeader;
	}

	return [[HtmlElement blankElement] with: hHeader and: HR];
}

// TODO: Use correct span class names...
- (HtmlElement *) HTMLTOCRepresentation
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H hEntryName = [SPAN class: @"symbolName" with: [SPAN class: @"collapsedIndicator"]];

	/* Insert either class, category or protocol as main symbol */
	if (className != nil && categoryName == nil)
	{
		ETAssert(protocolName == nil);
		[hEntryName with: [docIndex linkForClassName: className]];
		// TODO: When expanded, we should show...
		//[hEntryName with: className and: @" : " and: [docIndex linkForClassName: superClassName]];
	}
	else if (categoryName != nil)
	{
		ETAssert(protocolName == nil);
		NSString *linkName = [NSString stringWithFormat: @"%@ (%@)", className, categoryName];
		NSString *symbol = [NSString stringWithFormat: @"%@(%@)", className, categoryName];

		[hEntryName with: [docIndex linkWithName: linkName 
		                           forSymbolName: symbol
		                                  ofKind: @"categories"]];
	}
	else if (protocolName != nil)
	{
		NSString *linkName = [NSString stringWithFormat: @"&lt;%@&gt;", protocolName];

		[hEntryName with: [docIndex linkWithName: linkName 
		                           forSymbolName: protocolName 
		                                  ofKind: @"protocols"]];	
	}

	NSString *description = [self HTMLDescriptionWithDocIndex: [DocIndex currentIndex]];
	H hEntryDesc = [DIV class: @"symbolDescription" with: [P with: description]];

	return [DIV class: @"symbol" with: [DL with: [DT with: hEntryName]
                                            and: [DD with: hEntryDesc]]];
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
	if ([elementName isEqualToString: @"head"]) /* Opening tag */
	{
		BEGINLOG();
	}
	else if ([elementName isEqualToString: @"author"]) 
	{
		[self addAuthor: [attributeDict objectForKey: @"name"]];
	}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"abstract"])
	{
		[self setAbstract: trimmed];
		CONTENTLOG();
	}
	else if ([elementName isEqualToString: @"title"]) 
	{ 
		[self setTitle: trimmed];
	}
	else if ([elementName isEqualToString: @"head"]) /* Closing tag */
	{
		[[parser weaver] weaveHeader: self];

		ENDLOG2(title, className);
	}
}

@end
