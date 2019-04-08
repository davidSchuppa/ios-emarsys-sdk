//
//  Copyright © 2019 Emarsys. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "EMSPushV3Internal.h"
#import "EMSRequestManager.h"
#import "EMSRequestFactory.h"
#import "NSData+MobileEngine.h"
#import "NSDictionary+MobileEngage.h"
#import "NSError+EMSCore.h"
#import "EMSNotificationCache.h"
#import "EMSTimestampProvider.h"

@interface EMSPushV3InternalTests : XCTestCase

@property(nonatomic, strong) EMSPushV3Internal *push;
@property(nonatomic, strong) EMSRequestManager *mockRequestManager;
@property(nonatomic, strong) EMSRequestFactory *mockRequestFactory;
@property(nonatomic, strong) EMSNotificationCache *mockNotificationCache;
@property(nonatomic, strong) EMSTimestampProvider *mockTimestampProvider;

@end

@implementation EMSPushV3InternalTests

- (void)setUp {
    _mockRequestFactory = OCMClassMock([EMSRequestFactory class]);
    _mockRequestManager = OCMClassMock([EMSRequestManager class]);
    _mockNotificationCache = OCMClassMock([EMSNotificationCache class]);
    _mockTimestampProvider = OCMClassMock([EMSTimestampProvider class]);

    _push = [[EMSPushV3Internal alloc] initWithRequestFactory:self.mockRequestFactory
                                               requestManager:self.mockRequestManager
                                            notificationCache:self.mockNotificationCache
                                            timestampProvider:self.mockTimestampProvider];
}

- (void)testInit_requestFactory_mustNotBeNil {
    @try {
        [[EMSPushV3Internal alloc] initWithRequestFactory:nil
                                           requestManager:self.mockRequestManager
                                        notificationCache:self.mockNotificationCache
                                        timestampProvider:self.mockTimestampProvider];
        XCTFail(@"Expected Exception when requestFactory is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: requestFactory");
    }
}

- (void)testInit_requestManager_mustNotBeNil {
    @try {
        [[EMSPushV3Internal alloc] initWithRequestFactory:self.mockRequestFactory
                                           requestManager:nil
                                        notificationCache:self.mockNotificationCache
                                        timestampProvider:self.mockTimestampProvider];
        XCTFail(@"Expected Exception when requestManager is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: requestManager");
    }
}

- (void)testInit_notificationCache_mustNotBeNil {
    @try {
        [[EMSPushV3Internal alloc] initWithRequestFactory:self.mockRequestFactory
                                           requestManager:self.mockRequestManager
                                        notificationCache:nil
                                        timestampProvider:self.mockTimestampProvider];
        XCTFail(@"Expected Exception when notificationCache is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: notificationCache");
    }
}

- (void)testInit_timestampProvider_mustNotBeNil {
    @try {
        [[EMSPushV3Internal alloc] initWithRequestFactory:self.mockRequestFactory
                                           requestManager:self.mockRequestManager
                                        notificationCache:self.mockNotificationCache
                                        timestampProvider:nil];
        XCTFail(@"Expected Exception when timestampProvider is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: timestampProvider");
    }
}

- (void)testSetPushToken_requestFactory_calledWithProperPushToken {
    NSString *token = @"pushTokenString";

    [self.push setPushToken:[self pushTokenFromString:token]];

    OCMVerify([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]);
}

- (void)testSetPushToken_shouldNotCallRequestFactory_when_pushTokenIsNil {
    OCMReject([self.mockRequestFactory createPushTokenRequestModelWithPushToken:[OCMArg any]]);

    [self.push setPushToken:nil];
}

- (void)testSetPushToken_shouldNotCallRequestFactory_when_pushTokenStringIsNilOrEmpty {
    NSString *token = nil;

    OCMReject([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]);

    [self.push setPushToken:[self pushTokenFromString:token]];
}

- (void)testSetPushToken_shouldNotCallRequestManager_when_pushTokenIsNil {
    OCMReject([self.mockRequestManager submitRequestModel:[OCMArg any]
                                      withCompletionBlock:[OCMArg any]]);

    [self.push setPushToken:nil];
}

- (void)testSetPushToken {
    NSString *token = @"pushTokenString";
    id mockRequestModel = OCMClassMock([EMSRequestModel class]);

    OCMStub([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]).andReturn(mockRequestModel);

    [self.push setPushToken:[self pushTokenFromString:token]];

    OCMVerify([self.mockRequestManager submitRequestModel:mockRequestModel
                                      withCompletionBlock:[OCMArg any]]);
}

- (void)testSetPushTokenCompletionBlock_requestFactory_calledWithProperPushToken {
    NSString *token = @"pushTokenString";

    [self.push setPushToken:[self pushTokenFromString:token]
            completionBlock:nil];

    OCMVerify([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]);
}

- (void)testSetPushTokenCompletionBlock_shouldNotCallRequestFactory_when_pushTokenIsNil {
    OCMReject([self.mockRequestFactory createPushTokenRequestModelWithPushToken:[OCMArg any]]);

    [self.push setPushToken:nil
            completionBlock:nil];
}

- (void)testSetPushTokenCompletionBlock_shouldNotCallRequestFactory_when_pushTokenStringIsNilOrEmpty {
    NSString *token = nil;

    OCMReject([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]);

    [self.push setPushToken:[self pushTokenFromString:token]
            completionBlock:nil];
}

