//
//  BTIdealOAuth.m
//  Braintree
//
//  Created by Everett Quebral on 9/29/15.
//
//

#import "BTIdealOAuth.h"

NSString *const BTIdealOAuthErrorUserInfoKey = @"IdealOAuthError";

@implementation BTIdealOAuth

static NSURL * __strong baseURL;

+ (BOOL) isAppOAuthAuthenticationAvailable {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"com.ideal.oauth-authorize://authorize"]];
}

+ (BTIdealOAuthAuthenticationMechanism) startOAuthAuthenticationWithClientId:(NSString *)clientId
                                                                       scope:(NSString *)scope
                                                                 redirectUri:(NSString *)redirectUri
                                                                        meta:(NSDictionary *)meta {

    NSString *path = [NSString stringWithFormat:@"/oauth/authorize?response_type=code&client_id=%@", clientId];
    if (scope) {
        path = [path stringByAppendingFormat:@"&scope=%@", [self URLEncodedStringFromString:scope]];
    }
    if (redirectUri){
        path = [path stringByAppendingFormat:@"&redirect_uri=%@", [self URLEncodedStringFromString:redirectUri]];
    }
    if (meta){
        for (NSString *key in meta){
            path = [path stringByAppendingFormat:@"&meta[%@]=%@", [self URLEncodedStringFromString:key], [self URLEncodedStringFromString:meta[key]]];
        }
    }
    

    BTIdealOAuthAuthenticationMechanism mechanism = BTIdealOAuthMechanismNone;
    NSURL *idealAppUrl = [NSURL URLWithString:[NSString stringWithFormat:@"com.ideal.oauth-authorize:%@", path]];
    BOOL appSwitchSuccessful = NO;
    if ([[UIApplication sharedApplication] canOpenURL:idealAppUrl] && baseURL == nil){
        appSwitchSuccessful = [[UIApplication sharedApplication] openURL:idealAppUrl];
        if (appSwitchSuccessful){
            mechanism = BTIdealOAuthMechanismApp;
        }
    }
    if (!appSwitchSuccessful){
        NSURL *base = [NSURL URLWithString:path relativeToURL:(baseURL == nil ? [NSURL URLWithString:@"https://ideal.nl"] : baseURL)];
        NSURL *webUrl = [[NSURL URLWithString:path relativeToURL:base] absoluteURL];
        BOOL browserSwitchSuccessful = [[UIApplication sharedApplication] openURL:webUrl];
        if (browserSwitchSuccessful){
            mechanism = BTIdealOAuthMechanismBrowser;
        }
    }

    return mechanism;
}

+ (void) finishOAuthAuthenticationForUrl:(NSURL *)url
                                clientId:(NSString *)clientId
                            clientSecret:(NSString *)clientSecret
                              completion:(BTIdealCompletionBlock)completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString * param in [url.query componentsSeparatedByString:@"&"]){
        NSArray *elts = [param componentsSeparatedByString:@"="];
        NSString *key = [elts objectAtIndex:0];
        NSString *value = [elts objectAtIndex:1];
        
        params[key] = value;
    }
    
    NSString *code = params[@"code"];
    
    if (params[@"error_description"] != nil){
        NSString *errorDescription = [[params[@"error_description"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: errorDescription, BTIdealOAuthErrorUserInfoKey:(params[@"error"] ?: [NSNull null]) };
        NSError *error = [NSError errorWithDomain:BTIdealErrorDomain code:BTIdealOAuthError userInfo:userInfo];
        completion(nil, error);
        return;
    }
    else if (!code){
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Malformed URL." };
        NSError *error = [NSError errorWithDomain:BTIdealErrorDomain code:BTIdealOAuthError userInfo:userInfo];
        completion(nil, error);
        return;
    }
    else if (!clientSecret) {
        completion(@{@"code": code}, nil);
        return ;
    }
    
    // Make the token request here
    NSString *redirectURL = [[url absoluteString] stringByReplacingOccurrencesOfString:[url query] withString:@""];
    redirectURL = [redirectURL substringToIndex:redirectURL.length - 1];
    [BTIdealOAuth getOAuthTokensForCode:code
                            redirectUri:redirectURL
                               clientId:clientId
                           clientSecret:clientSecret
                             completion:completion];
    return;
}

+ (void) getOAuthTokensForCode:(NSString *)code
                   redirectUri:(NSString *)redirectUri
                      clientId:(NSString *)clientId
                  clientSecret:(NSString *)clientSecret
                    completion:(BTIdealCompletionBlock)completion{
    
    NSDictionary *params = @{ @"grant_type" : @"authroization_code",
                              @"code" : code,
                              @"redirect_uri" : redirectUri,
                              @"client_id" : clientId,
                              @"client_secret" : clientSecret };
    [BTIdealOAuth doOAuthPostToPath:@"token" withParams:params completion:completion];
    
}

+ (void) getOAuthTokensForRefreshToken:(NSString *)refreshToken
                              clientId:(NSString *)clientId
                          clientSecret:(NSString *)clientSecret
                            completion:(BTIdealCompletionBlock)completion{
    NSDictionary *params = @{ @"grant_type" : @"refresh_token",
                              @"refresh_token" :refreshToken,
                              @"client_id" : clientId,
                              @"client_secret" : clientSecret };
    [BTIdealOAuth doOAuthPostToPath:@"token" withParams:params completion:completion];
}



+ (void) doOAuthPostToPath:(NSString *)path
                withParams:(NSDictionary *)params
                completion:(BTIdealCompletionBlock)completion {
    
    NSURL *base = [NSURL URLWithString:@"oauth/" relativeToURL:(baseURL == nil ? [NSURL URLWithString:@"https://ideal.nl"] : baseURL)];
    NSURL *url = [[NSURL URLWithString:path relativeToURL:base] absoluteURL];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableArray *components = [NSMutableArray new];
    NSString *encodedKey, *encodedValue;
    for (NSString *key in params){
        encodedKey = [BTIdealOAuth URLEncodedStringFromString:key];
        encodedValue = [BTIdealOAuth URLEncodedStringFromString:[params objectForKey:key]];
        [components addObject: [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSError *error = nil;
    NSData *data = [[components componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
    if (error){
        completion(nil, error);
        return;
    }
    
    NSURLSessionUploadTask *task;
    task = [session uploadTaskWithRequest:request
                                 fromData:data
                        completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
                            if (!error){
                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                NSDictionary *parsedBody = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                if (!error){
                                    if (![parsedBody objectForKey:@"error"] || [httpResponse statusCode] > 300){
                                        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:[parsedBody objectForKey:@"error"] };
                                        error = [NSError errorWithDomain:BTIdealErrorDomain code:BTIdealOAuthError userInfo:userInfo];
                                    }
                                    else {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            completion(parsedBody, nil);
                                        });
                                        return;
                                    }
                                }
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(nil, error);
                            });
                        }];
    [task resume];
    
}

+ (NSString *) URLEncodedStringFromString:(NSString *) string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (void) setBaseURL:(NSURL *)URL {
    baseURL = URL;
}
@end
