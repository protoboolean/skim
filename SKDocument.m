//

// SKDocument.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import "SKDocument.h"
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "SKPDFAnnotationNote.h"
#import "SKNote.h"
#import "SKPSProgressController.h"
#import "BDAlias.h"

// maximum length of xattr value recommended by Apple
#define MAX_XATTR_LENGTH 4096

NSString *SKDocumentControllerWillCloseDocumentsNotification = @"SKDocumentControllerWillCloseDocumentsNotification";

NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

// See CFBundleTypeName in Info.plist
static NSString *SKPDFDocumentType = nil; /* set to NSPDFPboardType, not @"NSPDFPboardType" */
static NSString *SKEmbeddedPDFDocumentType = @"PDF With Embedded Notes";
static NSString *SKBarePDFDocumentType = @"PDF Without Notes";
static NSString *SKNotesDocumentType = @"Skim Notes";
static NSString *SKPostScriptDocumentType = @"PostScript document";

@implementation SKDocument

+ (void)initialize {
    if (nil == SKPDFDocumentType)
        SKPDFDocumentType = [NSPDFPboardType copy];
}

- (id)init{
    
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        notes = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pdfData release];
    [notes release];
    [noteDicts release];
    [super dealloc];
}

- (void)makeWindowControllers{
    SKMainWindowController *mainWindowController = [[[SKMainWindowController alloc] initWithWindowNibName:@"MainWindow"] autorelease];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    
    SKMainWindowController *mainController =  (SKMainWindowController *)aController;
    
    [mainController setShouldCloseDocument:YES];
    
    [mainController setPdfDocument:pdfDocument];
    
    // we keep a pristine copy for save, as we shouldn't save the annotations
    [pdfDocument autorelease];
    pdfDocument = nil;
    
    [mainController setAnnotationsFromDictionaries:noteDicts];
    [noteDicts release];
    noteDicts = nil;
}


- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    // we check for notes and save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType]) {
       [self saveNotesToExtendedAttributesAtURL:absoluteURL];
       if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation)
            [self updateChangeCount:NSChangeCleared];
    }
    
    return success;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    if ([typeName isEqualToString:SKPDFDocumentType]) {
        didWrite = [pdfData writeToURL:absoluteURL options:NSAtomicWrite error:outError];
    } else if ([typeName isEqualToString:SKEmbeddedPDFDocumentType]) {
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [[[self mainWindowController] pdfDocument] writeToURL:absoluteURL];
    } else if ([typeName isEqualToString:SKBarePDFDocumentType]) {
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [pdfData writeToURL:absoluteURL options:NSAtomicWrite error:outError];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        NSData *data = [self notesData];
        if (data != nil)
            didWrite = [data writeToURL:absoluteURL options:NSAtomicWrite error:outError];
    }
    return didWrite;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    if ([super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]) {
        if ([typeName isEqualToString:SKNotesDocumentType] == NO) {
            [[self mainWindowController] setPdfDocument:pdfDocument];
            [pdfDocument autorelease];
            pdfDocument = nil;
        } else {
            [self updateChangeCount:NSChangeCleared];
        }
        if (noteDicts) {
            [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts];
            [noteDicts release];
            noteDicts = nil;
        }
        return YES;
    } else return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead = NO;
    if ([docType isEqualToString:SKPDFDocumentType]) {
        [pdfData release];
        [pdfDocument release];
        pdfData = [[NSData alloc] initWithContentsOfURL:absoluteURL];    
        pdfDocument = [[PDFDocument alloc] initWithURL:absoluteURL];    
        didRead = pdfDocument != nil;
        [self readNotesFromExtendedAttributesAtURL:absoluteURL];
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        [pdfData release];
        [pdfDocument release];
        NSData *data = [[NSData alloc] initWithContentsOfURL:absoluteURL];
        if (data) {
            SKPSProgressController *progressController = [[SKPSProgressController alloc] init];
            pdfData = [[progressController PDFDataWithPostScriptData:data] retain];
            [progressController autorelease];
            pdfDocument = [[PDFDocument alloc] initWithData:pdfData];    
        } else {
            pdfData = nil;
            pdfDocument = nil;
        }
        didRead = pdfDocument != nil;
    }
    if (NO == didRead && outError)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @""), NSLocalizedDescriptionKey, nil]];
    return didRead;
}

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
    if (returnCode == NSOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        
        if ([self readNotesFromData:[NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]]] && noteDicts) {
            [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts];
            [noteDicts release];
            noteDicts = nil;
        }
        
        [self updateChangeCount:NSChangeDone];
    }
}

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *path = [[self fileURL] path];
    [oPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
                              file:[[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"]
                             types:[NSArray arrayWithObject:@"skim"]
                    modalForWindow:[[self mainWindowController] window]
                     modalDelegate:self
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];		
}

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        int i, numberOfNotes = [notes count];
        NSArray *oldNotes = [fm extendedAttributeNamesAtPath:path traverseLink:YES error:NULL];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", nil];
        NSMutableDictionary *longNotes = [NSMutableDictionary dictionary];
        NSString *name = nil;
        NSData *data = nil;
        NSError *error = nil;
        
        // first remove all old notes
        for (i = 0; YES; i++) {
            name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i", i];
            if ([oldNotes containsObject:name] == NO)
                break;
            if ([fm removeExtendedAttribute:name atPath:path traverseLink:YES error:&error] == NO) {
                NSLog(@"%@: %@", self, error);
            }
        }
        
        for (i = 0; i < numberOfNotes; i++) {
            name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i", i];
            data = [NSKeyedArchiver archivedDataWithRootObject:[[notes objectAtIndex:i] dictionaryValue]];
            if ([data length] > MAX_XATTR_LENGTH) {
                int j, n = ceil([data length] / MAX_XATTR_LENGTH);
                NSData *subdata;
                for (j = 0; j < n; j++) {
                    name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i-%i", i, j];
                    subdata = [data subdataWithRange:NSMakeRange(j * MAX_XATTR_LENGTH, j == n - 1 ? [data length] - j * MAX_XATTR_LENGTH : MAX_XATTR_LENGTH)];
                    if ([fm setExtendedAttributeNamed:name toValue:subdata atPath:path options:nil error:&error] == NO) {
                        success = NO;
                        NSLog(@"%@: %@", self, error);
                    }                    
                }
                [longNotes setObject:[NSNumber numberWithInt:j] forKey:[NSNumber numberWithInt:i]];
            } else if ([fm setExtendedAttributeNamed:name toValue:data atPath:path options:nil error:&error] == NO) {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        }
        
        if ([notes count] == 0) {
            if ([fm removeExtendedAttribute:@"net_sourceforge_bibdesk_skim_notesInfo" atPath:path traverseLink:YES error:&error] == NO) {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        } else {
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", [longNotes count] ? longNotes : nil, @"longNotes", nil];
            if ([fm setExtendedAttributeNamed:@"net_sourceforge_bibdesk_skim_notesInfo" toPropertyListValue:dictionary atPath:path options:nil error:&error] == NO) {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        }
    }
    return success;
}

- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *dict = nil;
    BOOL success = YES;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        dict = [fm propertyListFromExtendedAttributeNamed:@"net_sourceforge_bibdesk_skim_notesInfo" atPath:[aURL path] traverseLink:YES error:&error];
        if (dict == nil) {
            success = NO;
            if ([[[error userInfo] objectForKey:NSUnderlyingErrorKey] code] != ENOATTR)
                NSLog(@"%@: %@", self, error);
        }
    }
    if (dict != nil) {
        int i, numberOfNotes = [[dict objectForKey:@"numberOfNotes"] intValue];
        NSDictionary *longNotes = [dict objectForKey:@"longNotes"];
        NSString *name = nil;
        int n;
        NSData *data = nil;
        
        if (noteDicts)
            [noteDicts release];
        noteDicts = [[NSMutableArray alloc] initWithCapacity:numberOfNotes];
        
        for (i = 0; i < numberOfNotes; i++) {
            n = [[longNotes objectForKey:[NSNumber numberWithInt:i]] intValue];
            if (n == 0) {
                name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i", i];
                if ((data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) &&
                    (dict = [NSKeyedUnarchiver unarchiveObjectWithData:data])) {
                    [noteDicts addObject:dict];
                } else {
                    success = NO;
                    NSLog(@"%@: %@", self, error);
                }
            } else {
                NSMutableData *mutableData = [NSMutableData dataWithCapacity:n * MAX_XATTR_LENGTH];
                int j;
                for (j = 0; j < n; j++) {
                    name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i-%i", i, j];
                    if (data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) {
                        [mutableData appendData:data];
                    } else {
                        success = NO;
                        NSLog(@"%@: %@", self, error);
                    }
                }
                if (dict = [NSKeyedUnarchiver unarchiveObjectWithData:mutableData]) {
                    [noteDicts addObject:dict];
                } else {
                    success = NO;
                    NSLog(@"%@: %@", self, error);
                }
            }
        }
    } else {
        success = NO;
    }
    return success;
}

