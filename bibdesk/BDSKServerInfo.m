//
//  BDSKServerInfo.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKServerInfo.h"
#import "BDSKSearchGroup.h"
#import "NSString_BDSKExtensions.h"


@implementation BDSKServerInfo

+ (id)defaultServerInfoWithType:(int)aType;
{
    return [[[[self class] alloc] initWithType:aType name:NSLocalizedString(@"New Server",@"")
                                          host:@"host.domain.com"
                                          port:@"0" database:@"database" 
                                      password:@"" username:@""] autorelease];
}

- (id)initWithType:(int)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser options:(NSDictionary *)opts;
{
    if (self = [super init]) {
        type = aType;
        name = [aName copy];
        if (type == BDSKSearchGroupEntrez) {
            host = nil;
            port = nil;
            database = [aDbase copy];
            password = nil;
            username = nil;
            options = nil;
        } else {
            host = [aHost copy];
            port = [aPort copy];
            database = [aDbase copy];
            password = [aPassword copy];
            username = [aUser copy];
            options = [opts copy];
        }
    }
    return self;
}

- (id)initWithType:(int)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser;
{
    return [self initWithType:aType name:aName host:aHost port:aPort database:aDbase password:aPassword username:aUser options:nil];
}

- (id)initWithType:(int)aType dictionary:(NSDictionary *)info;
{
    self = [self initWithType:aType
                         name:[[info objectForKey:@"name"] stringByUnescapingGroupPlistEntities]
                         host:[[info objectForKey:@"host"] stringByUnescapingGroupPlistEntities]
                         port:[[info objectForKey:@"port"] stringByUnescapingGroupPlistEntities]
                     database:[[info objectForKey:@"database"] stringByUnescapingGroupPlistEntities]
                     password:[[info objectForKey:@"password"] stringByUnescapingGroupPlistEntities]
                     username:[[info objectForKey:@"username"] stringByUnescapingGroupPlistEntities]
                      options:[info objectForKey:@"options"]];
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    id copy = [[[self class] allocWithZone:aZone] initWithType:[self type] name:[self name] host:[self host] port:[self port] database:[self database] password:[self password] username:[self username] options:[self options]];
    return copy;
}

- (void)dealloc {
    [name release];
    [host release];
    [port release];
    [database release];
    [password release];
    [username release];
    [options release];
    [super dealloc];
}

static inline BOOL BDSKIsEqualOrNil(id first, id second) {
    return (first == nil && second == nil) || [first isEqual:second];
}

- (BOOL)isEqual:(id)other {
    BOOL isEqual = NO;
    // we don't compare the name, as that is just a label
    if ([self isMemberOfClass:[other class]] == NO || [self type] != [(BDSKServerInfo *)other type])
        isEqual = NO;
    else if ([self type] == BDSKSearchGroupEntrez)
        isEqual = BDSKIsEqualOrNil([self database], [other database]);
    else
        isEqual = BDSKIsEqualOrNil([self host], [other host]) && BDSKIsEqualOrNil([self port], [other port]) && BDSKIsEqualOrNil([self database], [other database]) && BDSKIsEqualOrNil([self password], [other password]) && BDSKIsEqualOrNil([self username], [other username]);
    return isEqual;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:7];
    [info setValue:[NSNumber numberWithInt:[self type]] forKey:@"type"];
    [info setValue:[self name] forKey:@"name"];
    if ([self type] == BDSKSearchGroupEntrez) {
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
    } else {
        [info setValue:[[self host] stringByEscapingGroupPlistEntities] forKey:@"host"];
        [info setValue:[[self port] stringByEscapingGroupPlistEntities] forKey:@"port"];
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
        [info setValue:[[self password] stringByEscapingGroupPlistEntities] forKey:@"password"];
        [info setValue:[[self username] stringByEscapingGroupPlistEntities] forKey:@"username"];
        [info setValue:[self options] forKey:@"options"];
    }
    return info;
}

- (int)type { return type; }

- (NSString *)name { return name; }

- (NSString *)host { return host; }

- (NSString *)port { return port; }

- (NSString *)database { return database; }

- (NSString *)password { return password; }

- (NSString *)username { return username; }

- (NSDictionary *)options { return options; }

- (void)setType:(int)t { type = t; }

- (void)setName:(NSString *)s;
{
    [name autorelease];
    name = [s copy];
}

- (void)setPort:(NSString *)p;
{
    [port autorelease];
    port = [p copy];
}

- (void)setHost:(NSString *)h;
{
    [host autorelease];
    host = [h copy];
}

- (void)setDatabase:(NSString *)d;
{
    [database autorelease];
    database = [d copy];
}

- (void)setPassword:(NSString *)p;
{
    [password autorelease];
    password = [p copy];
}

- (void)setUsername:(NSString *)u;
{
    [username autorelease];
    username = [u copy];
}

- (void)setOptions:(NSDictionary *)o;
{
    [options autorelease];
    options = [o copy];
}

- (BOOL)validateHost:(id *)value error:(NSError **)error {
    NSString *string = *value;
    NSRange range = [string rangeOfString:@"://"];
    if(range.location != NSNotFound){
        // ZOOM gets confused when the host has a protocol
        string = [string substringFromIndex:NSMaxRange(range)];
    }
    // split address:port/dbase in components
    range = [string rangeOfString:@"/"];
    if(range.location != NSNotFound){
        [self setDatabase:[string substringFromIndex:NSMaxRange(range)]];
        string = [string substringToIndex:range.location];
    }
    range = [string rangeOfString:@":"];
    if(range.location != NSNotFound){
        [self setPort:[string substringFromIndex:NSMaxRange(range)]];
        string = [string substringToIndex:range.location];
    }
    *value = string;
    return YES;
}

- (BOOL)validatePort:(id *)value error:(NSError **)error {
    if (nil != *value)
    *value = [NSString stringWithFormat:@"%i", [*value intValue]];
    return YES;
}


@end
