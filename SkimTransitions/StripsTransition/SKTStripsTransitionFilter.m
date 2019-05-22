//
//  SKTStripsTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTStripsTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTStripsTransitionFilter

static CIKernel *_SKTStripsTransitionFilterKernel = nil;

- (id)init
{
    if(_SKTStripsTransitionFilterKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKTStripsTransitionFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKTStripsTransitionFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKTStripsTransitionFilterKernel = [kernels firstObject];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,          kCIAttributeType,
            nil],                               @"inputExtent",
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  0.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  100.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  50.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeScalar,            kCIAttributeType,
            nil],                              @"inputWidth",
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeTime,              kCIAttributeType,
            nil],                              @"inputTime",

        nil];
}

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(NSArray *)array {
    if (sampler == 0) {
        CGRect extent = [[array objectAtIndex:0] extent];
        CGFloat offset = [[array objectAtIndex:1] doubleValue];
        R = CGRectIntersection(extent, CGRectUnion(CGRectOffset(R, offset, 0.0), CGRectOffset(R, -offset, 0.0)));
    }
    return R;
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *trgt = [CISampler samplerWithImage:inputTargetImage];
    NSNumber *offset = [NSNumber numberWithDouble:[inputExtent Z] * [inputTime doubleValue]];
    NSArray *extent = [NSArray arrayWithObjects:[NSNumber numberWithDouble:[inputExtent X]], [NSNumber numberWithDouble:[inputExtent Y]], [NSNumber numberWithDouble:[inputExtent Z]], [NSNumber numberWithDouble:[inputExtent W]], nil];
    NSArray *arguments = [NSArray arrayWithObjects:src, trgt, inputExtent, inputWidth, inputTime, nil];
    NSArray *userInfo = [NSArray arrayWithObjects:src, offset, nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:extent, kCIApplyOptionDefinition, extent, kCIApplyOptionExtent, userInfo, kCIApplyOptionUserInfo, nil];
    
    [_SKTStripsTransitionFilterKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    
    return [self apply:_SKTStripsTransitionFilterKernel arguments:arguments options:options];
}

@end
