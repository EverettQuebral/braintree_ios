//
//  BTIdeal.m
//  Braintree
//
//  Created by Everett Quebral on 9/29/15.
//
//

#import "BTIdeal.h"

#import "BTAppSwitch.h"
#import "BTClient_Internal.h"
#import "BTAppSwitchErrors.h"
#import "BTIdealOAuth.h"

@interface BTIdeal()

@property (nonatomic, strong) BTClient *client;
@property (nonatomic, assign) BTIdealOAuthAuthenticationMechanism authenticationMechanism;

@end

@implementation BTIdeal


@synthesize returnURLScheme = _returnURLScheme;
@synthesize redirectURL = _redirectURL;
@synthesize delegate = _delegate;

+ (void) load {
    if (self == [BTIdeal class]){
        [[BTAppSwitch sharedInstance] addAppSwitching:[BTIdeal sharedIdeal] forApp:BTAppTypeIdeal];
    }
}

+ (instancetype) sharedIdeal {
    static BTIdeal *ideal;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        ideal = [[self alloc] init];
    });
    return ideal;
}

- (BOOL) providerAppSwitchAvailableForClient:(BTClient *)client{
    return self.returnURLScheme && [self appSwitchAvailableForClient:client] && [BTIdealOAuth isAppOAuthAuthenticationAvailable];
}

- (BOOL) isProviderAppInstalled {
    return [BTIdealOAuth isAppOAuthAuthenticationAvailable];
}

#pragma mark Helpers

- (NSURL *) redirectUri {
    /// this is going to be challenging on the Ideal case as we don't really know what will
    /// be the final return URL, unless we put the createPayment request here
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = [self returnURLScheme];
    components.path = @"/weneedtheurlhere";
    components.host = @"x-callback-url";
    return [components URL];
}

#pragma mark BTAppSwitching

- (BOOL) appSwitchAvailableForClient:(BTClient *)client {
    return client.configuration.idealEnabled == YES && self.disabled == NO;
}


//// interface that will be called to start the app switching and will be opened up as
//// 
- (BOOL) initiateAppSwitchWithClient:(BTClient *)client delegate:(id<BTAppSwitchingDelegate>)delegate error:(NSError * _Nullable __autoreleasing *)error {
    
    //// WE HAVE A PROBLEM HERE
    //// Ideal will need to present a page for selecting the bank that will carry the transaction
    //// if that is the case, the bank will be the one to carry the oauth handshake

    
    self.client = client;
    self.delegate = delegate;
    
    [self.client postAnalyticsEvent:@"ios.ideal.initiate.started"];
    
    if (!self.returnURLScheme){
        [self.client postAnalyticsEvent:@"ios.ideal.initiate.invalid-return-url-scheme"];
        if (error != NULL){
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain code:BTAppSwitchErrorIntegrationReturnURLScheme userInfo:@ { NSLocalizedDescriptionKey : @"Ideal is not available",
                NSLocalizedFailureReasonErrorKey : @"Invalid return URL scheme",
                NSLocalizedRecoverySuggestionErrorKey : @"Add scheme to info.plist and use + [Braintree setReturnURLScheme:]" }];
        }
        return NO;
    }
    
    if (![self appSwitchAvailableForClient:client]){
        [self.client postAnalyticsEvent:@"ios.ideal.initiate.unavailable"];
        if (error != NULL){
            *error = [NSError errorWithDomain:BTAppSwitchErrorDomain code:BTAppSwitchErrorIntegrationReturnURLScheme userInfo:@ { NSLocalizedDescriptionKey : @"Ideal is not available",
                NSLocalizedFailureReasonErrorKey : @"Configuration does not enable Ideal",
                NSLocalizedRecoverySuggestionErrorKey : @"Enable Ideal in your Braintree Control Panel" }];
        }
        return NO;
    }
    
    
    //// this will open up the web
//    self.authenticationMechanism = [BTIdealOAuth startOAuthAuthenticationWithClientId:client.configuration.idealClientId
//                                                                                scope:client.configuration.idealScope
//                                                                          redirectUri:[self.redirectUri absoluteString]
//                                                                                 meta:(client.configuration.idealMerchantAccount ? @ { @"authorizations_merchant_account" : client.configuration.idealMerchantAccount } : nil )];
    
    // instead of calling an OAuth, we can just hard code that this is an appauthenticationmode
    
    self.authenticationMechanism = [BTIdealOAuth startOAuthAuthenticationWithClientId:client.configuration.idealClientId
                                                                                scope:client.configuration.idealScope
                                                                          redirectUri:_redirectURL
                                                                                 meta:(client.configuration.idealMerchantAccount ? @ { @"authorizations_merchant_account" : client.configuration.idealMerchantAccount } : nil )];


    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_redirectURL]];
    
    self.authenticationMechanism =  BTIdealOAuthMechanismBrowser;
    
    switch (self.authenticationMechanism){
        case BTIdealOAuthMechanismNone :
            [self.client postAnalyticsEvent:@"ios.ideal.initiate.failed"];
            if (error != NULL){
                *error = [NSError errorWithDomain:BTAppSwitchErrorDomain code:BTAppSwitchErrorFailed userInfo:@{NSLocalizedDescriptionKey: @"Ideal is not available", NSLocalizedFailureReasonErrorKey:@"Unable to perform app switch"}];
            }
            break;
        case BTIdealOAuthMechanismApp :
            [self.client postAnalyticsEvent:@"ios.ideal.appswitch.started"];
            break;
        case BTIdealOAuthMechanismBrowser :
            [self.client postAnalyticsEvent:@"ios.ideal.webswitch.started"];
            break;
    }
    
    return self.authenticationMechanism != BTIdealOAuthMechanismNone;
}


