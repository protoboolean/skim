//
//  SKFDFParser.m
//  Skim
//
//  Created by Christiaan Hofman on 9/6/07.
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

#import "SKFDFParser.h"
#import <Quartz/Quartz.h>
#import <ApplicationServices/ApplicationServices.h>
#import "NSScanner_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKStringConstants.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKPDFAnnotationCircle.h"
#import "SKPDFAnnotationSquare.h"
#import "SKPDFAnnotationLine.h"
#import "SKPDFAnnotationMarkup.h"
#import "SKPDFAnnotationFreeText.h"
#import "SKPDFAnnotationNote.h"

const char *SKFDFCatalogKey = "FDF";
const char *SKFDFAnnotationsKey = "Annots";
const char *SKFDFFileKey = "F";
const char *SKFDFFileIDKey = "ID";
const char *SKFDFRootKey = "Root";

const char *SKFDFTypeKey = "Type";

const char *SKFDFAnnotationFlagsKey = "F";
const char *SKFDFAnnotationTypeKey = "Subtype";
const char *SKFDFAnnotationBoundsKey = "Rect";
const char *SKFDFAnnotationPageIndexKey = "Page";
const char *SKFDFAnnotationContentsKey = "Contents";
const char *SKFDFAnnotationColorKey = "C";
const char *SKFDFAnnotationInteriorColorKey = "IC";
const char *SKFDFAnnotationBorderStylesKey = "BS";
const char *SKFDFAnnotationLineWidthKey = "W";
const char *SKFDFAnnotationDashPatternKey = "D";
const char *SKFDFAnnotationBorderStyleKey = "S";
const char *SKFDFAnnotationBorderKey = "Border";
const char *SKFDFAnnotationIconTypeKey = "Name";
const char *SKFDFAnnotationLineStylesKey = "LE";
const char *SKFDFAnnotationLinePointsKey = "L";
const char *SKFDFAnnotationQuadPointsKey = "QuadPoints";
const char *SKFDFDefaultAppearanceKey = "DA";
const char *SKFDFDefaultStyleKey = "DS";

const char *SKFDFAnnotation = "Annot";

const char *SKFDFBorderStyleSolid = "S";
const char *SKFDFBorderStyleDashed = "D";
const char *SKFDFBorderStyleBeveled = "B";
const char *SKFDFBorderStyleInset = "I";
const char *SKFDFBorderStyleUnderline = "U";

const char *SKFDFTextAnnotationIconComment = "Comment";
const char *SKFDFTextAnnotationIconKey = "Key";
const char *SKFDFTextAnnotationIconNote = "Note";
const char *SKFDFTextAnnotationIconNewParagraph = "NewParagraph";
const char *SKFDFTextAnnotationIconParagraph = "Paragraph";
const char *SKFDFTextAnnotationIconInsert = "Insert";

const char *SKFDFLineStyleNone = "None";
const char *SKFDFLineStyleSquare = "Square";
const char *SKFDFLineStyleCircle = "Circle";
const char *SKFDFLineStyleDiamond = "Diamond";
const char *SKFDFLineStyleOpenArrow = "OpenArrow";
const char *SKFDFLineStyleClosedArrow = "ClosedArrow";

@interface SKFDFParser (SKPrivate)
+ (NSDictionary *)noteDictionaryFromPDFDictionary:(CGPDFDictionaryRef)annot;
@end


@implementation SKFDFParser

+ (NSArray *)noteDictionariesFromFDFData:(NSData *)data {
    const char *pdfHeader = "%PDF";
    unsigned pdfHeaderLength = strlen(pdfHeader);
    
    if ([data length] < pdfHeaderLength)
        return NO;
    
    NSMutableData *pdfData = [data mutableCopy];
    
    [pdfData replaceBytesInRange:NSMakeRange(0, pdfHeaderLength) withBytes:pdfHeader length:pdfHeaderLength];

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
    NSMutableArray *notes = nil;
    
    if (document) {
        CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
        CGPDFDictionaryRef fdfDict;
        CGPDFArrayRef annots;
        
        if (catalog &&
            CGPDFDictionaryGetDictionary(catalog, SKFDFCatalogKey, &fdfDict) &&
            CGPDFDictionaryGetArray(fdfDict, SKFDFAnnotationsKey, &annots)) {
            
            size_t i, count = CGPDFArrayGetCount(annots);
            notes = [NSMutableArray arrayWithCapacity:count];
            for (i = 0; i < count; i++) {
                CGPDFDictionaryRef annot;
                NSDictionary *note;
                if (CGPDFArrayGetDictionary(annots, i, &annot) && 
                    (note = [self noteDictionaryFromPDFDictionary:annot])) {
                    [notes addObject:note];
                }
            }
        }
        
        CGPDFDocumentRelease(document);
    }
    
    CGDataProviderRelease(provider);
    [pdfData release];
    
    return notes;
}

