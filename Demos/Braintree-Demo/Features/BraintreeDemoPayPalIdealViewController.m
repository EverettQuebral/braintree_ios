//
//  BraintreeDemoPayPalIdealViewController.m
//  Braintree
//
//  Created by Everett Quebral on 9/28/15.
//
//

#import "BraintreeDemoPayPalIdealViewController.h"
#import <PureLayout/ALView+PureLayout.h>
#import <Braintree/Braintree.h>
#import <Braintree/UIColor+BTUI.h>

#import "BraintreeDemoSettings.h"
#import "BTHTTP.h"

#import "BTIdeal.h"

@interface BraintreeDemoPayPalIdealViewController ()
@property (nonatomic, strong) BTPaymentProvider *paymentProvider;
@property (nonatomic, strong) BTUICardFormView *cardForm;
@property (nonatomic, strong) UINavigationController *cardFormNavigationViewController;
@property (nonatomic, strong) UINavigationController *idealBankListNavigationViewController;
@property (nonatomic, strong) UINavigationController *webViewNavigationController;
@property (nonatomic, strong) UIViewController *webViewController;
@property (nonatomic, strong) UIView *bankListView;
@property (nonatomic, strong) UIView *paymentView;
@property (nonatomic, strong) NSMutableData *bankListData;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSArray *issuers;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, strong) NSString *selectedBankName;
@property (nonatomic, strong) NSString *redirectUri;
@property (nonatomic, strong) UIView *itemToBuyView;
@property (nonatomic, strong) UILabel *statusBank;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
//@property (nonatomic, strong) UIImage *idealLogo;
//@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation BraintreeDemoPayPalIdealViewController


NSString *const returnURL = @"https://sandbox.paypal-hub.com/rest/_test/success.php";
NSString *const cancelURL = @"http://everettquebral.com/sample-page/cancel";

/// account related information
NSString *const _alternatePaymentAccountId = @"ALT-449dd166044b4dd6af68a4e21f69eef6";


/// mock server
//NSString *const issuersList = @"http://localhost:3000/v1/customer/alternate-payment-accounts/ALT-449dd166044b4dd6af68a4e21f69eef6/issuers";
//NSString *const paymentsApi = @"http://localhost:3000/v1/payments";

/// sandbox
NSString *const issuersList = @"https://sandbox.paypal-hub.com/v1/customer/alternate-payment-accounts/ALT-449dd166044b4dd6af68a4e21f69eef6/issuers2";
NSString *const paymentsApi = @"https://sandbox.paypal-hub.com/v1/payments";

/// logo
NSString *const idealLogo = @"https://myideal.test.db.com/ideal/images/fatmpi/ideal_logo.gif";
//NSString *const idealLogo = @"http://www.cdbudgetstore.nl/WebRoot/StoreNL2/Shops/62149771/MediaGallery/ideal_log.jpg";


/// item information
NSString *const _itemDescription = @"Toys enjoy an important part in growth and also development of each and every kid, as they deal with years ago, approach. We cannot imagine a childhood without toys in addition to games. A superb toy present kids full leisure and capability to discover brand new things from the greatest way. Currently, your games choice is nearly unlimited, since toys for children are available in many different styles, sizes and colors several age brackets of children. Manufacturing advancements make it even more exciting that children would pretty inches for their games. You can get a tiny to a large electric powered toy in cost a lot of money.";
NSString *prize = @"";


NSString *altPayId = @"";

- (instancetype) initWithClientToken:(NSString *)clientToken {
    self  = [super initWithClientToken:clientToken];
    if (self){
        self.paymentProvider = [self.braintree paymentProviderWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicatorView.center = self.view.center;
    [self.view addSubview:self.activityIndicatorView];
    
    UIView *itemToBuyView = [self showItemToBuy];
    [self.view addSubview:itemToBuyView];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    
    self.webViewController = [[UIViewController alloc] init];
//    self.webViewController.title = @"iDeal";
    self.webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelWebView)];
    self.webViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(successWebView)];
    
    [self.webViewController.view addSubview:self.webView];
    
    self.webViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];
    
    self.title = @"PayPal iDeal Demo";
    self.bankListData = [[NSMutableData alloc] init];
    
    /// let's have an ideal logo in the title
    UIImage *logoImage = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:idealLogo]]];
    UIView *headerView = [[UIView alloc] init];
    headerView.frame = CGRectMake(0,0, 320, 44);
    UIImageView *imgView = [[UIImageView alloc] initWithImage:logoImage];
    imgView.frame = CGRectMake(75, 0, 150, 44);
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    [headerView addSubview:imgView];
    
    self.navigationController.navigationBar.topItem.titleView = headerView;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
    delegateQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    
    self.session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:delegateQueue];
    
}

