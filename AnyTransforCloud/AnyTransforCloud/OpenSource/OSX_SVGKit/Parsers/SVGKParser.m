//
//  SVGKParser.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGKParser.h"
#import <libxml/parser.h>

#import "SVGKParserSVG.h"

@class SVGKParserGradient;
#import "SVGKParserGradient.h"
@class SVGKParserPatternsAndGradients;
#import "SVGKParserPatternsAndGradients.h"
@class SVGKParserStyles;
#import "SVGKParserStyles.h"
@class SVGKParserDefsAndUse;
#import "SVGKParserDefsAndUse.h"
@class SVGKParserDOM;
#import "SVGKParserDOM.h"

#import "SVGDocument_Mutable.h" // so we can modify the SVGDocuments we're parsing

#import "Node.h"

#import "SVGKSourceString.h"
#import "SVGKSourceURL.h"
#import "CSSStyleSheet.h"
#import "StyleSheetList+Mutable.h"

@interface SVGKParser()
@property(nonatomic,retain, readwrite) SVGKSource* source;
@property(nonatomic,retain, readwrite) NSMutableArray* externalStylesheets;
@property(nonatomic,retain, readwrite) SVGKParseResult* currentParseRun;
@property(nonatomic,retain) NSString* defaultXMLNamespaceForThisParseRun;
@end

@implementation SVGKParser

@synthesize source;
@synthesize externalStylesheets;
@synthesize currentParseRun;
@synthesize defaultXMLNamespaceForThisParseRun;

@synthesize parserExtensions;
@synthesize parserKnownNamespaces;

static xmlSAXHandler SAXHandler;

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

#if 0
static NSString *NSStringFromLibxmlString (const xmlChar *string);
#else
#define NSStringFromLibxmlString(string) (string ? @((const char*)string) : nil)
#endif
static NSMutableDictionary *NSDictionaryFromLibxmlNamespaces (const xmlChar **namespaces, int namespaces_ct);
static NSMutableDictionary *NSDictionaryFromLibxmlAttributes (const xmlChar **attrs, int attr_ct);

static SVGKParser *parserThatWasMostRecentlyStarted;

+ (SVGKParseResult*) parseSourceUsingDefaultSVGKParser:(SVGKSource*) source;
{
	SVGKParser *parser = [[SVGKParser alloc] initWithSource:source];
	[parser addDefaultSVGParserExtensions];
	
	SVGKParseResult* result = [[parser parseSynchronously] retain];
	[parser release];
	return [result autorelease];
}


#define READ_CHUNK_SZ 1024*10

