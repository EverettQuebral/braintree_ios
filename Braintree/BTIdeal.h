//
//  BTIdeal.h
//  Braintree
//
//  Created by Everett Quebral on 9/29/15.
//
//  Implementation is almost similar to Coinbase
//

#import <Foundation/Foundation.h>
#import "BTAppSwitching.h"
#import "BTAppSwitchErrors.h"

@interface BTIdeal : NSObject <BTAppSwitching>

@property (nonatomic, assign) BOOL storeInVault;

@property (nonatomic, assign) BOOL disabled;

@property (nonatomic, assign, readonly) BOOL isProviderAppInstalled;

+ (instancetype) sharedIdeal;

- (BOOL) providerAppSwitchAvailableForClient: (BTClient *) client;

@end
