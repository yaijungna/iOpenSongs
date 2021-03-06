//
//  OSShopManager.h
//  iOpenSongs
//
//  Created by Andreas Böhrnsen on 11/30/13.
//  Copyright (c) 2013 Andreas Boehrnsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/SKProduct.h>
#import <StoreKit/SKPaymentTransaction.h>

#import "OSInAppPurchaseIdentifiers.h"

@interface OSStoreManager : NSObject

+ (instancetype)sharedManager;

+ (BOOL)isEnabled;

- (void)initInAppStore;

- (void)requestProductsOnSuccess:(void (^)(NSArray *products, NSArray *invalidIdentifiers))success
                         failure:(void (^)(NSError *error))failure;

- (void)buyProduct:(NSString *)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;

- (void)restoreTransactionsOnSuccess:(void (^)(void))successBlock
                             failure:(void (^)(NSError *error))failureBlock;

- (void)whenPurchasedOrRestored:(NSString *)productIdentifier execute:(void (^)(void))block;

- (BOOL)canRestorePurchases;

- (BOOL)isPurchased:(NSString *)productIdentifier;

@end
