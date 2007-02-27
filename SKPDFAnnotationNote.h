//
//  SKPDFAnnotationNote.h
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
/*
 This software is Copyright (c) 2007
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern NSString *SKAnnotationWillChangeNotification;
extern NSString *SKAnnotationDidChangeNotification;

@interface PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryValue;

- (PDFDestination *)destination;
- (unsigned int)pageIndex;
- (NSString *)pageLabel;

- (NSImage *)image;
- (NSAttributedString *)text;

- (void)setDefaultColor:(NSColor *)newColor;

- (NSArray *)texts;

- (BOOL)isNoteAnnotation;
- (BOOL)isTemporaryAnnotation;
- (BOOL)isResizable;

@end

@interface SKPDFAnnotationCircle : PDFAnnotationCircle
@end

@interface SKPDFAnnotationSquare : PDFAnnotationSquare
@end

@interface SKPDFAnnotationFreeText : PDFAnnotationFreeText
@end

@interface SKPDFAnnotationText : PDFAnnotationText
@end

@interface SKPDFAnnotationNote : PDFAnnotationText {
    NSImage *image;
    NSAttributedString *text;
    NSArray *texts;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSAttributedString *)newText;

@end

@interface SKPDFAnnotationTemporary : PDFAnnotationCircle
@end

@interface SKNoteText : NSObject {
    PDFAnnotation *annotation;
    float rowHeight;
}

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation;

- (PDFAnnotation *)annotation;

- (NSArray *)texts;

- (NSString *)type;
- (unsigned int)pageIndex;
- (NSString *)pageLabel;
- (NSAttributedString *)contents;

- (float)rowHeight;
- (void)setRowHeight:(float)newRowHeight;

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;

@end