// TODO :: implement handleReturnURL

- (BOOL) canHandleReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication{
    NSURL *redirectURL = self.redirectUri;
    BOOL schemeMatches = [[url.scheme lowercaseString] isEqualToString:[redirectURL.scheme lowercaseString]];
    BOOL hostMatches = [url.host isEqualToString:redirectURL.host];
    BOOL pathMatches = [url.path isEqualToString:redirectURL.path];
    NSLog(@"%d, %d, %d", schemeMatches, hostMatches, pathMatches);
//    return schemeMatches && hostMatches && pathMatches;
    return YES;
}

- (void) handleReturnURL:(NSURL *)url {
    if(![self canHandleReturnURL:url sourceApplication:nil]){
        return;
    }
    
    [BTIdealOAuth finishOAuthAuthenticationForUrl:url clientId:self.client.configuration.idealClientId clientSecret:nil completion:^(id response, NSError *error)
    {
        BTIdealOAuthAuthenticationMechanism mechanism = self.authenticationMechanism;
        if (error) {
            if ([error.domain isEqualToString:BTIdealErrorDomain] && error.code == BTIdealOAuthError && [error.userInfo[BTIdealOAuthErrorUserInfoKey] isEqual:@"access_denied"]) {
                switch(mechanism) {
                    case BTIdealOAuthMechanismApp: [self.client postAnalyticsEvent:@"ios.ideal.appswitch.denied"]; break;
                    case BTIdealOAuthMechanismBrowser: [self.client postAnalyticsEvent:@"ios.ideal.webswitch.denied"]; break;
                    case BTIdealOAuthMechanismNone: [self.client postAnalyticsEvent:@"ios.ideal.unknown.denied"]; break;
                }
                [self informDelegateDidCancel];
            } else {
                switch(mechanism) {
                    case BTIdealOAuthMechanismApp: [self.client postAnalyticsEvent:@"ios.ideal.appswitch.failed"]; break;
                    case BTIdealOAuthMechanismBrowser: [self.client postAnalyticsEvent:@"ios.ideal.webswitch.failed"]; break;
                    case BTIdealOAuthMechanismNone: [self.client postAnalyticsEvent:@"ios.ideal.unknown.failed"]; break;
                }
                [self informDelegateDidFailWithError:error];
            }
        } else {
            switch(mechanism) {
                case BTIdealOAuthMechanismApp: [self.client postAnalyticsEvent:@"ios.ideal.appswitch.authorized"]; break;
                case BTIdealOAuthMechanismBrowser: [self.client postAnalyticsEvent:@"ios.ideal.webswitch.authorized"]; break;
                case BTIdealOAuthMechanismNone: [self.client postAnalyticsEvent:@"ios.ideal.unknown.authorized"]; break;
            }
            [self informDelegateWillCreatePaymentMethod];
            
            NSMutableDictionary *mutableResponse = [response mutableCopy];
            mutableResponse[@"redirect_uri"] = [self.redirectUri absoluteString];
            response = mutableResponse;
            [[self clientWithMetadataForAuthenticationMechanism:mechanism] saveIdealAccount:response
                                                                               storeInVault:self.storeInVault
                                                                                    success:^(BTIdealPaymentMethod *idealPaymentMethod) {
                                                                                           [self.client postAnalyticsEvent:@"ios.ideal.tokenize.succeeded"];
                                                                                           [self informDelegateDidCreatePaymentMethod:idealPaymentMethod];
                                                                                       } failure:^(NSError *error) {
                                                                                           [self.client postAnalyticsEvent:@"ios.ideal.tokenize.failed"];
                                                                                           [self informDelegateDidFailWithError:error];
                                                                                       }];
        }

    }];
    
    
}

#pragma mark Delegate Informers

- (void) informDelegateWillCreatePaymentMethod {
    if ([self.delegate respondsToSelector:@selector(appSwitcherWillCreatePaymentMethod:)]){
        [self.delegate appSwitcherWillCreatePaymentMethod:self];
    }
}

- (void) informDelegateDidFailWithError:(NSError *) error {
    if ([self.delegate respondsToSelector:@selector(appSwitcher:didFailWithError:)]) {
        [self.delegate appSwitcher:self didFailWithError:error];
    }
}

- (void) informDelegateDidCancel {
    if ([self.delegate respondsToSelector:@selector(appSwitcherDidCancel:)]){
        [self.delegate appSwitcherDidCancel:self];
    }
}

- (void) informDelegateDidCreatePaymentMethod:(BTIdealPaymentMethod *) paymentMethod {
    if ([self.delegate respondsToSelector:@selector(appSwitcher:didCreatePaymentMethod:)]){
        [self.delegate appSwitcher:self didCreatePaymentMethod:paymentMethod];
    }
}


#pragma mark Helpers

- (BTClient *) clientWithMetadataForAuthenticationMechanism:(BTIdealOAuthAuthenticationMechanism) authenticationMechanism {
    return [self.client copyWithMetadata:^(BTClientMutableMetadata *metadata){
        switch (authenticationMechanism){
            case BTIdealOAuthMechanismApp:
                metadata.source = BTClientMetadataSourceIdealApp;
                break;
            case BTIdealOAuthMechanismBrowser :
                metadata.source = BTClientMetadataSourceIdealBrowser;
                break;
            default:
                metadata.source = BTClientMetadataSourceUnknown;
                break;
        }
    }];
}


@end
