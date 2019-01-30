//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "EMSDeviceInfo.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>

@interface EMSDeviceInfo ()

@end

@implementation EMSDeviceInfo

#define kEMSHardwareIdKey @"kHardwareIdKey"
#define kEMSSuiteName @"com.emarsys.core"

- (instancetype)initWithSDKVersion:(NSString *)sdkVersion {
    NSParameterAssert(sdkVersion);
    if (self = [super init]) {
        _sdkVersion = sdkVersion;
    }
    return self;
}

- (NSString *)platform {
    return @"ios";
}

- (NSString *)timeZone {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    formatter.dateFormat = @"xxxx";
    return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)languageCode {
    return [NSLocale preferredLanguages][0];
}

- (NSString *)applicationVersion {
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return @(systemInfo.machine);
}

- (NSString *)deviceType {
    NSDictionary *idiomDict = @{
            @(UIUserInterfaceIdiomUnspecified): @"UnspecifiediOS",
            @(UIUserInterfaceIdiomPhone): @"iPhone",
            @(UIUserInterfaceIdiomPad): @"iPad",
            @(UIUserInterfaceIdiomTV): @"AppleTV",
            @(UIUserInterfaceIdiomCarPlay): @"iPhone"
    };
    return idiomDict[@([UIDevice.currentDevice userInterfaceIdiom])];
}

- (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)systemName {
    return [UIDevice currentDevice].systemName;
}

- (NSString *)hardwareId {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kEMSSuiteName];
    NSString *hardwareId = [userDefaults objectForKey:kEMSHardwareIdKey];

    if (!hardwareId) {
        hardwareId = [self getNewHardwareId];
        [userDefaults setObject:hardwareId forKey:kEMSHardwareIdKey];
        [userDefaults synchronize];
    }

    return hardwareId;
}

- (NSString *)getNewHardwareId {
    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier]
                UUIDString];
    }
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

@end