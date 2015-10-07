//
//  BTUIIdealButton.m
//  Braintree
//
//  Created by Everett Quebral on 10/7/15.
//
//
#import "BTUIIdealButton.h"

#import "BTUI.h"
#import "UIColor+BTUI.h"

#import "BTUIIdealWordmarkVectorArtView.h"
#import "BTUILocalizedString.h"

@interface BTUIIdealButton ()
@property (nonatomic, strong) BTUIIdealWordmarkVectorArtView *idealWordmark;
@end

@implementation BTUIIdealButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.theme = [BTUI braintreeTheme];
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;
    self.opaque = NO;
    self.backgroundColor = [UIColor whiteColor];
    self.accessibilityLabel = [BTUILocalizedString PAYMENT_METHOD_TYPE_IDEAL];
    
    self.idealWordmark = [[BTUIIdealWordmarkVectorArtView alloc] init];
    self.idealWordmark.userInteractionEnabled = NO;
    self.idealWordmark.translatesAutoresizingMaskIntoConstraints = NO;
    self.idealWordmark.color = [self.theme idealPrimaryColor];
    
    [self addSubview:self.idealWordmark];
}

- (void)updateConstraints {
    NSDictionary *metrics = @{ @"minHeight": @([self.theme paymentButtonMinHeight]),
                               @"maxHeight": @([self.theme paymentButtonMaxHeight]),
                               @"minWidth": @(200),
                               @"required": @(UILayoutPriorityRequired),
                               @"high": @(UILayoutPriorityDefaultHigh),
                               @"breathingRoom": @(10) };
    NSDictionary *views = @{ @"self": self ,
                             @"idealWordmark": self.idealWordmark };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[idealWordmark]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.idealWordmark
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [super updateConstraints];
}

- (void)setHighlighted:(BOOL)highlighted {
    [UIView animateWithDuration:0.08f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            if (highlighted) {
                                self.backgroundColor = [UIColor colorWithWhite:0.92f alpha:1.0f];
                            } else {
                                self.backgroundColor = [UIColor whiteColor];
                            }
                        }
                     completion:nil];
}

@end
