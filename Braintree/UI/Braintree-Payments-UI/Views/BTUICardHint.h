#import <UIKit/UIKit.h>
#import "BTUIPaymentMethodType.h"

/// `BTCardHint` has two display modes: one emphasizes the card type, and the second emphasizes the CVV location.
typedef NS_ENUM(NSInteger, BTCardHintDisplayMode) {
    /// Emphasize the card's type.
    BTCardHintDisplayModeCardType,
    /// Emphasize the CVV's location.
    BTCardHintDisplayModeCVVHint,
};

/// A View that displays a card icon in order to provide users with a hint as to what card type
/// has been detected or where the CVV can be found on that card.
@interface BTUICardHint : UIView

/// The card type to display.
@property (nonatomic, assign) BTUIPaymentMethodType cardType;

/// Whether to emphasize the card type or the CVV.
@property (nonatomic, assign) BTCardHintDisplayMode displayMode;

/// Update the current cardType with an optional visual animation
/// @see cardType
- (void)setCardType:(BTUIPaymentMethodType)cardType animated:(BOOL)animated;

/// Update the current displayMode with an optional visual animation
/// @see displayMode
- (void)setDisplayMode:(BTCardHintDisplayMode)displayMode animated:(BOOL)animated;

- (void)highlight:(BOOL)highlight;

@end