- (NSData *)notesData {
    int i, numberOfNotes = [notes count];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:numberOfNotes];
    NSData *data;
    
    for (i = 0; i < numberOfNotes; i++)
        [array addObject:[[notes objectAtIndex:i] dictionaryValue]];
    data = [NSKeyedArchiver archivedDataWithRootObject:array];
    
    return data;
}

- (BOOL)readNotesFromData:(NSData *)data {
    NSDictionary *dict = nil;
    BOOL success = YES;
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (array != nil) {
        int i, numberOfNotes = [array count];
        
        if (noteDicts)
            [noteDicts release];
        noteDicts = [[NSMutableDictionary alloc] initWithCapacity:numberOfNotes];
        
        for (i = 0; i < numberOfNotes; i++) {
            dict = [array objectAtIndex:i];
            [noteDicts addObject:dict];
        }
    } else {
        success = NO;
    }
    return success;
}

#pragma mark Accessors

- (NSArray *)notes {
    return notes;
}

- (void)setNotes:(NSArray *)newNotes {
    [notes setArray:notes];
}

- (unsigned)countOfNotes {
    return [notes count];
}

- (id)objectInNotesAtIndex:(unsigned)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)theIndex {
    [notes insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(unsigned)theIndex {
    [notes removeObjectAtIndex:theIndex];
}

- (SKMainWindowController *)mainWindowController {
    NSArray *windowControllers = [self windowControllers];
    return [windowControllers count] ? [windowControllers objectAtIndex:0] : nil;
}

- (PDFDocument *)pdfDocument{
    return [[self mainWindowController] pdfDocument];
}

@end


@implementation SKDocumentController

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType {
	NSString *type = [super typeFromFileExtension:fileExtensionOrHFSFileType];
    if ([type isEqualToString:SKEmbeddedPDFDocumentType] || [type isEqualToString:SKBarePDFDocumentType]) {
        // fix of bug when reading a PDF file
        // this is interpreted as SKEmbeddedPDFDocumentType, even though we don't declare that as a readable type
        type = NSPDFPboardType;
    }
	return type;
}

- (void)closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo{
    NSArray *fileNames = [[[NSDocumentController sharedDocumentController] documents] valueForKeyPath:@"@distinctUnionOfObjects.fileName"];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[fileNames count]];
    NSEnumerator *fEnum = [fileNames objectEnumerator];
    NSString *fileName;
    while(fileName = [fEnum nextObject]){
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        if(data)
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", data, @"_BDAlias", nil]];
        else
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", nil]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:SKLastOpenFileNamesKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerWillCloseDocumentsNotification object:self];
    
    [super closeAllDocumentsWithDelegate:delegate didCloseAllSelector:didCloseAllSelector contextInfo:contextInfo];
}

@end

