//
//  BTIdealDefines.h
//  Braintree
//
//  Created by Everett Quebral on 9/29/15.
//
//

#import <Foundation/Foundation.h>

/// IF the API request is successful, `response` will be either a NSDictionary or NSArray, and `error` will benil
/// Otherwise, `error` will be non-nil


typedef void (^BTIdealCompletionBlock) (id response, NSError *error);

extern NSString *const BTIdealErrorDomain;

typedef NS_ENUM(NSInteger, BTIdealErrorCode){
    BTIdealOAuthError,
    BTIdealServerErrorUnknown,
    BTIdealServerErrorWithMessage
};

//@interface BTIdealDefines : NSObject
//
//@end
