/** <abstract>WeavedDocPage represents a documentation page.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard, 
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHeader, DocMethod, DocFunction, DocMacro, DocConstant, DocCDataType, HtmlElement;

/** A documentation page that weaves various HTML, GSDoc, Markdown and plist 
files (usually provided on the command-line), into a new HTML representation  
based on the template tags embedded in the HTML or Markdown content.

You usually don't instantiate this class, but give the documentation input files 
to DocPageWeaver which will create new WeavedDocPages instances and return 
them.<br />
The returned pages can then be written to disk with -writeToURL: or 
their HTML representation retrieved with -HTMLString.

Subclasses can be written to customize the presentation and how the various 
elements (methods, macros, menu etc.) are laid out. Subclassing support is 
experimental and untested. */
@interface WeavedDocPage : NSObject 
{
	/* Source & Template */
	NSString *documentType;
	NSString *documentPath;
	NSString *documentContent;
	NSString *templateContent;
	NSString *menuContent;
	NSString *weavedContent;

	/* Doc Element Tree
	   Each doc element dictionaries is organized as described:
	   { taskOrGroupName = ( doc element 1, doc element 2 ...); ... } */
	DocHeader *header;
	NSMutableDictionary *subheaders;
	NSMutableDictionary *methods;
	NSMutableDictionary *functions;
	NSMutableDictionary *constants;
	NSMutableDictionary *macros;
	NSMutableDictionary *otherDataTypes;
}

/** @taskunit Initialization and Identity */

/** Initialises and returns a new documentation page that combines the given 
input files. */
- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath;

/** Returns the page name.

Can be used as a file name when saving the page, as <em>etdocgen</em> does. */
- (NSString *) name;

/** @taskunit Writing to File */

/** Writes the page to the given URL atomically. */
- (void) writeToURL: (NSURL *)outputURL;

/** @taskunit Page Building */

/** Sets the page header. */
- (void) setHeader: (DocHeader *)aHeader;
/** Returns the page header. */
- (DocHeader *) header;
/** Adds a subheader to the page.

Subheaders are expected to be positioned under the main header.<br />
A subheader can be used to regroup related documentation tree elements. */
- (void) addSubheader: (DocHeader *)aHeader;
/** Adds a method documentation to the page. */
- (void) addMethod: (DocMethod *)aMethod;
/** Adds a function documentation to the page. */
- (void) addFunction: (DocFunction *)aFunction;
/** Adds a constant documentation to the page. */
- (void) addConstant: (DocConstant *)aConstant;
/** Adds a macro documentation to the page. */
- (void) addMacro: (DocMacro *)aMacro;
/** Adds another data type documentation to the page. */
- (void) addOtherDataType: (DocCDataType *)anotherDataType;

/** @taskunit HTML Generation */

/** Returns a string representation of the whole page by weaving the input files. */
- (NSString *) HTMLString;
/** Returns the main page content rendered as an HtmlElement array, including 
elements such as <em>Instance Methods</em>,<em>Macros</em> etc.

Menu, navigation bar etc. are not present in the returned HTML representation 
unlike -HTMLString which does include them in its ouput. */
- (NSArray *) mainContentHTMLRepresentations;
/** <override-dummy />
Returns the HTML element tree into which the main header should be rendered.

By default, returns the -[DocHeader HTMLRepresentation].

Can be overriden to return a custom representation. */
- (HtmlElement *) HTMLRepresentationForHeader: (DocHeader *)aHeader;
/** Returns the given methods or functions rendered as a HTML element tree.

Both methods and functions are sorted by tasks before being rendered to HTML.

Task names are output with a &lt;h4&gt; header (&lt;h3&gt; when the title is nil).<br />
A title is also added, which uses a &lt;h3;&gt; header.

repSelector should usually be -HTMLRepresentation. Additional representations 
can be added to the DocElement subclasses such as 
-[DocHeader HTMLTOCRepresentation]. You can pass such a selector in argument to 
use a custom representation in the output.

See also DocSubroutine, DocMethod and DocFunction. */
- (HtmlElement *) HTMLRepresentationWithTitle: (NSString *) aTitle 
                                  subroutines: (NSDictionary *)subroutinesByTask
                   HTMLRepresentationSelector: (SEL)repSelector;
@end
