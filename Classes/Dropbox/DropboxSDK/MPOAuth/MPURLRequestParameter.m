//
//  MPURLParameter.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPURLRequestParameter.h"
#import "NSString+URLEscapingAdditions.h"

@implementation MPURLRequestParameter

+ (NSArray *)parametersFromString:(NSString *)inString {
	NSMutableArray *foundParameters = [NSMutableArray arrayWithCapacity:10];
	NSScanner *parameterScanner = [[NSScanner alloc] initWithString:inString];
	NSString *thisName = nil;
	NSString *thisValue = nil;
	MPURLRequestParameter *currentParameter = nil;
	
	while (![parameterScanner isAtEnd]) {
		thisName = nil;
		thisValue = nil;
		
		[parameterScanner scanUpToString:@"=" intoString:&thisName];
		[parameterScanner scanString:@"=" intoString:NULL];
		[parameterScanner scanUpToString:@"&" intoString:&thisValue];
		[parameterScanner scanString:@"&" intoString:NULL];		
		
		currentParameter = [[MPURLRequestParameter alloc] init];
		currentParameter.name = thisName;
		currentParameter.value = [thisValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[foundParameters addObject:currentParameter];
		
		[currentParameter release];
	}
	
	[parameterScanner release];
	
	return foundParameters;
}

+ (NSArray *)parametersFromDictionary:(NSDictionary *)inDictionary {
	NSMutableArray *parameterArray = [[NSMutableArray alloc] init];
	MPURLRequestParameter *aURLParameter = nil;
	
	NSArray *keys = [inDictionary allKeys];
	for (int i=0; i<[keys count]; i++) {
		aURLParameter = [[MPURLRequestParameter alloc] init];
		aURLParameter.name = [keys objectAtIndex:i];
		aURLParameter.value = [inDictionary objectForKey:[keys objectAtIndex:i]];
		
		[parameterArray addObject:aURLParameter];
		[aURLParameter release];
	}
	
	return [parameterArray autorelease];
}

+ (NSDictionary *)parameterDictionaryFromString:(NSString *)inString {
	NSMutableDictionary *foundParameters = [NSMutableDictionary dictionaryWithCapacity:10];
	if (inString) {
		NSScanner *parameterScanner = [[NSScanner alloc] initWithString:inString];
		NSString *thisName = nil;
		NSString *thisValue = nil;
		
		while (![parameterScanner isAtEnd]) {
			thisName = nil;
			thisValue = nil;
			
			[parameterScanner scanUpToString:@"=" intoString:&thisName];
			[parameterScanner scanString:@"=" intoString:NULL];
			[parameterScanner scanUpToString:@"&" intoString:&thisValue];
			[parameterScanner scanString:@"&" intoString:NULL];		
			
			[foundParameters setObject:[thisValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:thisName];
		}
		
		[parameterScanner release];
	}
	return foundParameters;
}

+ (NSString *)parameterStringForParameters:(NSArray *)inParameters {
	NSMutableString *queryString = [[NSMutableString alloc] init];
	int i = 0;
	int parameterCount = [inParameters count];	
	MPURLRequestParameter *aParameter = nil;
	
	for (; i < parameterCount; i++) {
		aParameter = [inParameters objectAtIndex:i];
		[queryString appendString:[aParameter URLEncodedParameterString]];
		
		if (i < parameterCount - 1) {
			[queryString appendString:@"&"];
		}
	}
	
	return [queryString autorelease];
}

+ (NSString *)parameterStringForDictionary:(NSDictionary *)inParameterDictionary {
	NSArray *parameters = [self parametersFromDictionary:inParameterDictionary];
	NSString *queryString = [self parameterStringForParameters:parameters];
	
	return queryString;
}

#pragma mark -

- (id)init {
	if (self = [super init]) {
		
	}
	return self;
}

- (id)initWithName:(NSString *)inName andValue:(NSString *)inValue {
	if (self = [super init]) {
		name = [inName copy];
		value = [inValue copy];
	}
	return self;
}

- (oneway void)dealloc {
	[name release];
	[value release];
	[super dealloc];
}

- (void)setName:(NSString *)theName {
	[name release];
	name = [theName copy];
}
- (NSString *)name {
	return name;
}
- (void)setValue:(NSString *)theValue {
	[value release];
	value = [theValue copy];
}
- (NSString *)value {
	return value;
}

#pragma mark -

- (NSString *)URLEncodedParameterString {
	return [NSString stringWithFormat:@"%@=%@", [name stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding], value ? [value stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @""];
}

#pragma mark -

- (NSComparisonResult)compare:(id)inObject {
	NSComparisonResult result = [name compare:[(MPURLRequestParameter *)inObject name]];
	
	if (result == NSOrderedSame) {
		result = [value compare:[(MPURLRequestParameter *)inObject value]];
	}
								 
	return result;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p %@>", NSStringFromClass([self class]), self, [self URLEncodedParameterString]];
}

@end