- (id)initWithSource:(SVGKSource *) s {
	self = [super init];
	if (self) {
		self.parserExtensions = [NSMutableArray array];
		
		self.source = s;
        self.externalStylesheets = nil;
		
		_storedChars = [NSMutableString new];
		_stackOfParserExtensions = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc {
	self.currentParseRun = nil;
	self.source = nil;
    self.externalStylesheets = nil;
	[_storedChars release];
	[_stackOfParserExtensions release];
   // [_parentOfCurrentNode release];
	self.parserExtensions = nil;
    self.parserKnownNamespaces = nil;
    self.defaultXMLNamespaceForThisParseRun = nil;
	[super dealloc];
}

#define AddParser(clazz) { \
clazz *parser = [[clazz alloc] init]; \
[self addParserExtension:parser];\
[parser release]; \
}

-(void) addDefaultSVGParserExtensions
{
    AddParser(SVGKParserSVG);
    AddParser(SVGKParserGradient);
    AddParser(SVGKParserPatternsAndGradients); // FIXME: this is a "not implemented yet" parser; now that we have gradients, it should be renamed!
    AddParser(SVGKParserStyles);
    AddParser(SVGKParserDefsAndUse);
    AddParser(SVGKParserDOM);
}

#undef AddParser

- (void) addParserExtension:(NSObject<SVGKParserExtension>*) extension
{
	// TODO: Should check for conflicts between this parser-extension and our existing parser-extensions, and issue warnings for any we find
	
	if( self.parserExtensions == nil )
	{
		self.parserExtensions = [NSMutableArray array];
	}
	
	if( [self.parserExtensions containsObject:extension])
	{
		DDLogVerbose(@"[%@] WARNING: attempted to add a ParserExtension that was already added = %@", [self class], extension);
		return;
	}
	
	[self.parserExtensions addObject:extension];
	
	if( self.parserKnownNamespaces == nil )
	{
		self.parserKnownNamespaces = [NSMutableDictionary dictionary];
	}
	for( NSString* parserNamespace in extension.supportedNamespaces )
	{
		NSMutableArray* extensionsForNamespace = (self.parserKnownNamespaces)[parserNamespace];
		if( extensionsForNamespace == nil )
		{
			extensionsForNamespace = [NSMutableArray array];
			(self.parserKnownNamespaces)[parserNamespace] = extensionsForNamespace;
		}
		
		[extensionsForNamespace addObject:extension];
	}
}

static FILE *desc;
static int
readPacket(char *mem, int size) {
    int res;
	
    res = (int)fread(mem, 1, size, desc);
    return(res);
}

- (SVGKParseResult*) parseSynchronously
{
	self.currentParseRun = [[SVGKParseResult new] autorelease];
	_parentOfCurrentNode = nil;
	[_stackOfParserExtensions removeAllObjects];
	parserThatWasMostRecentlyStarted = self;
	
	/*
	// 1. while (source has chunks of BYTES)
	// 2.   read a chunk from source, send to libxml
	// 3.   if libxml failed chunk, break
	// 4. return result
	*/
	
	NSInputStream* stream = source.stream;
	NSStreamStatus status = [stream streamStatus];
	if (status != NSStreamStatusOpen)
	{
		if (status == NSStreamStatusError)
			[currentParseRun addSourceError:[stream streamError]];
		[stream close];
		return  currentParseRun;
	}
	char buff[READ_CHUNK_SZ];
	
	xmlParserCtxtPtr ctx;
	ctx = xmlCreatePushParserCtxt(&SAXHandler, NULL, NULL, 0, NULL); // NEVER pass anything except NULL in second arg - libxml has a massive bug internally
	
	/* 
	 DDLogVerbose(@"[%@] WARNING: Substituting entities directly into document, c.f. http://www.xmlsoft.org/entities.html for why!", [self class]);
	 xmlSubstituteEntitiesDefault(1);
	xmlCtxtUseOptions( ctx,
					  XML_PARSE_DTDATTR  // default DTD attributes
					  | XML_PARSE_NOENT    // substitute entities
					  | XML_PARSE_DTDVALID // validate with the DTD
					  );
	*/
	
	if( ctx ) // if libxml init succeeds...
	{
		// 1. while (source has chunks of BYTES)
		// 2.   read a chunk from source, send to libxml
		NSInteger bytesRead = [stream read:(uint8_t*)&buff maxLength:READ_CHUNK_SZ];
		while( bytesRead > 0 )
		{
			int libXmlParserParseError = xmlParseChunk(ctx, buff, (int)bytesRead, 0);
			
			if( [currentParseRun.errorsFatal count] > 0 )
			{
				// 3.   if libxml failed chunk, break
				if( libXmlParserParseError > 0 )
				{
				DDLogVerbose(@"[%@] libXml reported internal parser error with magic libxml code = %i (look this up on http://xmlsoft.org/html/libxml-xmlerror.html#xmlParserErrors)", [self class], libXmlParserParseError );
				currentParseRun.libXMLFailed = YES;
				}
				else
				{
					DDLogWarn(@"[%@] SVG parser generated one or more FATAL errors (not the XML parser), errors follow:", [self class] );
					for( NSError* error in currentParseRun.errorsFatal )
					{
						DDLogWarn(@"[%@] ... FATAL ERRRO in SVG parse: %@", [self class], error );
					}
				}
				
				break;
			}
			
			bytesRead = [stream read:(uint8_t*)&buff maxLength:READ_CHUNK_SZ];
		}
	}
	
	[stream close]; // close the handle NO MATTER WHAT
    
	if (!currentParseRun.libXMLFailed)
		xmlParseChunk(ctx, NULL, 0, 1); // EOF
	
	xmlFreeParserCtxt(ctx);
	
	// 4. return result
	return currentParseRun;
}

/** ADAM: use this for a higher-performance, *non-blocking* parse
 (when someone upgrades this class and the interface to support non-blocking parse)
// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data 
{
	// Process the downloaded chunk of data.
	xmlParseChunk(_xmlParserContext, (const char *)[data bytes], [data length], 0);//....Getting Exception at this line.
}
 */


- (SVGKSource *)loadCSSFrom:(NSString *)href
{
    SVGKSource *cssSource = nil;
    if( [href hasPrefix:@"http"] )
    {
        NSURL *url = [NSURL URLWithString:href];
        cssSource = [SVGKSourceURL sourceFromURL:url];
    }
    else
    {
        cssSource = [self.source sourceFromRelativePath:href];
    }
    
    if( cssSource == nil )
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:href];
        NSString *cssText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        if( cssText == nil )
        {
            DDLogWarn(@"[%@] Unable to find external CSS file '%@'", [self class], href );
        }
        else
        {
            cssSource = [SVGKSourceString sourceFromContentsOfString:cssText];
        }
    }
    
    return cssSource;
}

