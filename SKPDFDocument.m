//
//  SKPDFDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2011
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

#import "SKPDFDocument.h"
#import "SKPDFPage.h"
#import "SKPrintAccessoryController.h"

NSString *SKSuppressPrintPanel = @"SKSuppressPrintPanel";

@interface PDFDocument (SKPrivateDeclarations)
- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;
@end


@interface PDFDocument (SKLionDeclarations)
- (NSPrintOperation *)printOperationForPrintInfo:(NSPrintInfo *)printInfo scalingMode:(PDFPrintScalingMode)scalingMode autoRotate:(BOOL)autoRotate;
@end


@implementation SKPDFDocument

- (Class)pageClass {
    return [SKPDFPage class];
}

- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate {
    NSPrintOperation *printOperation = nil;
    if ([[SKPDFDocument superclass] instancesRespondToSelector:_cmd]) {
        printOperation = [super getPrintOperationForPrintInfo:printInfo autoRotate:autoRotate];
        if ([[[[printOperation printInfo] dictionary] objectForKey:SKSuppressPrintPanel] boolValue])
            [printOperation setShowsPrintPanel:NO];
        // NSPrintProtected is a private key that disables the items in the PDF popup of the Print panel, and is set for encrypted documents
        if ([self isEncrypted])
            [[[printOperation printInfo] dictionary] setValue:[NSNumber numberWithBool:NO] forKey:@"NSPrintProtected"];
        
        NSPrintPanel *printPanel = [printOperation printPanel];
        [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
        [printPanel addAccessoryController:[[[SKPrintAccessoryController alloc] init] autorelease]];
    }
    return printOperation;
}

- (NSPrintOperation *)printOperationForPrintInfo:(NSPrintInfo *)printInfo scalingMode:(PDFPrintScalingMode)scalingMode autoRotate:(BOOL)autoRotate {
    NSPrintOperation *printOperation = nil;
    if ([[SKPDFDocument superclass] instancesRespondToSelector:_cmd]) {
        printOperation = [super printOperationForPrintInfo:printInfo scalingMode:scalingMode autoRotate:autoRotate];
        if ([[[[printOperation printInfo] dictionary] objectForKey:SKSuppressPrintPanel] boolValue])
            [printOperation setShowsPrintPanel:NO];
        // NSPrintProtected is a private key that disables the items in the PDF popup of the Print panel, and is set for encrypted documents
        if ([self isEncrypted])
            [[[printOperation printInfo] dictionary] setValue:[NSNumber numberWithBool:NO] forKey:@"NSPrintProtected"];
        
        NSPrintPanel *printPanel = [printOperation printPanel];
        [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
        [printPanel addAccessoryController:[[[SKPrintAccessoryController alloc] init] autorelease]];
    }
    return printOperation;
}

- (BOOL)unlockWithPassword:(NSString *)password {
    BOOL wasLocked = [self isLocked];
    BOOL allowedPrinting = [self allowsPrinting];
    BOOL allowedCopying = [self allowsCopying];
    if ([super unlockWithPassword:password]) {
        if ([[self delegate] respondsToSelector:@selector(document:didUnlockWithPassword:)] &&
            ([self isLocked] > wasLocked || [self allowsPrinting] > allowedPrinting || [self allowsCopying] > allowedCopying)) {
            [[self delegate] document:self didUnlockWithPassword:password];
        }
        return YES;
    }
    return NO;
}

@end