- (UIView *) showItemToBuy {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 250)];
    view.backgroundColor = [UIColor whiteColor];
    
    /// create an image view for showing an image of the product
    UIImageView *productImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://puzzletoysforchildren.tk/wp-content/uploads/2014/10/the-logo-board-game-photo-001.jpg"]]]];
    productImageView.frame = CGRectMake(10, 10, 160, 160);
    
    /// create a label to say about the title of the product
    UILabel *productTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(170, 10, self.view.bounds.size.width - 180, 50)];
    productTitleLabel.text = @"Puzzle Toys for Children";
    
    /// create a label for the descrption of the product
    UILabel *productDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(170, 60, self.view.bounds.size.width - 180, 100)];
    productDescriptionLabel.text = _itemDescription;
    [productDescriptionLabel setFont:[UIFont systemFontOfSize:12]];
    productDescriptionLabel.numberOfLines = 10;
    [productDescriptionLabel sizeToFit];
    
    /// create a lable for the price of the product
    UILabel *productPrizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 180, self.view.bounds.size.width - 200, 100)];
    [productPrizeLabel setFont:[UIFont systemFontOfSize:20]];
//    productPrizeLabel.text = @"$ 10.99 + tax";
    
    prize = [NSString stringWithFormat:@"%d.%d", arc4random_uniform(10) + 1 , arc4random_uniform(88) + 10];
    productPrizeLabel.text = [NSString stringWithFormat:@"$ %@", prize];
    
    
    [view addSubview:productTitleLabel];
    [view addSubview:productDescriptionLabel];
    [view addSubview:productPrizeLabel];
    [view addSubview:productImageView];
    
    
    return view;
}

