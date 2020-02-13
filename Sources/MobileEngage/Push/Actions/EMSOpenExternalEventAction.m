//
// Copyright (c) 2020 Emarsys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMSOpenExternalEventAction.h"

@interface EMSOpenExternalEventAction ()

@property(nonatomic, strong) UIApplication *application;
@property(nonatomic, strong) NSDictionary *action;

@end

@implementation EMSOpenExternalEventAction

- (instancetype)initWithActionDictionary:(NSDictionary<NSString *, id> *)action
                             application:(UIApplication *)application {
    NSParameterAssert(action);
    NSParameterAssert(application);
    if (self = [super init]) {
        _action = action;
        _application = application;
    }
    return self;
}

- (void)execute {
    NSString *urlString = self.action[@"url"];
    if (urlString) {
        [self.application openURL:[[NSURL alloc] initWithString:urlString]
                          options:@{}
                completionHandler:nil];
    }
}

@end