- (NSString *)stringFromSource:(SVGKSource *) src
{
    static uint8_t byteBuffer[4096];
    NSInteger bytesRead;
    NSString *result = nil;
    do
    {
        bytesRead = [src.stream read:byteBuffer maxLength:4096];
        NSString *read = [[[NSString alloc] initWithBytes:byteBuffer length:bytesRead encoding:NSUTF8StringEncoding] autorelease];
        if( result )
            result = [result stringByAppendingString:read];
        else
            result = read;
    } while (bytesRead > 0);
    return result;
}

- (void)handleProcessingInstruction:(NSString *)target withData:(NSString *) data
{
    if( [@"xml-stylesheet" isEqualToString:target] && ( [data rangeOfString:@"type=\"text/css\""].location != NSNotFound || [data rangeOfString:@"type="].location == NSNotFound ) )
    {
        NSRange startHref = [data rangeOfString:@"href=\""];
        if( startHref.location != NSNotFound )
        {
            NSUInteger startIndex = startHref.location + startHref.length;
            NSRange endHref = [data rangeOfString:@"\"" options:0 range:NSMakeRange(startIndex, data.length - startIndex)];
            if( startHref.location != NSNotFound )
            {
                NSString *href = [data substringWithRange:NSMakeRange(startIndex, endHref.location - startIndex)];
                SVGKSource* cssSource = [self loadCSSFrom:href];
                
                if( cssSource != nil )
                {
                    NSString *cssText = [self stringFromSource:cssSource];
                    CSSStyleSheet* parsedStylesheet = [[[CSSStyleSheet alloc] initWithString:cssText] autorelease];
                    
                    if( currentParseRun.parsedDocument.rootElement == nil )
                    {
                        if( self.externalStylesheets == nil )
                            self.externalStylesheets = [[[NSMutableArray alloc] init] autorelease];
                        [self.externalStylesheets addObject:parsedStylesheet];
                    }
                    else
                    {
                        [currentParseRun.parsedDocument.rootElement.styleSheets.internalArray addObject:parsedStylesheet];
                    }
                }
            }
        }
    }
}

- (void)addExternalStylesheetsToRootElement {
    
    if( self.externalStylesheets != nil )
    {
        [currentParseRun.parsedDocument.rootElement.styleSheets.internalArray addObjectsFromArray:self.externalStylesheets];
        self.externalStylesheets = nil;
    }
}

static void processingInstructionSAX (void * ctx,
                                         const xmlChar * target,
                                         const xmlChar * data)
{
    SVGKParser *self = parserThatWasMostRecentlyStarted;
    
    NSString *stringTarget = NSStringFromLibxmlString(target);
	NSString *stringData = NSStringFromLibxmlString(data);
    
    [self handleProcessingInstruction:stringTarget withData:stringData];
}

