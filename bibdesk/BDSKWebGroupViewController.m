//
//  BDSKWebGroupViewController.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/26/07.

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
 
 - Neither the name of Michael McCracken nor the names of any
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

#import "BDSKWebGroupViewController.h"
#import <WebKit/WebKit.h>
#import "BDSKHCiteParser.h"
#import "BDSKWebGroup.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"


@implementation BDSKWebGroupViewController

- (NSString *)windowNibName { return @"BDSKWebGroupView"; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [group release];
    [super dealloc];
}

- (void)awakeFromNib {
//    [view setMinSize:[view frame].size];
    [edgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
}

- (void)updateWebGroupView {
    OBASSERT(group);
    [self window];
    NSString *name = [group name];

    [[urlTextField cell] setPlaceholderString:NSLocalizedString(@"URL ", @"Web group URL field placeholder")];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWebGroupUpdatedNotification:) name:BDSKWebGroupUpdatedNotification object:group];
}

- (NSView *)view {
    [self window];
    return view;
}

- (BDSKWebGroup *)group {
    return group;
}

- (void)setGroup:(BDSKWebGroup *)newGroup {
    if (group != newGroup) {
        if (group)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:BDSKWebGroupUpdatedNotification object:group];
        
        [group release];
        group = [newGroup retain];
        
        if (group)
            [self updateWebGroupView];
    }
}

- (IBAction)changeURL:(id)sender {
    [webView takeStringURLFrom:sender];
    // listen for did 
   // [group setSearchTerm:[sender stringValue]];

}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{

    NSString *s = [[[frame DOMDocument] documentElement] outerHTML];
    
    NSError *err = nil;
    NSArray *d = [BDSKHCiteParser itemsFromXHTMLString:s error:&err];
    
    [group setPublications:d];
    
}

- (void)handleWebGroupUpdatedNotification:(NSNotification *)notification{
// ?
}

@end