+ (NSDictionary *)noteDictionaryFromPDFDictionary:(CGPDFDictionaryRef)annot {
    if (annot == NULL)
        return nil;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    CGPDFDictionaryRef dict;
    CGPDFArrayRef array;
    CGPDFStringRef string;
    const char *name;
    CGPDFReal real;
    CGPDFInteger integer;
    BOOL success = YES;
    NSRect bounds = NSZeroRect;
    
    if (CGPDFDictionaryGetName(annot, SKFDFTypeKey, &name) == NO || strcmp(name, SKFDFAnnotation) != 0) {
        success = NO;
    }
    
    if (CGPDFDictionaryGetName(annot, SKFDFAnnotationTypeKey, &name)) {
        [dictionary setObject:[NSString stringWithFormat:@"%s", name] forKey:SKPDFAnnotationTypeKey];
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationBoundsKey, &array)) {
        CGPDFReal l, b, r, t;
        if (CGPDFArrayGetCount(array) == 4 && CGPDFArrayGetNumber(array, 0, &l) && CGPDFArrayGetNumber(array, 1, &b) && CGPDFArrayGetNumber(array, 2, &r) && CGPDFArrayGetNumber(array, 3, &t)) {
            bounds = NSMakeRect(l, b, r - l, t - b);
            [dictionary setObject:NSStringFromRect(bounds) forKey:SKPDFAnnotationBoundsKey];
        }
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetInteger(annot, SKFDFAnnotationPageIndexKey, &integer)) {
        [dictionary setObject:[NSNumber numberWithInt:integer] forKey:SKPDFAnnotationPageIndexKey];
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetString(annot, SKFDFAnnotationContentsKey, &string)) {
        NSString *contents = (NSString *)CGPDFStringCopyTextString(string);
        if (contents)
            [dictionary setObject:contents forKey:SKPDFAnnotationContentsKey];
        [contents release];
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationColorKey, &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:SKPDFAnnotationColorKey];
        }
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationInteriorColorKey, &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:SKPDFAnnotationInteriorColorKey];
        }
    }
    
    if (CGPDFDictionaryGetDictionary(annot, SKFDFAnnotationBorderStylesKey, &dict)) {
        if (CGPDFDictionaryGetNumber(dict, SKFDFAnnotationLineWidthKey, &real)) {
            if (real > 0.0) {
                [dictionary setObject:[NSNumber numberWithFloat:real] forKey:SKPDFAnnotationLineWidthKey];
                if (CGPDFDictionaryGetName(dict, SKFDFAnnotationBorderStyleKey, &name)) {
                    int style = kPDFBorderStyleSolid;
                    if (strcmp(name, SKFDFBorderStyleSolid) == 0)
                        style = kPDFBorderStyleSolid;
                    else if (strcmp(name, SKFDFBorderStyleDashed) == 0)
                        style = kPDFBorderStyleDashed;
                    else if (strcmp(name, SKFDFBorderStyleBeveled) == 0)
                        style = kPDFBorderStyleBeveled;
                    else if (strcmp(name, SKFDFBorderStyleInset) == 0)
                        style = kPDFBorderStyleInset;
                    else if (strcmp(name, SKFDFBorderStyleUnderline) == 0)
                        style = kPDFBorderStyleUnderline;
                    [dictionary setObject:[NSNumber numberWithInt:style] forKey:SKPDFAnnotationBorderStyleKey];
                }
                if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationDashPatternKey, &array)) {
                    size_t i, count = CGPDFArrayGetCount(array);
                    NSMutableArray *dp = [NSMutableArray array];
                    for (i = 0; i < count; i++) {
                        if (CGPDFArrayGetNumber(array, i, &real))
                            [dp addObject:[NSNumber numberWithFloat:real]];
                    }
                    [dictionary setObject:dp forKey:SKPDFAnnotationDashPatternKey];
                }
            }
        }
    } else if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationBorderKey, &array)) {
        size_t i, count = CGPDFArrayGetCount(array);
        if (count > 2 && CGPDFArrayGetNumber(array, 2, &real) && real > 0.0) {
            [dictionary setObject:[NSNumber numberWithFloat:real] forKey:SKPDFAnnotationLineWidthKey];
            CGPDFArrayRef dp;
            if (count > 3 && CGPDFArrayGetArray(array, 3, &dp)) {
                count = CGPDFArrayGetCount(dp);
                NSMutableArray *dashPattern = [NSMutableArray arrayWithCapacity:count];
                for (i = 0; i < count; i++) {
                    if (CGPDFArrayGetNumber(dp, i, &real))
                        [dashPattern addObject:[NSNumber numberWithFloat:real]];
                }
                [dictionary setObject:dashPattern forKey:SKPDFAnnotationDashPatternKey];
                [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleDashed] forKey:SKPDFAnnotationBorderStyleKey];
            } else {
                 [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleSolid] forKey:SKPDFAnnotationBorderStyleKey];
            }
        }
    } else {
        [dictionary setObject:[NSNumber numberWithFloat:1.0] forKey:SKPDFAnnotationLineWidthKey];
        [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleSolid] forKey:SKPDFAnnotationBorderStyleKey];
    }
    
    if (CGPDFDictionaryGetName(annot, SKFDFAnnotationIconTypeKey, &name)) {
        int icon = kPDFTextAnnotationIconNote;
        if (strcmp(name, SKFDFTextAnnotationIconComment) == 0)
            icon = kPDFTextAnnotationIconComment;
        else if (strcmp(name, SKFDFTextAnnotationIconKey) == 0)
            icon = kPDFTextAnnotationIconKey;
        else if (strcmp(name, SKFDFTextAnnotationIconNote) == 0)
            icon = kPDFTextAnnotationIconNote;
        else if (strcmp(name, SKFDFTextAnnotationIconNewParagraph) == 0)
            icon = kPDFTextAnnotationIconNewParagraph;
        else if (strcmp(name, SKFDFTextAnnotationIconParagraph) == 0)
            icon = kPDFTextAnnotationIconParagraph;
        else if (strcmp(name, SKFDFTextAnnotationIconInsert) == 0)
            icon = kPDFTextAnnotationIconInsert;
        [dictionary setObject:[NSNumber numberWithInt:icon] forKey:SKPDFAnnotationIconTypeKey];
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationLineStylesKey, &array)) {
        int startStyle = kPDFLineStyleNone;
        int endStyle = kPDFLineStyleNone;
        if (CGPDFArrayGetCount(array) == 2) {
            if (CGPDFArrayGetName(array, 0, &name)) {
                if (strcmp(name, SKFDFLineStyleNone) == 0)
                    startStyle = kPDFLineStyleNone;
                else if (strcmp(name, SKFDFLineStyleSquare) == 0)
                    startStyle = kPDFLineStyleSquare;
                else if (strcmp(name, SKFDFLineStyleCircle) == 0)
                    startStyle = kPDFLineStyleCircle;
                else if (strcmp(name, SKFDFLineStyleDiamond) == 0)
                    startStyle = kPDFLineStyleDiamond;
                else if (strcmp(name, SKFDFLineStyleOpenArrow) == 0)
                    startStyle = kPDFLineStyleOpenArrow;
                else if (strcmp(name, SKFDFLineStyleClosedArrow) == 0)
                    startStyle = kPDFLineStyleClosedArrow;
            }
            if (CGPDFArrayGetName(array, 1, &name)) {
                if (strcmp(name, SKFDFLineStyleNone) == 0)
                    startStyle = kPDFLineStyleNone;
                else if (strcmp(name, SKFDFLineStyleSquare) == 0)
                    endStyle = kPDFLineStyleSquare;
                else if (strcmp(name, SKFDFLineStyleCircle) == 0)
                    endStyle = kPDFLineStyleCircle;
                else if (strcmp(name, SKFDFLineStyleDiamond) == 0)
                    endStyle = kPDFLineStyleDiamond;
                else if (strcmp(name, SKFDFLineStyleOpenArrow) == 0)
                    endStyle = kPDFLineStyleOpenArrow;
                else if (strcmp(name, SKFDFLineStyleClosedArrow) == 0)
                    endStyle = kPDFLineStyleClosedArrow;
            }
        }
        [dictionary setObject:[NSNumber numberWithInt:endStyle] forKey:SKPDFAnnotationEndLineStyleKey];
        [dictionary setObject:[NSNumber numberWithInt:startStyle] forKey:SKPDFAnnotationStartLineStyleKey];
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationLinePointsKey, &array)) {
        NSPoint p1, p2;
        if (CGPDFArrayGetCount(array) == 4 && CGPDFArrayGetNumber(array, 0, &p1.x) && CGPDFArrayGetNumber(array, 1, &p1.y) && CGPDFArrayGetNumber(array, 2, &p2.x) && CGPDFArrayGetNumber(array, 3, &p2.y)) {
            [dictionary setObject:NSStringFromPoint(p1) forKey:SKPDFAnnotationStartPointKey];
            [dictionary setObject:NSStringFromPoint(p2) forKey:SKPDFAnnotationEndPointKey];
        }
    }
    
    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationQuadPointsKey, &array)) {
        size_t i, count = CGPDFArrayGetCount(array);
        if (count % 8 == 0) {
            NSMutableArray *quadPoints = [NSMutableArray arrayWithCapacity:count / 2];
            for (i = 0; i < count; i++) {
                NSPoint point;
                if (CGPDFArrayGetNumber(array, i, &point.x) && CGPDFArrayGetNumber(array, ++i, &point.y))
                    [quadPoints addObject:NSStringFromPoint(SKSubstractPoints(point, bounds.origin))];
            }
            [dictionary setObject:quadPoints forKey:SKPDFAnnotationQuadrilateralPointsKey];
        }
    }
    
    if (CGPDFDictionaryGetString(annot, SKFDFDefaultAppearanceKey, &string)) {
        NSString *da = (NSString *)CGPDFStringCopyTextString(string);
        if (da) {
            NSScanner *scanner = [NSScanner scannerWithString:da];
            NSString *fontName;
            float fontSize;
            if ([scanner scanUpToString:@"Tf" intoString:NULL] && [scanner isAtEnd] == NO) {
                unsigned location = [scanner scanLocation];
                NSRange r = [da rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, location)];
                if (r.location != NSNotFound) {
                    [scanner setScanLocation:NSMaxRange(r)];
                    if ([scanner scanCharactersFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet] intoString:&fontName] &&
                        [scanner scanFloat:&fontSize] &&
                        [scanner scanString:@"Tf" intoString:NULL] &&
                        [scanner scanLocation] == location + 2) {
                        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
                        if (font == nil) {
                            fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey];
                            font = [NSFont fontWithName:fontName size:fontSize];
                        }
                        if (font)
                            [dictionary setObject:font forKey:SKPDFAnnotationFontKey];
                   }
               }
           }
           [da release];
       }
    }
    
    NSSet *validTypes = [NSSet setWithObjects:SKFreeTextString, SKNoteString, SKCircleString, SKSquareString, SKHighlightString, SKUnderlineString, SKStrikeOutString, SKLineString, nil];
    NSString *type = [dictionary objectForKey:SKPDFAnnotationTypeKey];
    NSString *contents;
    if ([type isEqualToString:SKTextString]) {
        [dictionary setObject:SKNoteString forKey:SKPDFAnnotationTypeKey];
        if (contents = [dictionary objectForKey:SKPDFAnnotationContentsKey]) {
            NSRange r = [contents rangeOfString:@"  "];
            if (NSMaxRange(r) < [contents length]) {
                NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey]
                                               size:[[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey]];
                NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:[contents substringFromIndex:NSMaxRange(r)]
                                                    attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]] autorelease];
                [dictionary setObject:attrString forKey:SKPDFAnnotationTextKey];
                [dictionary setObject:[contents substringToIndex:r.location] forKey:SKPDFAnnotationContentsKey];
            }
        }
    } else if ([validTypes containsObject:type] == NO) {
        success = NO;
    }
    
    return success ? dictionary : nil;
}

@end