- (void)handleStartElement:(NSString *)name namePrefix:(NSString*)prefix namespaceURI:(NSString*) XMLNSURI attributeObjects:(NSMutableDictionary *) attributeObjects
{
	BOOL parsingRootTag = FALSE;
	
	if( _parentOfCurrentNode == nil )
		parsingRootTag = TRUE;
	
	if( ! parsingRootTag && _storedChars.length > 0 )
	{
		/** Send any partially-parsed text data into the old node that is now the parent node,
		 then change the "storing chars" flag to fit the new node */
		
		Text *tNode = [[Text alloc] initWithValue:_storedChars];
		
		[_parentOfCurrentNode appendChild:tNode];
		[tNode release];
		[_storedChars setString:@""];
	}
	
	/**
	 Search for a Parser Extension to handle this XML tag ...
	 
	 (most tags are handled by the default SVGParserSVG - but if you have other XML embedded in your SVG, you'll
	 have custom parser extentions too)
	 */
	NSObject<SVGKParserExtension>* defaultParserForThisNamespace = nil;
	NSObject<SVGKParserExtension>* defaultParserForEverything = nil;
	for( NSObject<SVGKParserExtension>* subParser in self.parserExtensions )
	{
		// TODO: rather than checking for the default parser on every node, we should stick them in a Dictionar at the start and re-use them when needed
		/**
		 First: check if this parser is a "default" / fallback parser. If so, skip it, and only use it
		 AT THE VERY END after checking all other parsers
		 */
		BOOL shouldBreakBecauseParserIsADefault = FALSE;
		
		if( [[subParser supportedNamespaces] count] == 0 )
		{
			defaultParserForEverything = subParser;
			shouldBreakBecauseParserIsADefault = TRUE;
		}
		
		if( [[subParser supportedNamespaces] containsObject:XMLNSURI]
		   && [[subParser supportedTags] count] == 0 )
		{
			defaultParserForThisNamespace = subParser;
			shouldBreakBecauseParserIsADefault = TRUE;
		}
		
		if( shouldBreakBecauseParserIsADefault )
			continue;
			
		/**
		 Now we know it's a specific parser, check if it handles this particular node
		 */
		if( [[subParser supportedNamespaces] containsObject:XMLNSURI]
		   && [[subParser supportedTags] containsObject:name] )
		{
			[_stackOfParserExtensions addObject:subParser];
			
			/** Parser Extenstion creates a node for us */
			Node* subParserResult = [subParser handleStartElement:name document:source namePrefix:prefix namespaceURI:XMLNSURI attributes:attributeObjects parseResult:self.currentParseRun parentNode:_parentOfCurrentNode];
			
#if DEBUG_XML_PARSER
			DDLogVerbose(@"[%@] tag: <%@:%@> id=%@ -- handled by subParser: %@", [self class], prefix, name, ([((Attr*)[attributeObjects objectForKey:@"id"]) value] != nil?[((Attr*)[attributeObjects objectForKey:@"id"]) value]:@"(none)"), subParser );
#endif
			
			/** Add the new (partially parsed) node to the parent node in tree
			 
			 (need this for some of the parsing, later on, where we need to be able to read up
			 the tree to make decisions about the data - this is REQUIRED by the SVG Spec)
			 */
			[_parentOfCurrentNode appendChild:subParserResult]; // this is a DOM method: should NOT have side-effects
			_parentOfCurrentNode = subParserResult;
			
			if( parsingRootTag )
			{
				currentParseRun.parsedDocument.rootElement = (SVGSVGElement*) subParserResult;
                [self addExternalStylesheetsToRootElement];
			}
			
			return;
		}
	}
	
	/**
	 IF we had a specific matching parser, we would have returned already.
	 
	 Since we haven't, it means we have to try the default parsers instead
	 */
	NSObject<SVGKParserExtension>* eventualParser = defaultParserForThisNamespace != nil ? defaultParserForThisNamespace : defaultParserForEverything;
	NSAssert( eventualParser != nil, @"Found a tag (prefix:%@ name:%@) that was rejected by all the parsers available. Perhaps you forgot to include a default parser (usually: SVGKParserDOM, which will handle any / all XML tags)", prefix, name );
	
	DDLogVerbose(@"[%@] WARN: found a tag with no namespace parser: (</%@>), using default parser(%@)", [self class], name, eventualParser );
	
	
	[_stackOfParserExtensions addObject:eventualParser];
	
	/** Parser Extenstion creates a node for us */
	Node* subParserResult = [eventualParser handleStartElement:name document:source namePrefix:prefix namespaceURI:XMLNSURI attributes:attributeObjects parseResult:self.currentParseRun parentNode:_parentOfCurrentNode];
	
#if DEBUG_XML_PARSER
	DDLogVerbose(@"[%@] tag: <%@:%@> id=%@ -- handled by subParser: %@", [self class], prefix, name, ([((Attr*)[attributeObjects objectForKey:@"id"]) value] != nil?[((Attr*)[attributeObjects objectForKey:@"id"]) value]:@"(none)"), eventualParser );
#endif
	
	/** Add the new (partially parsed) node to the parent node in tree
	 
	 (need this for some of the parsing, later on, where we need to be able to read up
	 the tree to make decisions about the data - this is REQUIRED by the SVG Spec)
	 */
	[_parentOfCurrentNode appendChild:subParserResult]; // this is a DOM method: should NOT have side-effects
	_parentOfCurrentNode = subParserResult;
	
		
	if( parsingRootTag )
	{
		currentParseRun.parsedDocument.rootElement = (SVGSVGElement*) subParserResult;
        [self addExternalStylesheetsToRootElement];
	}
	
	return;
}


