//
//  NSFileManager_ExtendedAttributes.h
//
//  Created by Adam R. Maxwell on 05/12/05.
//  Copyright 2005 Adam R. Maxwell. All rights reserved.
//
/*
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this 
 list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or 
 other materials provided with the distribution.
 - Neither the name of Adam R. Maxwell nor the names of any contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

/*!
    @category    NSFileManager (ExtendedAttributes)
    @abstract    Provides an Objective-C wrapper for the low-level BSD functions dealing with file attributes.
    @discussion  (comprehensive description)
*/
@interface NSFileManager (ExtendedAttributes)

/*!
    @method     extendedAttributeNamesAtPath:traverseLink:
    @abstract   Return a list of extended attributes for the given file.
    @discussion Calls <tt>listxattr(2)</tt> to determine all of the extended attributes, and returns them as
                an array of NSString objects.  Returns nil if an error occurs.    
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>listxattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Array of strings or nil.
*/
- (NSArray *)extendedAttributeNamesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     extendedAttributeNamed:atPath:traverseLink:error:
    @abstract   Return the extended attribute named <tt>attr</tt> for a given file.
    @discussion Calls <tt>getxattr(2)</tt> to determine the extended attribute, and returns it as data.
    @param      attr The attribute name.
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>getxattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Data object representing the extended attribute or nil if an error occurred.
*/
- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     allExtendedAttributesAsStringsAtPath:traverseLink:error:
    @abstract   Returns all extended attributes for the given file, converting each to an NSString object.
    @discussion (comprehensive description)
    @param      path (description)
    @param      follow (description)
    @param      error (description)
    @result     (description)
*/
- (NSArray *)allExtendedAttributesAsStringsAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     allExtendedAttributesAtPath:traverseLink:error:
    @abstract   Returns all extended attributes for the given file, each as an NSData object.
    @discussion (comprehensive description)
    @param      path (description)
    @param      follow (description)
    @param      error (description)
    @result     (description)
*/
- (NSArray *)allExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     setExtendedAttributeNamed:toValue:atPath:options:error:
    @abstract   Sets the value of attribute named <tt>attr</tt> to <tt>value</tt>, which is an NSData object.
    @discussion Calls <tt>setxattr(2)</tt> to set the attributes for the file.
    @param      attr The attribute name.
    @param      value The value of the attribute as NSData.
    @param      path Path to the object in the file system.
    @param      options Dictionary containing three BOOL keys, or nil for default options of <tt>setxattr(2)</tt>.
                The key strings are <tt>@"FollowLinks"</tt> to traverse symlinks, <tt>@"CreateOnly"</tt> to create, but
                not replace the attribute, and <tt>@"ReplaceOnly"</tt> to replace, but not create the attribute.
    @param      error Error object describing the error if NO was returned.
    @result     Returns NO if an error occurred.
*/
- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(NSDictionary *)options error:(NSError **)error;

/*!
    @method     addExtendedAttributeNamed:withValue:atPath:error:
    @abstract   Adds the extended attribute named <tt>attr</tt> with a value of <tt>value</tt> to the given file.
                Returns NO if an error occurred or the named attribute already exists.
    @discussion (comprehensive description)
    @param      attr The attribute name.
    @param      value The value of the attribute as NSData.
    @param      path Path to the object in the file system.
    @param      error Error object describing the error if NO was returned.
    @result     Returns NO if an error occurred.

*/
- (BOOL)addExtendedAttributeNamed:(NSString *)attr withValue:(NSData *)value atPath:(NSString *)path error:(NSError **)error;

/*!
    @method     addExtendedAttributeNamed:withStringValue:atPath:error:
    @abstract   Adds an NSString object as the specified attribute name.
    @discussion (comprehensive description)
    @param      attr (description)
    @param      value (description)
    @param      path (description)
    @param      error (description)
    @result     (description)
*/
- (BOOL)addExtendedAttributeNamed:(NSString *)attr withStringValue:(NSString *)value atPath:(NSString *)path error:(NSError **)error;

/*!
    @method     replaceExtendedAttributeNamed:withValue:atPath:error:
    @abstract   Replaces the attributed name <tt>attr</tt> with a value of <tt>value</tt> for the given file.
                Returns NO if an error occurred or the named attribute does not exist.
    @discussion (comprehensive description)
    @param      attr The attribute name.
    @param      value The value of the attribute as NSData.
    @param      path Path to the object in the file system.
    @param      error Error object describing the error if NO was returned.
    @result     Returns NO if an error occurred.
*/
- (BOOL)replaceExtendedAttributeNamed:(NSString *)attr withValue:(NSData *)value atPath:(NSString *)path error:(NSError **)error;

/*!
    @method     replaceExtendedAttributeNamed:withStringValue:atPath:error:
    @abstract   Convenience for replacing string attributes on a file
    @discussion (comprehensive description)
    @param      attr (description)
    @param      value (description)
    @param      path (description)
    @param      error (description)
    @result     (description)
*/
- (BOOL)replaceExtendedAttributeNamed:(NSString *)attr withStringValue:(NSString *)value atPath:(NSString *)path error:(NSError **)error;

/*!
    @method     removeExtendedAttribute:atPath:followLinks:error:
    @abstract   Removes the given attribute <tt>attr</tt> from the named file at <tt>path</tt>.
    @discussion Calls <tt>removexattr(2)</tt> to remove the given attribute from the file.
    @param      attr The attribute name.
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>removexattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Returns NO if an error occurred.
*/
- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

@end

@class PDFMetadata;

@interface NSFileManager (PDFMetadata)

- (id)PDFMetadataForURL:(NSURL *)fileURL error:(NSError **)outError;
- (BOOL)addPDFMetadata:(PDFMetadata *)attributes toURL:(NSURL *)fileURL error:(NSError **)outError;

@end