- (UIView *) paymentButton {
    self.itemToBuyView = [[UIView alloc] initForAutoLayout];
    self.paymentView = [[UIView alloc] initForAutoLayout];
    
    UIButton *venmoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    venmoButton.translatesAutoresizingMaskIntoConstraints = NO;
    venmoButton.titleLabel.font = [UIFont fontWithName:@"AmericanTypewriter" size:[UIFont systemFontSize]];
    venmoButton.backgroundColor = [[BTUI braintreeTheme] venmoPrimaryBlue];
    [venmoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [venmoButton setTitle:@"Venmo" forState:UIControlStateNormal];
    venmoButton.tag = BTPaymentProviderTypeVenmo;
    
    UIButton *payPalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    payPalButton.translatesAutoresizingMaskIntoConstraints = NO;
    payPalButton.titleLabel.font = [UIFont fontWithName:@"GillSans-BoldItalic" size:[UIFont systemFontSize]];
    payPalButton.backgroundColor = [[BTUI braintreeTheme] palBlue];
    [payPalButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [payPalButton setTitle:@"PayPal" forState:UIControlStateNormal];
    payPalButton.tag = BTPaymentProviderTypePayPal;
    
    UIButton *cardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cardButton.translatesAutoresizingMaskIntoConstraints = NO;
    cardButton.backgroundColor = [UIColor bt_colorFromHex:@"DDDECB" alpha:1.0f];
    [cardButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cardButton setTitle:@"💳" forState:UIControlStateNormal];
    cardButton.tag = -1;
    
    /// ==== ideal button here ======
    UIButton *idealButton = [UIButton buttonWithType:UIButtonTypeSystem];
    idealButton.translatesAutoresizingMaskIntoConstraints = NO;
    idealButton.backgroundColor = [UIColor bt_colorFromHex:@"DD127B" alpha:1.0f];
    [idealButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [idealButton setTitle:@"iDeal" forState:UIControlStateNormal];
    idealButton.translatesAutoresizingMaskIntoConstraints = NO;
    idealButton.tag = BTPaymentProviderTypeIdeal;
    /// ==== ideal button ========
    
    
    [venmoButton addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [payPalButton addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cardButton addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [idealButton addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.paymentView addSubview:payPalButton];
    [self.paymentView addSubview:venmoButton];
    [self.paymentView addSubview:cardButton];
    [self.paymentView addSubview:idealButton];
    
    [venmoButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:payPalButton];
    [payPalButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:cardButton];
    [idealButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:cardButton];
    
    [venmoButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [venmoButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:payPalButton];
    [payPalButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:idealButton];
    [idealButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:cardButton];
    [cardButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    
    [venmoButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [venmoButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [payPalButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [payPalButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [idealButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [idealButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [cardButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [cardButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    
    [self.paymentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:venmoButton];
    
    return self.paymentView;
}

- (UIButton *) idealButton {
    UIButton *idealButton = [UIButton buttonWithType:UIButtonTypeSystem];
    //    idealButton.translatesAutoresizingMaskIntoConstraints = NO;
    //    idealButton.backgroundColor = [UIColor bt_colorFromHex:@"DDDECB" alpha:1.0f];
    //    [idealButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [idealButton setTitle:@"Ideal" forState:UIControlStateNormal];
    //    idealButton.tag = BTPaymentProviderTypeIdeal;
    
    NSURL *imageURL = [NSURL URLWithString:@"https://static.webshopapp.com/shops/072347/files/028974021/ideal-logo.gif"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:imageURL];
    UIImage *idealButtonImg = [UIImage imageWithData:data];
    [idealButton setImage:idealButtonImg
                 forState:UIControlStateNormal];
    
    idealButton.translatesAutoresizingMaskIntoConstraints = NO;
    idealButton.tag = BTPaymentProviderTypeIdeal;
    return idealButton;
}

- (void)tapped:(UIButton *)sender {
    if (sender.tag == -1) {
        self.cardForm = [[BTUICardFormView alloc] initForAutoLayout];
        self.cardForm.optionalFields = BTUICardFormOptionalFieldsAll;
        
        UIViewController *cardFormViewController = [[UIViewController alloc] init];
        cardFormViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                                target:self
                                                                                                                action:@selector(cancelCardVC)];
        cardFormViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                                                 target:self
                                                                                                                 action:@selector(saveCardVC)];
        cardFormViewController.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
        
        cardFormViewController.title = @"💳";
        [cardFormViewController.view addSubview:self.cardForm];
        cardFormViewController.view.backgroundColor = sender.backgroundColor;
        
        [self.cardForm autoPinToTopLayoutGuideOfViewController:cardFormViewController withInset:40];
        [self.cardForm autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.cardForm autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
        
        self.cardFormNavigationViewController = [[UINavigationController alloc] initWithRootViewController:cardFormViewController];
        
        [self paymentMethodCreator:self requestsPresentationOfViewController:self.cardFormNavigationViewController];
    }
    else if (sender.tag == BTPaymentProviderTypeIdeal){
        [self displayBankList];
    } else {
        [self.paymentProvider createPaymentMethod:sender.tag];
    }
}

#pragma mark Bank List
- (void) displayBankList {
    //// a couple of things we need to do here
    //// get the bank list first - issuers
    
    
    NSURL *paymentHubUrl = [[NSURL alloc] initWithString:issuersList];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:paymentHubUrl];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                   @"Content-Type":@"application/json",
                                                                        @"Authorization":@"YnJhaW50cmVlOjRiMjFiY2Y2NTI4Mzc1N2M3ZDA3NDQ5MmU5ZmM4MWNmZmZkNzc1OWVi"}];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPMethod:@"GET"];
    
    
    self.statusBank = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.origin.y + 280, self.view.frame.size.width, 50)];
    [self.statusBank setFont:[UIFont systemFontOfSize:15]];
    self.statusBank.text = @"Fetching Bank List...";
    self.statusBank.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusBank];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.frame.origin.y + 320, self.view.frame.size.width, self.view.frame.size.height - 320)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    
    [self.activityIndicatorView startAnimating];
    
    // Perform the actual request
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSLog(@"JSON is %@", json);
        
        self.issuers = [[[json objectForKey:@"data"] objectAtIndex:0] objectForKey:@"issuers"];
        
        NSLog(@"issuers %@", self.issuers);
        
        dispatch_async(dispatch_get_main_queue(),^{
            self.tableView.dataSource = self;
            self.tableView.delegate = self;
            [self.tableView reloadData];
            self.statusBank.text = @"Please select bank";
            [self.activityIndicatorView stopAnimating];
            
        });
    }];
    
    [task resume];
}

#pragma mark Ideal Banks
- (void) handleBankListRequest:(NSData *) data response:(NSURLResponse *) response error:(NSError *)error {
    if (error) {
        return;
    }
    
}

- (void) makePayment {
    //// we need to send the URI that we get from the createPayment API call
    //// right now, the URL for opening up Ideal is set in the configuration
    
    /// we need to generate a unique id here
    NSString *uniqueId = [[NSUUID UUID] UUIDString];
    altPayId = [NSString stringWithFormat:@"ALTPAY-%@%@", [uniqueId componentsSeparatedByString:@"-"][3], [uniqueId componentsSeparatedByString:@"-"][4]];
    
    NSLog(@"Unique Id %@", altPayId);
    
    NSMutableDictionary *alternatePayment = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                @"external_customer_id" :@"jan_doe@gmail.com",
                                                                                                @"alternate_payment_provider_id" : @"",
                                                                                                @"alternate_payment_account_id" : _alternatePaymentAccountId
                                                                                                }];
    [alternatePayment setValue:[NSString stringWithFormat:@"%@", self.selectedBankName ] forKey:@"alternate_payment_provider_id"];
    NSMutableDictionary *paymentRequestBody = [NSMutableDictionary dictionaryWithDictionary:@{
        @"id" : altPayId,
        @"intent" : @"sale",
        @"payer" : @{
                     @"payment_method" : @"alternate_payment",
                     @"funding_instruments" : @[@{
                                                @"alternate_payment" : alternatePayment
                                                }],
                     @"payer_info" : @{
                             @"email" : @"jan_doe@gmail.com",
                             @"first_name" : @"John",
                             @"last_name" : @"Doe",
                             @"phone" : @"8898980988",
                             @"@country_code" : @"NL"
                             }
                     },
        @"transactions" : @[@{
                            @"amount": @{
                                @"total" : prize,
                                @"currency" : @"EUR",
                                @"detail" : @{
                                        @"tax" : @"2.10",
                                        @"handling_fee" : @"0.34"
                                        }
                                },
                            @"description" : _itemDescription,
                            @"item_list" : @{
                                    @"items" : @[
                                                @{ @"name" : @"item1", @"quantity" : @"1", @"price" : @"2" },
                                                @{ @"name" : @"item2", @"quantity" : @"1", @"price" : @"3" }
                                                ],
                                    @"shipping_address" : @{
                                            @"city" : @"Drenthe",
                                            @"country_code" : @"NL"
                                            }
                                    }
                            }],
        @"redirect_urls" : @{
                             @"return_url" : [NSString stringWithFormat:@"%@?id=%@", returnURL, altPayId],
                             @"cancel_url" : [NSString stringWithFormat:@"%@?id=%@", cancelURL, altPayId]
                             }
    }];
    
    NSLog(@"dictionary here %@", paymentRequestBody);
    
    NSURL *createPaymentURL = [[NSURL alloc] initWithString:paymentsApi];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:createPaymentURL];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                   @"Content-Type" : @"application/json",
                                                                                   @"Authorization" : @"Basic YnJhaW50cmVlOjNhYzY0YTBlMjY5ZDFiMWM5YzBmZGIyNmQyYjU3ODMwYmY1MDQyOTBi"}];

    [request setAllHTTPHeaderFields:headers];
    [request setHTTPMethod:@"POST"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:paymentRequestBody options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"payload here %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    
    [request setHTTPBody:data];
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 [self handleCreatePaymentResponse:data response:response error:error];
    }];
    [task resume];
}