static void startElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix,
							 const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
							 int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
	
	SVGKParser *self = parserThatWasMostRecentlyStarted;
	
	NSString *stringLocalName = NSStringFromLibxmlString(localname);
	NSString *stringPrefix = NSStringFromLibxmlString(prefix);
	NSMutableDictionary *namespacesByPrefix = NSDictionaryFromLibxmlNamespaces(namespaces, nb_namespaces); // TODO: need to do something with this; this is the ONLY point at which we discover the "xmlns:" definitions in the SVG doc! See below for a temp fix
	NSMutableDictionary *attributeObjects = NSDictionaryFromLibxmlAttributes(attributes, nb_attributes);
	NSString *stringURI = NSStringFromLibxmlString(URI);
	
	/** Set a default Namespace for rest of this document if one is included in the attributes */
	if( self.defaultXMLNamespaceForThisParseRun == nil )
	{
		NSString* newDefaultNamespace = [namespacesByPrefix valueForKey:@""];
		if( newDefaultNamespace != nil )
		{
			self.defaultXMLNamespaceForThisParseRun = newDefaultNamespace;
		}
	}
	
	if( stringURI == nil
	&& self.defaultXMLNamespaceForThisParseRun != nil )
	{
		/** Apply the default XML NS to this tag as if it had been typed in.
		 
		 e.g. if somewhere in this doc the author put:
		 
		 <svg xmlns="blah">
		 
		 ...then any time we find a tag that HAS NO EXPLICIT NAMESPACE, we act as if it had that one.
		 */
		
		stringURI = self.defaultXMLNamespaceForThisParseRun;
	}
	
	for( Attr* newAttribute in attributeObjects.allValues )
	{
		if( newAttribute.namespaceURI == nil )
			newAttribute.namespaceURI = self.defaultXMLNamespaceForThisParseRun;
	}
	
	/**
	 This appears to be a major bug in libxml: "xmlns:blah="blah"" is treated as a namespace declaration - but libxml
	 FAILS to report it as an attribute (according to the XML spec, it appears to be "both" of those things?)
	 
	 ...but I could be wrong. The XML definition of Namespaces is badly written and missing several key bits of info
	 (I have inferred the "both" status from the definition of XML's Node class, which raises an error on setting
	 Node.prefix "if the node is an attribute, and it's in the xmlns namespace ... and ... and" -- which implies to me
	 that attributes can be xmlns="blah" definitions)
	 
	 ... UPDATE: I have found confirming evidence in the "http://www.w3.org/2000/xmlns/" namespace itself. Visit that URL! It has docs...
	 
	 
	 NB: this bug / issue was irrelevant until we started trying to export SVG documents from memory back to XML strings,
	 at which point: we need this info! Or else we end up substantially changing the incoming SVG :(.
	 
	 So:
	 
	 Add any namespace declarations to the attributes dictionary:
	 */
	for( NSString* prefix in namespacesByPrefix )
	{
		NSString* namespace = [namespacesByPrefix objectForKey:prefix];
		
		/** NB this happens *AFTER* setting default namespaces for all attributes - the xmlns: attributes are required by the XML
		 spec to all live in a special magical namespace AND to all use the same prefix of "xmlns" - no other is allowed!
		 */
		Attr* newAttributeFromNamespaceDeclaration = [[[Attr alloc] initWithNamespace:@"http://www.w3.org/2000/xmlns/" qualifiedName:[NSString stringWithFormat:@"xmlns:%@", prefix] value:namespace] autorelease];
		
		[attributeObjects setObject:newAttributeFromNamespaceDeclaration forKey:newAttributeFromNamespaceDeclaration.nodeName];
	}
	
	/**
	 TODO: temporary workaround to PRETEND that all namespaces are always defined;
	 this is INCORRECT: namespaces should be UNdefined once you close the parent tag that defined them (I think?)
	 */
	for( NSString* prefix in namespacesByPrefix )
	{
		NSString* uri = namespacesByPrefix[prefix];
		
        // special string we put in earlier to indicate zero-length / "default" prefix
        (self.currentParseRun.namespacesEncountered)[[prefix isEqualToString:@""] ? [NSNull null] : prefix] = uri;
	}
	