- (void)testSetPushTokenCompletionBlock_shouldNotCallRequestManager_when_pushTokenIsNil {
    OCMReject([self.mockRequestManager submitRequestModel:[OCMArg any]
                                      withCompletionBlock:[OCMArg any]]);

    [self.push setPushToken:nil
            completionBlock:nil];
}

- (void)testSetPushTokenCompletionBlock {
    NSString *token = @"pushTokenString";
    id mockRequestModel = OCMClassMock([EMSRequestModel class]);
    EMSCompletionBlock completionBlock = ^(NSError *error) {
    };

    OCMStub([self.mockRequestFactory createPushTokenRequestModelWithPushToken:token]).andReturn(mockRequestModel);

    [self.push setPushToken:[self pushTokenFromString:token]
            completionBlock:completionBlock];

    OCMVerify([self.mockRequestManager submitRequestModel:mockRequestModel
                                      withCompletionBlock:completionBlock]);
}

- (void)testTrackMessageOpenWithUserInfo_userInfo_mustNotBeNil {
    @try {
        [self.push trackMessageOpenWithUserInfo:nil];
        XCTFail(@"Expected Exception when userInfo is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: userInfo");
    }
}

- (void)testTrackMessageOpenWithUserInfo {
    NSDictionary *testUserInfo = @{@"testKey": @"testValue"};

    EMSPushV3Internal *partialMockPush = OCMPartialMock(self.push);

    [partialMockPush trackMessageOpenWithUserInfo:testUserInfo];

    OCMVerify([partialMockPush trackMessageOpenWithUserInfo:testUserInfo
                                            completionBlock:nil]);
}

- (void)testTrackMessageOpenWithUserInfoCompletionBlock_userInfo_mustNotBeNil {
    @try {
        [self.push trackMessageOpenWithUserInfo:nil
                                completionBlock:^(NSError *error) {
                                }];
        XCTFail(@"Expected Exception when userInfo is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: userInfo");
    }
}

- (void)testTrackMessageOpenWithUserInfoCompletionBlock {
    NSDictionary *mockUserInfo = OCMClassMock([NSDictionary class]);
    NSString *messageId = @"testMessageId";
    NSString *eventName = @"push:click";
    NSDictionary *eventAttributes = @{
            @"origin": @"main",
            @"sid": messageId
    };

    id mockRequestModel = OCMClassMock([EMSRequestModel class]);

    OCMStub([mockUserInfo messageId]).andReturn(messageId);
    OCMStub([self.mockRequestFactory createEventRequestModelWithEventName:eventName
                                                          eventAttributes:eventAttributes
                                                                eventType:EventTypeInternal]).andReturn(mockRequestModel);

    [self.push trackMessageOpenWithUserInfo:mockUserInfo completionBlock:nil];

    OCMVerify([self.mockRequestFactory createEventRequestModelWithEventName:eventName
                                                            eventAttributes:eventAttributes
                                                                  eventType:EventTypeInternal]);
    OCMVerify([self.mockRequestManager submitRequestModel:mockRequestModel
                                      withCompletionBlock:nil]);
}

- (void)testTrackMessageOpenWithUserInfoCompletionBlock_when_messageIdIsMissing {
    NSError *expectedError = [NSError errorWithCode:1400
                               localizedDescription:@"No messageId found!"];

    __block NSError *returnedError = nil;
    __block NSOperationQueue *usedOperationQueue = [NSOperationQueue new];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"waitForCompletionBlock"];
    [self.push trackMessageOpenWithUserInfo:@{}
                            completionBlock:^(NSError *error) {
                                returnedError = error;
                                usedOperationQueue = [NSOperationQueue currentQueue];
                                [expectation fulfill];
                            }];

    XCTWaiterResult waiterResult = [XCTWaiter waitForExpectations:@[expectation]
                                                          timeout:10];
    XCTAssertEqual(waiterResult, XCTWaiterResultCompleted);
    XCTAssertEqualObjects(returnedError, expectedError);
    XCTAssertEqualObjects(usedOperationQueue, [NSOperationQueue mainQueue]);
}

- (void)testTrackMessageOpenWithUserInfoCompletionBlock_cachesInboxNotifications {
    NSDictionary *userInfo = @{
            @"inbox": @(1)
    };
    NSDate *date = [NSDate date];

    OCMStub([self.mockTimestampProvider provideTimestamp]).andReturn(date);

    EMSNotification *expectedNotification = [[EMSNotification alloc] initWithUserInfo:userInfo
                                                                    timestampProvider:self.mockTimestampProvider];

    [self.push trackMessageOpenWithUserInfo:userInfo
                            completionBlock:nil];

    OCMVerify([self.mockNotificationCache cache:expectedNotification]);
}

- (void)testTrackMessageOpenWithUserInfoCompletionBlock_shouldNotCache_when_notInboxNotification {
    NSDictionary *userInfo = @{@"inbox": @(NO)};

    OCMReject([self.mockNotificationCache cache:[OCMArg any]]);

    [self.push trackMessageOpenWithUserInfo:userInfo
                            completionBlock:nil];
}

- (NSData *)pushTokenFromString:(NSString *)pushTokenString {
    NSData *mockData = OCMClassMock([NSData class]);
    OCMStub([mockData deviceTokenString]).andReturn(pushTokenString);
    return mockData;
}

@end