- (void) handleCreatePaymentResponse:(NSData *) data response:(NSURLResponse *) response error:(NSError *) error {
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSLog(@"JSON is %@", json);
    NSArray *links = [json objectForKey:@"links"];
    for (id link in links){
        if ([[link valueForKey:@"method"] isEqualToString:@"REDIRECT"]){
            NSLog(@"found the redirect %@", [link valueForKey:@"href"]);
            self.redirectUri = [link valueForKey:@"href"];
        }
    }
    
    /// let's dismiss the idealBankListNavigationViewController
    [self paymentMethodCreator:self requestsDismissalOfViewController:self.idealBankListNavigationViewController];
    
    /// this is a hack since the nonce is not propagated to all the required servers to check for the status of the payment
    [self displayWebViewWithURL:self.redirectUri];

    /// the code below is the proper way of integrating this feature
//    [self processBank];
//    [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:self.redirectUri]];
}

- (void) cancelIdeal {
    [self paymentMethodCreator:self requestsDismissalOfViewController:self.idealBankListNavigationViewController];
}

- (void) cancelWebView {
    [self paymentMethodCreator:self requestsDismissalOfViewController:self.webViewNavigationController];
}

- (void) successWebView {
    [self paymentMethodCreator:self requestsDismissalOfViewController:self.webViewNavigationController];
    self.tableView.hidden = YES;
    self.statusBank.hidden = YES;
    [self showSuccess];
}

- (void) processBank {
//    [self.paymentProvider createPaymentMethod:BTPaymentProviderTypeIdeal];
    [self.paymentProvider createIdealPaymentMethod:self.redirectUri];
}