#if DEBUG_XML_PARSER
#if DEBUG_VERBOSE_LOG_EVERY_TAG
	DDLogCWarn(@"[%@] DEBUG_VERBOSE: <%@%@> (namespace URL:%@), attributes: %i", [self class], [NSString stringWithFormat:@"%@:",stringPrefix], name, stringURI, nb_attributes );
#endif
#endif
	
#if DEBUG_VERBOSE_LOG_EVERY_TAG
	if( prefix2 == nil )
	{
		/* The XML library allows this, although it's very unhelpful when writing application code */
		
		/* Let's find out what namespaces DO exist... */
		
		/*
		 
		 TODO / DEVELOPER WARNING: the library says nb_namespaces is the number of elements in the array,
		 but it keeps returning nil pointer (not always, but often). WTF? Not sure what we're doing wrong
		 here, but commenting it out for now...
		 
		if( nb_namespaces > 0 )
		{
			for( int i=0; i<nb_namespaces; i++ )
			{
				DDLogCWarn(@"[%@] DEBUG: found namespace [%i] : %@", [self class], i, namespaces[i] );
			}
		}
		else
			DDLogCWarn(@"[%@] DEBUG: there are ZERO namespaces!", [self class] );
		 */
	}
#endif
	
	if( stringURI == nil && stringPrefix == nil )
	{
		DDLogCWarn(@"[%@] WARNING: Your input SVG contains tags that have no namespace, and your document doesn't define a default namespace. This is always incorrect - it means some of your SVG data will be ignored, and usually means you have a typo in there somewhere. Tag with no namespace: <%@>", [self class], stringLocalName );
	}
		  
	[self handleStartElement:stringLocalName namePrefix:stringPrefix namespaceURI:stringURI attributeObjects:attributeObjects];
}

