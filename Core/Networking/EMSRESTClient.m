//
//  Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "EMSRESTClient.h"
#import "NSURLRequest+EMSCore.h"
#import "NSError+EMSCore.h"
#import "EMSResponseModel.h"
#import "EMSCompositeRequestModel.h"
#import "EMSTimestampProvider.h"
#import "EMSMacros.h"
#import "EMSInDatabaseTime.h"
#import "EMSNetworkingTime.h"

@interface EMSRESTClient () <NSURLSessionDelegate>

@property(nonatomic, strong) CoreSuccessBlock successBlock;
@property(nonatomic, strong) CoreErrorBlock errorBlock;
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) EMSTimestampProvider *timestampProvider;

@end

@implementation EMSRESTClient

- (instancetype)initWithSession:(NSURLSession *)session
                          queue:(NSOperationQueue *)queue
              timestampProvider:(EMSTimestampProvider *)timestampProvider {
    NSParameterAssert(session);
    NSParameterAssert(queue);
    NSParameterAssert(timestampProvider);
    if (self = [super init]) {
        _session = session;
        _queue = queue;
        _timestampProvider = timestampProvider;
    }
    return self;
}

- (void)executeWithRequestModel:(EMSRequestModel *)requestModel
          coreCompletionHandler:(id <EMSCoreCompletionHandlerProtocol>)completionHandler {
    NSParameterAssert(requestModel);
    NSParameterAssert(completionHandler);
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:[NSURLRequest requestWithRequestModel:requestModel]
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     [weakSelf.queue addOperationWithBlock:^{
                                                         NSError *runtimeError = [weakSelf errorWithData:data
                                                                                                response:response
                                                                                                   error:error];
                                                         if (runtimeError) {
                                                             if (completionHandler.errorBlock) {
                                                                 completionHandler.errorBlock(requestModel.requestId, runtimeError);
                                                             }
                                                         } else {
                                                             EMSResponseModel *responseModel = [[EMSResponseModel alloc] initWithHttpUrlResponse:(NSHTTPURLResponse *) response
                                                                                                                                            data:data
                                                                                                                                    requestModel:requestModel
                                                                                                                                       timestamp:[weakSelf.timestampProvider provideTimestamp]];
                                                             if (completionHandler.successBlock) {
                                                                 completionHandler.successBlock(requestModel.requestId, responseModel);
                                                             }
                                                         }
                                                     }];
                                                 }];

    [task resume];
}

- (NSError *)errorWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    NSError *runtimeError = error;
    if (!error) {
        if (!response) {
            runtimeError = [NSError errorWithCode:1500
                             localizedDescription:@"Missing response"];
        }
        if (!data) {
            runtimeError = [NSError errorWithCode:1500
                             localizedDescription:@"Missing data"];
        }
    }
    return runtimeError;
}


- (instancetype)initWithSuccessBlock:(CoreSuccessBlock)successBlock
                          errorBlock:(CoreErrorBlock)errorBlock
                             session:(NSURLSession *)session
                   timestampProvider:(EMSTimestampProvider *)timestampProvider {
    if (self = [super init]) {
        NSParameterAssert(successBlock);
        NSParameterAssert(errorBlock);
        NSParameterAssert(timestampProvider);
        _successBlock = successBlock;
        _errorBlock = errorBlock;
        _timestampProvider = timestampProvider;
        if (session) {
            _session = session;
        } else {
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            [sessionConfiguration setTimeoutIntervalForRequest:30.0];
            [sessionConfiguration setHTTPCookieStorage:nil];
            NSOperationQueue *operationQueue = [NSOperationQueue new];
            [operationQueue setMaxConcurrentOperationCount:1];
            _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:operationQueue];
        }
    }
    return self;
}

- (void)executeTaskWithRequestModel:(EMSRequestModel *)requestModel
                       successBlock:(CoreSuccessBlock)successBlock
                         errorBlock:(CoreErrorBlock)errorBlock {
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task =
        [self.session dataTaskWithRequest:[NSURLRequest requestWithRequestModel:requestModel]
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *) response;
                            NSInteger statusCode = httpUrlResponse.statusCode;
                            const BOOL hasError = error || statusCode < 200 || statusCode > 299;
                            if (errorBlock && hasError) {
                                errorBlock(requestModel.requestId,
                                    error ? error : [weakSelf    errorWithData:data
                                                                 statusCode:statusCode]);
                            }
                            if (successBlock && !hasError) {
                                successBlock(requestModel.requestId, [[EMSResponseModel alloc] initWithHttpUrlResponse:httpUrlResponse
                                                                                                                  data:data
                                                                                                          requestModel:requestModel
                                                                                                             timestamp:[self.timestampProvider provideTimestamp]]);
                            }
                        }];
    [task resume];
}