- (void) showSuccess {
    self.paymentView.hidden = YES;
    
    UILabel *paymentCompletedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 220, self.view.bounds.size.width, 100)];
    [paymentCompletedLabel setFont:[UIFont systemFontOfSize:25]];
    paymentCompletedLabel.text = @"Payment Completed";
    paymentCompletedLabel.textAlignment = NSTextAlignmentCenter;
    paymentCompletedLabel.textColor = [UIColor bt_colorFromHex:@"DD127B" alpha:1.0f];
    
    UILabel *paymentReferenceId = [[UILabel alloc] initWithFrame:CGRectMake(0, 300, self.view.bounds.size.width, 50)];
    [paymentReferenceId setFont: [UIFont systemFontOfSize:10]];
    paymentReferenceId.textAlignment = NSTextAlignmentCenter;
    paymentReferenceId.text = [NSString stringWithFormat:@"Ref ID: %@", altPayId];
    
    [self.view addSubview:paymentCompletedLabel];
    [self.view addSubview:paymentReferenceId];
    
}

- (void)cancelCardVC {
    [self paymentMethodCreator:self requestsDismissalOfViewController:self.cardFormNavigationViewController];
}

- (void)saveCardVC {
    [self cancelCardVC];
    
    BTClientCardRequest *request = [[BTClientCardRequest alloc] init];
    request.number = self.cardForm.number;
    request.expirationMonth = self.cardForm.expirationMonth;
    request.expirationYear = self.cardForm.expirationYear;
    request.cvv = self.cardForm.cvv;
    request.postalCode = self.cardForm.postalCode;
    request.shouldValidate = NO;
    
    [self.braintree.client saveCardWithRequest:request
                                       success:^(BTCardPaymentMethod *card) {
                                           [self paymentMethodCreator:self didCreatePaymentMethod:card];
                                       }
                                       failure:^(NSError *error) {
                                           [self paymentMethodCreator:self didFailWithError:error];
                                       }];
}

#pragma mark display webview
- (void) displayWebViewWithURL:(NSString *) urlString {
    
    self.webViewController.title = self.selectedBankName;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    [self paymentMethodCreator:self requestsPresentationOfViewController:self.webViewNavigationController];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark tableView

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"cellidentifier";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *issuer = [[NSDictionary alloc] initWithDictionary:[self.issuers objectAtIndex:indexPath.row]];
    
    cell.textLabel.text = [issuer objectForKey:@"id"];
    
    /// two issuers for now, INGBNL2A and RABONL2U
    if ([cell.textLabel.text isEqualToString:@"INGBNL2A"]){
        [cell.imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://lh3.ggpht.com/MXg4jV17iSlhEr-5ZcemrpaH6_ZXQdoS3LQxRbZneb12Iez-t2mIYGJwrluz6_diTZM=w170"] ]]];
    }
    else if ([cell.textLabel.text isEqualToString:@"RABONL2U"]){
        [cell.imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://digimind.nl/wp-content/uploads/2012/07/ziningoud-rabobank-logo.png"]]]];
    }
    
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.issuers.count;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectedBankName = cell.textLabel.text;
    
    [self makePayment];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectedBankName = cell.textLabel.text;
}

#pragma mark UIWebView Delegates

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.webViewController.navigationItem.rightBarButtonItem.enabled = NO;
    self.webViewController.navigationItem.rightBarButtonItem.customView.hidden = YES;
    
    return YES;
}

- (void) webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
    NSURL *currentURL = [[webView request] URL];
    NSLog(@"Final URL %@",[currentURL description]);
    // only care when the redirecturl is correct
    NSRange xrange = [[currentURL description] rangeOfString:returnURL options:NSCaseInsensitiveSearch];
    if (xrange.location != NSNotFound){
        NSString *success = @"success";
        NSRange range = [[currentURL description] rangeOfString:success options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound){
            // hide the done button
            NSLog(@"Show the Done button");
            self.webViewController.navigationItem.rightBarButtonItem.enabled = YES;
            self.webViewController.navigationItem.rightBarButtonItem.customView.hidden = NO;
            self.webViewController.navigationItem.leftBarButtonItem.enabled = NO;
            self.webViewController.navigationItem.leftBarButtonItem.customView.hidden = YES;
        }
        else {
            // hide the cancel button
            NSLog(@"Hide the Done button");
            self.webViewController.navigationItem.leftBarButtonItem.enabled = YES;
            self.webViewController.navigationItem.leftBarButtonItem.customView.hidden = NO;
            
            self.webViewController.navigationItem.rightBarButtonItem.enabled = NO;
            self.webViewController.navigationItem.rightBarButtonItem.customView.hidden = YES;
        }
    }
    else {
        NSLog(@"Hide the Done button");
        self.webViewNavigationController.navigationItem.rightBarButtonItem.customView.hidden = YES;
    }
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