- (void)handleEndElement:(NSString *)name {
	//DELETE DEBUG DDLogVerbose(@"ending element, name = %@", name);
	
	
	NSObject* lastobject = [_stackOfParserExtensions lastObject];
	
	[_stackOfParserExtensions removeLastObject];
	
	NSObject<SVGKParserExtension>* parser = (NSObject<SVGKParserExtension>*)lastobject;
//	NSObject<SVGKParserExtension>* parentParser = [_stackOfParserExtensions lastObject];
	
#if DEBUG_XML_PARSER
#if DEBUG_VERBOSE_LOG_EVERY_TAG
	DDLogVerbose(@"[%@] DEBUG-PARSER: ended tag (</%@>), handled by parser (%@) with parent parsed by %@", [self class], name, parser, parentParser );
#endif
#endif
	
	/**
	 At this point, the "parent of current node" is still set to the node we're
	 closing - because we haven't finished closing it yet
	 */
	if( _storedChars.length > 0 )
	{
		/** Send any parsed text data into the node-we're-closing */
		
		Text *tNode = [[Text alloc] initWithValue:_storedChars];
		
		[_parentOfCurrentNode appendChild:tNode];
		[tNode release];
		[_storedChars setString:@""];
	}
	
	[parser handleEndElement:_parentOfCurrentNode document:source parseResult:self.currentParseRun];
	
	/** Update the _parentOfCurrentNode to point to the parent of the node we just closed...
	 */
	_parentOfCurrentNode = _parentOfCurrentNode.parentNode;
}

static void	endElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
	SVGKParser *self = parserThatWasMostRecentlyStarted;
	
	[self handleEndElement:NSStringFromLibxmlString(localname)];
}

- (void)handleFoundCharacters:(const xmlChar *)chars length:(int)len {
    NSString *stringToAppend = [[NSString alloc] initWithBytes:chars length:len encoding:NSUTF8StringEncoding];
    
    [_storedChars appendString:stringToAppend];
    [stringToAppend release];
}

static void cDataFoundSAX(void *ctx, const xmlChar *value, int len)
{
    SVGKParser *self = parserThatWasMostRecentlyStarted;
	
	[self handleFoundCharacters:value length:len];
}

static void	charactersFoundSAX (void *ctx, const xmlChar *chars, int len) {
	SVGKParser *self = parserThatWasMostRecentlyStarted;
	
	[self handleFoundCharacters:chars length:len];
}

static void errorEncounteredSAX (void *ctx, const char *msg, ...) {
    va_list va;
    NSString *errStr = nil;
	SVGKParser *self = parserThatWasMostRecentlyStarted;
    va_start(va, msg);
    errStr = [[NSString alloc] initWithFormat:@(msg) arguments:va];
    va_end(va);
    
	SVGKParseResult* parseResult = self.currentParseRun;
    
    DDLogCWarn(@"Error encountered during parse: %@", errStr);
	[parseResult addSAXError:[NSError errorWithDomain:@"SVG-SAX" code:1 userInfo:@{NSLocalizedDescriptionKey: errStr}]];
    [errStr release];
}

static void	unparsedEntityDeclaration(void * ctx, 
									 const xmlChar * name, 
									 const xmlChar * publicId, 
									 const xmlChar * systemId, 
									 const xmlChar * notationName)
{
	DDLogCWarn(@"Error: unparsed entity Decl");
}

static void structuredError		(void * userData, 
									 xmlErrorPtr error)
{
	/**
	 XML_ERR_WARNING = 1 : A simple warning
	 XML_ERR_ERROR = 2 : A recoverable error
	 XML_ERR_FATAL = 3 : A fatal error
	 */
	xmlErrorLevel errorLevel = error->level;
	
	NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@(error->message), NSLocalizedDescriptionKey,
									@(error->line), @"lineNumber",
									@(error->int2), @"columnNumber",
									nil];
	
	if( error->str1 )
		[details setValue:@(error->str1) forKey:@"bonusInfo1"];
	if( error->str2 )
		[details setValue:@(error->str2) forKey:@"bonusInfo2"];
	if( error->str3 )
		[details setValue:@(error->str3) forKey:@"bonusInfo3"];
	
	NSError* objcError = [NSError errorWithDomain:[@(error->domain) stringValue] code:error->code userInfo:details];
	
	SVGKParser *self = parserThatWasMostRecentlyStarted;
	SVGKParseResult* parseResult = self.currentParseRun;
	switch( errorLevel )
	{
		case XML_ERR_WARNING:
		{
			[parseResult addParseWarning:objcError];
		}break;
			
		case XML_ERR_ERROR:
		{
			[parseResult addParseErrorRecoverable:objcError];
		}break;
			
		case XML_ERR_FATAL:
		{
			[parseResult addParseErrorFatal:objcError];
		}
        default:
            break;
	}
	
}