- (void)executeTaskWithOfflineCallbackStrategyWithRequestModel:(EMSRequestModel *)requestModel
                                                    onComplete:(EMSRestClientCompletionBlock)onComplete {
    NSParameterAssert(onComplete);
    __weak typeof(self) weakSelf = self;
    NSDate *networkingStartTime = [self.timestampProvider provideTimestamp];
    NSOperationQueue *currentQueue = [NSOperationQueue currentQueue];
    NSURLSessionDataTask *task =
        [self.session dataTaskWithRequest:[NSURLRequest requestWithRequestModel:requestModel]
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            [currentQueue addOperationWithBlock:^{
                                [weakSelf handleResponse:requestModel
                                                    data:data
                                                response:response
                                     networkingStartTime:networkingStartTime
                                                   error:error
                                              onComplete:onComplete];
                            }];
                        }];
    [task resume];
}

- (void)handleResponse:(EMSRequestModel *)requestModel
                  data:(NSData *)data
              response:(NSURLResponse *)response
   networkingStartTime:(NSDate *)networkingStartTime
                 error:(NSError *)error
            onComplete:(EMSRestClientCompletionBlock)onComplete {
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *) response;
    NSInteger statusCode = httpUrlResponse.statusCode;
    const BOOL hasError = error || statusCode < 200 || statusCode > 299;
    const BOOL nonRetriableRequest = [self isStatusCodeNonRetriable:statusCode] || [self isErrorNonRetriable:error];

    if (onComplete) {
        const BOOL shouldContinue = !hasError || nonRetriableRequest;
        onComplete(shouldContinue);
    }

    if (self.errorBlock && nonRetriableRequest) {
        [self executeErrorBlockWithModel:requestModel
                            responseData:data
                              statusCode:statusCode
                                   error:error];
    }
    if (self.successBlock && !hasError) {
        [self executeSuccessBlockWithModel:requestModel
                              responseData:data
                                  response:httpUrlResponse
                       networkingStartTime:networkingStartTime];
    }
}

- (void)executeSuccessBlockWithModel:(EMSRequestModel *)requestModel
                        responseData:(NSData *)data
                            response:(NSHTTPURLResponse *)httpUrlResponse
                 networkingStartTime:(NSDate *)networkingStartTime {
    if ([requestModel isKindOfClass:[EMSCompositeRequestModel class]]) {
        NSArray<EMSRequestModel *> *originalRequests = [(EMSCompositeRequestModel *) requestModel originalRequests];
        for (EMSRequestModel *originalRequest in originalRequests) {
            EMSResponseModel *responseModel = [[EMSResponseModel alloc] initWithHttpUrlResponse:httpUrlResponse
                                                                                           data:data
                                                                                   requestModel:requestModel
                                                                                      timestamp:[self.timestampProvider provideTimestamp]];
            [self logWithRequestModel:originalRequest
                        responseModel:responseModel
                  networkingStartTime:networkingStartTime];
            self.successBlock(originalRequest.requestId, responseModel);
        }
    } else {
        EMSResponseModel *responseModel = [[EMSResponseModel alloc] initWithHttpUrlResponse:httpUrlResponse
                                                                                       data:data
                                                                               requestModel:requestModel
                                                                                  timestamp:[self.timestampProvider provideTimestamp]];
        [self logWithRequestModel:requestModel
                    responseModel:responseModel
              networkingStartTime:networkingStartTime];
        self.successBlock(requestModel.requestId, responseModel);
    }
}

- (void)executeErrorBlockWithModel:(EMSRequestModel *)requestModel
                      responseData:(NSData *)data
                        statusCode:(NSInteger)statusCode
                             error:(NSError *)error {
    error = error ? error : [self errorWithData:data
                                     statusCode:statusCode];
    if ([requestModel isKindOfClass:[EMSCompositeRequestModel class]]) {
        NSArray<EMSRequestModel *> *originalRequests = [(EMSCompositeRequestModel *) requestModel originalRequests];
        for (EMSRequestModel *request in originalRequests) {
            self.errorBlock(request.requestId, error);
        }
    } else {
        self.errorBlock(requestModel.requestId, error);
    }
}

- (BOOL)isErrorNonRetriable:(NSError *)error {
    return error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorBadURL || error.code == NSURLErrorUnsupportedURL;
}

- (BOOL)isStatusCodeNonRetriable:(NSInteger)statusCode {
    if (statusCode == 408) return NO;
    return statusCode >= 400 && statusCode < 500;
}

- (NSError *)errorWithData:(NSData *)data
                statusCode:(NSInteger)statusCode {
    NSString *description =
        data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"Unknown error";
    return [NSError errorWithCode:@(statusCode).intValue
             localizedDescription:description];
}

- (void)logWithRequestModel:(EMSRequestModel *)requestModel
              responseModel:(EMSResponseModel *)responseModel
        networkingStartTime:(NSDate *)networkingStartTime {
    EMSLog([[EMSInDatabaseTime alloc] initWithRequestModel:requestModel endDate:networkingStartTime]);

    EMSLog([[EMSNetworkingTime alloc] initWithResponseModel:responseModel startDate:networkingStartTime]);
}

@end
