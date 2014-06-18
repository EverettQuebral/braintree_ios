#import "BTClient.h"
#import "BTClient_Internal.h"
#import "BTClientToken.h"
#import "BTLogger.h"
#import "BTMutablePaymentMethod.h"
#import "BTMutablePayPalPaymentMethod.h"
#import "BTMutableCardPaymentMethod.h"
#import "BTHTTP.h"
#import "BTOfflineModeURLProtocol.h"

NSString *const BTClientChallengeResponseKeyPostalCode = @"postal_code";
NSString *const BTClientChallengeResponseKeyCVV = @"cvv";

@interface BTClient ()

@property (nonatomic, strong) NSMutableArray *analyticsEventQueue;

@end

@implementation BTClient

- (instancetype)initWithClientToken:(NSString *)clientTokenString {
    if(![clientTokenString isKindOfClass: NSString.class]){
        NSString *reason = @"BTClient could not initialize because the provided clientToken was of an invalid type";
        [[BTLogger sharedLogger] log:reason];

        return nil;
    }
    self = [self init];
    if (self) {
        NSError *error;
        self.clientToken = [[BTClientToken alloc] initWithClientTokenString:clientTokenString error:&error];
        if (!self.clientToken) {
            NSString *reason = @"BTClient could not initialize because the provided clientToken was invalid";
            [[BTLogger sharedLogger] log:reason];
#ifdef DEBUG
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
#endif
            return nil;
        }

        self.http = [[BTHTTP alloc] initWithBaseURL:self.clientToken.clientApiURL];
        [self.http setProtocolClasses:@[[BTOfflineModeURLProtocol class]]];
        self.analyticsEventQueue = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Configuration

- (NSSet *)challenges {
    return self.clientToken.challenges;
}


#pragma mark - API Methods

- (void)fetchPaymentMethodsWithSuccess:(BTClientPaymentMethodListSuccessBlock)successBlock
                               failure:(BTClientFailureBlock)failureBlock {
    NSDictionary *parameters = @{
                                 @"authorization_fingerprint": self.clientToken.authorizationFingerprint,
                                 };

    [self.http GET:@"v1/payment_methods" parameters:parameters completion:^(BTHTTPResponse *response, NSError *error) {
        if (response.isSuccess) {
            if (successBlock) {
                NSArray *responsePaymentMethods = response.object[@"paymentMethods"];

                NSMutableArray *paymentMethods = [NSMutableArray array];
                for (NSDictionary *paymentMethodDictionary in responsePaymentMethods) {
                    BTPaymentMethod *paymentMethod = [[self class] paymentMethodFromAPIResponseDictionary:paymentMethodDictionary];
                    if (paymentMethod == nil) {
                        NSLog(@"Unable to create payment method from %@", paymentMethodDictionary);
                    } else {
                        [paymentMethods addObject:paymentMethod];
                    }
                }

                successBlock(paymentMethods);
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

- (void)saveCardWithNumber:(NSString *)creditCardNumber
           expirationMonth:(NSString *)expirationMonth
            expirationYear:(NSString *)expirationYear
                       cvv:(NSString *)cvv
                postalCode:(NSString *)postalCode
                  validate:(BOOL)shouldValidate
                   success:(BTClientCardSuccessBlock)successBlock
                   failure:(BTClientFailureBlock)failureBlock {

    NSMutableDictionary *creditCardParams = [@{ @"number": creditCardNumber,
                                               @"expiration_month": expirationMonth,
                                               @"expiration_year": expirationYear,
                                               @"options": @{
                                                       @"validate": @(shouldValidate)
                                                       }
                                                } mutableCopy];
    
    NSMutableDictionary *requestParameters = [@{ @"credit_card": creditCardParams,
                                                 @"authorization_fingerprint": self.clientToken.authorizationFingerprint }
                                              mutableCopy];

    if (cvv) {
        requestParameters[@"credit_card"][@"cvv"] = cvv;
    }

    if (postalCode) {
        requestParameters[@"billing_address"] = @{ @"postal_code": postalCode };
    }

    [self.http POST:@"v1/payment_methods/credit_cards" parameters:requestParameters completion:^(BTHTTPResponse *response, NSError *error) {
        if (response.isSuccess) {
            NSDictionary *creditCardResponse = response.object[@"creditCards"][0];
            BTCardPaymentMethod *paymentMethod = [[self class] cardFromAPIResponseDictionary:creditCardResponse];

            if (successBlock) {
                successBlock(paymentMethod);
            }
        } else {
            NSError *returnedError = error;
            if (error.domain == BTBraintreeAPIErrorDomain && error.code == BTCustomerInputErrorInvalid) {
                returnedError = [NSError errorWithDomain:error.domain
                                                    code:error.code
                                                userInfo:@{BTCustomerInputBraintreeValidationErrorsKey: response.object}];
            }
            if (failureBlock) {
                failureBlock(returnedError);
            }
        }
    }];
}

- (void)savePaypalPaymentMethodWithAuthCode:(NSString*)authCode
                                    success:(BTClientPaypalSuccessBlock)successBlock
                                    failure:(BTClientFailureBlock)failureBlock{

    NSDictionary *requestParameters = @{@"paypal_account": @{
                                                @"consent_code": authCode
                                                },
                                        @"authorization_fingerprint": self.clientToken.authorizationFingerprint
                                        };

    [self.http POST:@"v1/payment_methods/paypal_accounts" parameters:requestParameters completion:^(BTHTTPResponse *response, NSError *error){
        if (response.isSuccess) {
            if (successBlock){
                NSDictionary *paypalPaymentMethodResponse = response.object[@"paypalAccounts"][0];
                BTPayPalPaymentMethod *payPalPaymentMethod = [[self class] payPalPaymentMethodFromAPIResponseDictionary:paypalPaymentMethodResponse];
                successBlock(payPalPaymentMethod);
            }
        } else {
            if (failureBlock) {
                failureBlock([NSError errorWithDomain:error.domain code:BTUnknownError userInfo:nil]);
            }
        }
    }];
}

- (void)postAnalyticsEvent:(NSString *)eventKind
                   success:(BTClientAnalyticsSuccessBlock)successBlock
                   failure:(BTClientFailureBlock)failureBlock {

    [self enqueueAnalyticsEvent:eventKind];

    if ([self shouldTransmitAnalyticsEventQueue]) {
        NSMutableArray *events = [NSMutableArray array];
        NSMutableArray *eventKinds = [NSMutableArray array];
        for (NSString *eventKind in [self dequeueAllAnalyticsEvents]) {
            [eventKinds addObject:eventKind];
            [events addObject:@{ @"kind": eventKind }];
        }
        NSDictionary *requestParameters = @{ @"analytics": events,
                                             @"authorization_fingerprint": self.clientToken.authorizationFingerprint };

        [self.http POST:@"v1/analytics"
             parameters:requestParameters
             completion:^(BTHTTPResponse *response, NSError *error) {
                 if (response.isSuccess) {
                     if (successBlock) {
                         successBlock(eventKinds);
                     }
                 } else {
                     if (failureBlock) {
                         failureBlock(error);
                     }
                 }
             }];
    } else {
        if (successBlock) {
            successBlock(@[]);
        }
    }
}

#pragma mark - Response Parsing

+ (BTPaymentMethod *)paymentMethodFromAPIResponseDictionary:(NSDictionary *)response {
    if ([response[@"type"] isEqual:@"CreditCard"]) {
        return [self cardFromAPIResponseDictionary:response];
    } else if ([response[@"type"] isEqual:@"PayPalAccount"]) {
        return [self payPalPaymentMethodFromAPIResponseDictionary:response];
    } else {
        return nil;
    }
}

+ (BTPayPalPaymentMethod *)payPalPaymentMethodFromAPIResponseDictionary:(NSDictionary *)response {
    BTMutablePayPalPaymentMethod *payPalPaymentMethod;
    if ([response respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        payPalPaymentMethod             = [BTMutablePayPalPaymentMethod new];
        payPalPaymentMethod.nonce       = response[@"nonce"];
        payPalPaymentMethod.locked      = [response[@"isLocked"] boolValue];
        payPalPaymentMethod.email       = response[@"details"][@"email"];
        payPalPaymentMethod.description = response[@"description"];
    }
    return payPalPaymentMethod;
}

+ (BTCardPaymentMethod *)cardFromAPIResponseDictionary:(NSDictionary *)responseObject {
    BTMutableCardPaymentMethod *card = [[BTMutableCardPaymentMethod alloc] init];

    card.description        = responseObject[@"description"];
    card.typeString         = responseObject[@"details"][@"cardType"];
    card.lastTwo            = responseObject[@"details"][@"lastTwo"];
    card.locked             = [responseObject[@"isLocked"] boolValue];
    card.nonce              = responseObject[@"nonce"];
    card.challengeQuestions = [NSSet setWithArray:responseObject[@"securityQuestions"]];

    return card;
}

#pragma mark - Analytics Helpers

- (void)enqueueAnalyticsEvent:(id)analyticsEvent {
    if (self.clientToken.analyticsBatchSize != BTClientTokenAnalyticsBatchSizeDisabled) {
        [self.analyticsEventQueue addObject:analyticsEvent];
    }
}

- (BOOL)shouldTransmitAnalyticsEventQueue {
    return self.analyticsEventQueue.count >= [self.clientToken analyticsBatchSize];
}

- (NSArray *)dequeueAllAnalyticsEvents {
    NSArray *analyticsEvents = [self.analyticsEventQueue copy];
    [self.analyticsEventQueue removeAllObjects];
    return analyticsEvents;
}

#pragma mark - Debug

- (NSString *)description {
    return [NSString stringWithFormat:@"<BTClient:%p http:%@>", self, self.http];
}

#pragma mark - Library Version

+ (NSString *)libraryVersion {
#if defined(COCOAPODS) && defined(COCOAPODS_VERSION_MAJOR_Braintree_api) && defined(COCOAPODS_VERSION_MINOR_Braintree_api) && defined(COCOAPODS_VERSION_PATCH_Braintree_api)
    return [NSString stringWithFormat:@"%d.%d.%d",
            COCOAPODS_VERSION_MAJOR_Braintree_api,
            COCOAPODS_VERSION_MINOR_Braintree_api,
            COCOAPODS_VERSION_PATCH_Braintree_api];
#else
#ifdef DEBUG
    return @"development";
#else
    return @"unknown";
#endif
#endif
}

@end