static xmlSAXHandler SAXHandler = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    processingInstructionSAX,   /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    cDataFoundSAX,              /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    structuredError,                       /* serror */
};

#pragma mark -
#pragma mark Utility

#if 0
static NSString *NSStringFromLibxmlString (const xmlChar *string) {
	if( string == NULL ) // Yes, Apple requires we do this check!
		return nil;
	else
		return [NSString stringWithUTF8String:(const char *) string];
}
#endif

static NSMutableDictionary *NSDictionaryFromLibxmlNamespaces (const xmlChar **namespaces, int namespaces_ct)
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:namespaces_ct];
	
	for (int i = 0; i < namespaces_ct * 2; i += 2)
	{
		NSString* prefix = NSStringFromLibxmlString(namespaces[i]);
		NSString* uri = NSStringFromLibxmlString(namespaces[i+1]);
		
		if( prefix == nil )
			prefix = @""; // Special case: Apple dictionaries can't handle null keys
		
		dict[prefix] = uri;
	}
	
	return [dict autorelease];
}


static NSMutableDictionary *NSDictionaryFromLibxmlAttributes (const xmlChar **attrs, int attr_ct) {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:attr_ct];
	
	for (int i = 0; i < attr_ct * 5; i += 5) {
		const char *begin = (const char *) attrs[i + 3];
		const char *end = (const char *) attrs[i + 4];
		size_t vlen = strlen(begin) - strlen(end);
				
		NSString* localName = NSStringFromLibxmlString(attrs[i]);
		NSString* prefix = NSStringFromLibxmlString(attrs[i+1]);
		NSString* uri = NSStringFromLibxmlString(attrs[i+2]);
		NSString* value = [[NSString alloc] initWithBytes:begin length:vlen encoding:NSUTF8StringEncoding];
		
		NSString* qname = (prefix == nil) ? localName : [NSString stringWithFormat:@"%@:%@", prefix, localName];
		
		Attr* newAttribute = [[Attr alloc] initWithNamespace:uri qualifiedName:qname value:value];
		
		dict[qname] = newAttribute;
        [newAttribute release];
        [value release];
	}
	
	return [dict autorelease];
}

#define MAX_ACCUM 256
#define MAX_NAME 256

+(NSDictionary *) NSDictionaryFromCSSAttributes: (Attr*) styleAttribute {
	
	if( styleAttribute == nil )
	{
		DDLogCWarn(@"[%@] WARNING: asked to convert an empty CSS string into a CSS dictionary; returning empty dictionary", [self class] );
		return @{};
	}
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	const char *cstr = [styleAttribute.value UTF8String];
	size_t len = strlen(cstr);
	
	char name[MAX_NAME];
	bzero(name, MAX_NAME);
	
	char accum[MAX_ACCUM];
	bzero(accum, MAX_ACCUM);
	
	size_t accumIdx = 0;
	
	for (size_t n = 0; n <= len; n++) {
		char c = cstr[n];
		
		if (c == '\n' || c == '\t' || c == ' ') {
			continue;
		}
		
		if (c == ':') {
			strcpy(name, accum);
			name[accumIdx] = '\0';
			
			bzero(accum, MAX_ACCUM);
			accumIdx = 0;
			
			continue;
		}
		else if (c == ';' || c == '\0') {
			accum[accumIdx] = '\0';
			
			Attr* newAttribute = [[Attr alloc] initWithNamespace:styleAttribute.namespaceURI qualifiedName:@(name) value:@(accum)];
			
			dict[newAttribute.localName] = newAttribute;
			[newAttribute release];
            
			bzero(name, MAX_NAME);
			
			bzero(accum, MAX_ACCUM);
			accumIdx = 0;
			
			continue;
		}
		
		accum[accumIdx++] = c;
	}
	
	return [dict autorelease];
}

@end