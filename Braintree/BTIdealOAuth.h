//
//  BTIdealOAuth.h
//  Braintree
//
//  Created by Everett Quebral on 9/29/15.
//
//

#import <UIKit/UIKit.h>
#import "BTIdealDefines.h"

typedef NS_ENUM(NSInteger, BTIdealOAuthAuthenticationMechanism){
    BTIdealOAuthMechanismNone = NO,
    BTIdealOAuthMechanismBrowser,
    BTIdealOAuthMechanismApp,
};

extern NSString *const BTIdealOAuthErrorUserInfoKey;

@interface BTIdealOAuth : NSObject

+ (BOOL) isAppOAuthAuthenticationAvailable;

+ (BTIdealOAuthAuthenticationMechanism)startOAuthAuthenticationWithClientId:(NSString *) clientId
                                                                      scope:(NSString *) scope
                                                                redirectUri:(NSString *) redirectUri
                                                                       meta:(NSDictionary *) meta;

+ (void)finishOAuthAuthenticationForUrl:(NSURL * )url
                               clientId:(NSString *) clientId
                           clientSecret:(NSString *) clientSecret
                             completion:(BTIdealCompletionBlock)completion;

+ (void)getOAuthTokensForRefreshToken:(NSString *) refreshToken
                             clientId:(NSString *) clientId
                         clientSecret:(NSString *) clientSecret
                           completion:(BTIdealCompletionBlock) completion;

+ (void)getOAuthTokensForCode:(NSString *)code
                  redirectUri:(NSString *)redirectUri
                     clientId:(NSString *)clientId
                 clientSecret:(NSString *)clientSecret
                   completion:(BTIdealCompletionBlock) completion;

+ (void)doOAuthPostToPath:(NSString *) path
               withParams:(NSDictionary *) params
               completion:(BTIdealCompletionBlock) completion;

+ (void) setBaseURL:(NSURL *) URL;
@end
