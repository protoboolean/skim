// BibPref_Defaults 
// Created Michael McCracken, 2002 
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
#import <OmniAppKit/OAPreferenceClient.h>
#import "BibPrefController.h"
#import "BDSKFieldNameFormatter.h"
#import "MacroWindowController.h"

@interface BibPref_Defaults : OAPreferenceClient
{
    IBOutlet NSButton* delSelectedDefaultFieldButton;
    IBOutlet NSButton* addDefaultFieldButton;
    IBOutlet NSWindow* globalMacroFileSheet;
    IBOutlet NSTableView* globalMacroFilesTableView;
    IBOutlet NSTableView* defaultFieldsTableView;
    IBOutlet NSMatrix* RSSDescriptionFieldMatrix;
    IBOutlet NSTextField* RSSDescriptionFieldTextField;
    IBOutlet NSButton *editGlobalMacroDefsButton;
    IBOutlet NSMenu *fieldTypeMenu;
    NSMutableArray *customFieldsArray;
    NSMutableSet *customFieldsSet;
    NSMutableArray *globalMacroFiles;
    MacroWindowController *macroWC;
}

- (IBAction)delSelectedDefaultField:(id)sender;
- (IBAction)addDefaultField:(id)sender;
- (IBAction)showTypeInfoEditor:(id)sender;
- (IBAction)RSSDescriptionFieldChanged:(id)sender;
- (void)addGlobalMacroFilePanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (IBAction)showMacrosWindow:(id)sender;
- (IBAction)showMacroFileWindow:(id)sender;
- (IBAction)closeMacroFileWindow:(id)sender;
- (IBAction)addGlobalMacroFile:(id)sender;
- (IBAction)delGlobalMacroFiles:(id)sender;

@end

@interface MacroFileTableView : NSTableView {} @end
