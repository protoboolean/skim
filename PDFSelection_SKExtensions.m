//
//  PDFSelection_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/24/07.
/*
 This software is Copyright (c) 2007-2008
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"

#define ELLIPSIS_CHARACTER 0x2026

@interface PDFSelection (PDFSelectionPrivateDeclarations)
- (int)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(int)index onPage:(PDFPage *)page;
@end


@implementation PDFSelection (SKExtensions)

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    NSArray *pages = [self pages];
    return [pages count] ? [[pages objectAtIndex:0] displayLabel] : nil;
}

- (NSString *)cleanedString {
	return [[[self string] stringByRemovingAliens] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
}

- (NSAttributedString *)contextString {
    PDFSelection *extendedSelection = [self copy]; // see remark in -tableViewSelectionDidChange:
	NSMutableAttributedString *attributedSample;
	NSString *searchString = [self cleanedString];
	NSString *sample;
    NSMutableString *attributedString;
	NSString *ellipse = [NSString stringWithFormat:@"%C", ELLIPSIS_CHARACTER];
	NSRange foundRange;
    NSDictionary *attributes;
    NSNumber *fontSizeNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
	float fontSize = fontSizeNumber ? [fontSizeNumber floatValue] : 0.0;
    
	// Extend selection.
	[extendedSelection extendSelectionAtStart:10];
	[extendedSelection extendSelectionAtEnd:50];
	
    // get the cleaned string
    sample = [extendedSelection cleanedString];
    
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString:sample];
    attributedString = [attributedSample mutableString];
    [attributedString insertString:ellipse atIndex:0];
    [attributedString appendString:ellipse];
	
	// Find instances of search string and "bold" them.
	foundRange = [sample rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (foundRange.location != NSNotFound) {
        // Bold the text range where the search term was found.
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:fontSize], NSFontAttributeName, nil];
        [attributedSample setAttributes:attributes range:NSMakeRange(foundRange.location + 1, foundRange.length)];
        [attributes release];
    }
    
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSParagraphStyle defaultTruncatingTailParagraphStyle], NSParagraphStyleAttributeName, nil];
	// Add paragraph style.
    [attributedSample addAttributes:attributes range:NSMakeRange(0, [attributedSample length])];
	// Clean.
	[attributes release];
	[extendedSelection release];
	
	return [attributedSample autorelease];
}

- (PDFDestination *)destination {
    PDFDestination *destination = nil;
    NSArray *pages = [self pages];
    if ([pages count]) {
        PDFPage *page = [pages objectAtIndex:0];
        NSRect bounds = [self boundsForPage:page];
        destination = [[[PDFDestination alloc] initWithPage:page atPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))] autorelease];
    }
    return destination;
}

- (int)safeNumberOfRangesOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(numberOfRangesOnPage:)])
        return [self numberOfRangesOnPage:page];
    else
        return 0;
}

- (NSRange)safeRangeAtIndex:(int)anIndex onPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(rangeAtIndex:onPage:)])
        return [self rangeAtIndex:anIndex onPage:page];
    else
        return NSMakeRange(NSNotFound, 0);
}


static inline NSRange rangeOfSubstringOfStringAtIndex(NSString *string, NSArray *substrings, unsigned int anIndex) {
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    unsigned int i, iMax = [substrings count];
    
    if (anIndex >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i <= anIndex; i++) {
        NSString *substring = [substrings objectAtIndex:i];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([substring length] == 0)
            continue;
        range = [string rangeOfString:substring options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

+ (id)selectionWithSpecifier:(id)specifier {
    return [self selectionWithSpecifier:specifier onPage:nil];
}

+ (id)selectionWithSpecifier:(id)specifier onPage:(PDFPage *)aPage {
    if ([specifier isEqual:[NSNull null]])
        return nil;
    if ([specifier isKindOfClass:[NSArray class]] == NO)
        specifier = [NSArray arrayWithObject:specifier];
    if ([specifier count] == 1) {
        NSScriptObjectSpecifier *spec = [specifier objectAtIndex:0];
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            NSString *key = [spec key];
            if ([key isEqualToString:@"characters"] == NO && [key isEqualToString:@"words"] == NO && [key isEqualToString:@"paragraphs"] == NO && [key isEqualToString:@"attributeRuns"] == NO)
                // this allows to use selection properties directly
                specifier = [spec objectsByEvaluatingSpecifier];
                if ([specifier isKindOfClass:[NSArray class]] == NO)
                    specifier = [NSArray arrayWithObject:specifier];
        }
    }
    
    PDFSelection *selection = nil;
    NSEnumerator *specEnum = [specifier objectEnumerator];
    NSScriptObjectSpecifier *spec;
    
    while (spec = [specEnum nextObject]) {
        if ([spec isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
            continue;
        
        // we should get ranges of characters, words, or parapgraphs of the richText of a page
        NSString *key = [spec key];
        if ([key isEqualToString:@"characters"] == NO && [key isEqualToString:@"words"] == NO && [key isEqualToString:@"paragraphs"] == NO && [key isEqualToString:@"attributeRuns"] == NO)
            continue;
        
        // get the richText specifier
        NSScriptObjectSpecifier *textSpec = [spec containerSpecifier];
        if ([[textSpec key] isEqualToString:@"richText"] == NO)
            continue;
        
        // get the page
        NSScriptObjectSpecifier *pageSpec = [textSpec containerSpecifier];
        PDFPage *page = [pageSpec objectsByEvaluatingSpecifier];
        if ([page isKindOfClass:[NSArray class]])
            page = [(NSArray *)page count] ? [(NSArray *)page objectAtIndex:0] : nil;
        if ([page isKindOfClass:[PDFPage class]] == NO || (aPage && [aPage isEqual:page] == NO))
            continue;
        
        // we could also evaluate textSpec, but we already have the page
        NSTextStorage *textStorage = [page richText];
        
        // now get the ranges, which can be any kind of specifier
        int startIndex, endIndex, i, count, *indices;
        NSRange *ranges = NULL;
        int numRanges = 0;
        
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            // this should be the full range of characters, words, or paragraphs
            numRanges = 1;
            ranges = NSZoneRealloc([self zone], ranges, sizeof(NSRange));
            ranges[0] = NSMakeRange(0, [[textStorage valueForKey:key] count]);
        } else if ([spec isKindOfClass:[NSRangeSpecifier class]]) {
            // somehow getting the indices as for the general case sometimes leads to an exception for NSRangeSpecifier, so we get the indices of the start/endSpecifiers
            NSScriptObjectSpecifier *startSpec = [(NSRangeSpecifier *)spec startSpecifier];
            NSScriptObjectSpecifier *endSpec = [(NSRangeSpecifier *)spec endSpecifier];
            
            if (startSpec == nil && endSpec == nil)
                continue;
            
            if (startSpec) {
                indices = [startSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                if (count <= 0)
                    continue;
                startIndex = indices[0];
            } else {
                startIndex = 0;
            }
            
            if (endSpec) {
                indices = [endSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                if (count <= 0)
                    continue;
                endIndex = indices[count - 1];
            } else {
                endIndex = [[textStorage valueForKey:key] count];
            }
            
            numRanges = 1;
            ranges = NSZoneRealloc([self zone], ranges, sizeof(NSRange));
            ranges[0] = NSMakeRange(MIN(startIndex, endIndex), MAX(startIndex, endIndex) + 1 - MIN(startIndex, endIndex));
        } else {
            // this handles other objectSpecifiers (index, middel, random, relative, whose). It can contain several ranges, e.g. for aan NSWhoseSpecifier
            indices = [spec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
            if (count <= 0)
                continue;
            
            for (i = 0; i < count; i++) {
                unsigned int idx = indices[i];
                if (numRanges == 0 || idx > NSMaxRange(ranges[numRanges - 1])) {
                    numRanges++;
                    ranges = NSZoneRealloc([self zone], ranges, numRanges * sizeof(NSRange));
                    ranges[numRanges - 1] = NSMakeRange(idx, 1);
                } else {
                    ++(ranges[numRanges - 1].length);
                }
            }
        }
        
        if ([key isEqualToString:@"characters"] == NO) {
            // translate from subtext ranges to character ranges
            for (i = 0; i < numRanges; i++) {
                startIndex = ranges[i].location;
                endIndex = NSMaxRange(ranges[i]) - 1;
                NSString *string = [textStorage string];
                NSArray *substrings = [[textStorage valueForKey:key] valueForKey:@"string"];
                NSRange range = rangeOfSubstringOfStringAtIndex(string, substrings, startIndex);
                if (range.location == NSNotFound) {
                    ranges[i] = NSMakeRange(NSNotFound, 0);
                    continue;
                }
                startIndex = range.location;
                if (ranges[i].length > 1) {
                    range = rangeOfSubstringOfStringAtIndex(string, substrings, endIndex);
                    if (range.location == NSNotFound) {
                        ranges[i] = NSMakeRange(NSNotFound, 0);
                        continue;
                    }
                }
                endIndex = NSMaxRange(range) - 1;
                ranges[i] = NSMakeRange(startIndex, endIndex + 1 - startIndex);
            }
        }
        
        for (i = 0; i < numRanges; i++) {
            PDFSelection *sel;
            NSRange range = ranges[i];
            if (range.length && (sel = [page selectionForRange:range])) {
                if (selection == nil)
                    selection = sel;
                else
                    [selection addSelection:sel];
            }
        }
        if (ranges) NSZoneFree([self zone], ranges);
    }
    return selection;
}

- (id)objectSpecifier {
    NSArray *pages = [self pages];
    if ([pages count] == 0)
        return [NSArray array];
    NSMutableArray *ranges = [NSMutableArray array];
    NSEnumerator *pageEnum = [pages objectEnumerator];
    PDFPage *page;
    while (page = [pageEnum nextObject]) {
        unsigned int i, iMax = [self safeNumberOfRangesOnPage:page];
        for (i = 0; i < iMax; i++) {
            NSRange range = [self safeRangeAtIndex:i onPage:page];
            if (range.length == 0)
                continue;
            
            NSScriptObjectSpecifier *textSpec = [[NSPropertySpecifier alloc] initWithContainerSpecifier:[page objectSpecifier] key:@"richText"];
            if (textSpec == nil)
                continue;
            
            NSIndexSpecifier *startSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:range.location];
            NSIndexSpecifier *endSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:NSMaxRange(range) - 1];
            if (startSpec == nil || endSpec == nil) {
                [startSpec release];
                [endSpec release];
                continue;
            }
            
            NSRangeSpecifier *rangeSpec = [[NSRangeSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" startSpecifier:startSpec endSpecifier:endSpec];
            if (rangeSpec == nil)
                continue;
            
            [ranges addObject:rangeSpec];
            [rangeSpec release];
            [startSpec release];
            [endSpec release];
            [textSpec release];
        }
    }
    return ranges;
}

@end
