//
//  BTUIIdealWordmarkVectorArtView.m
//  Braintree
//
//  Created by Everett Quebral on 10/7/15.
//
//


#import "BTUIIdealWordmarkVectorArtView.h"

@implementation BTUIIdealWordmarkVectorArtView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self doSetup];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self doSetup];
    }
    return self;
}

- (void)doSetup {
    self.artDimensions = CGSizeMake(162, 88);
    self.opaque = NO;
    self.color = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 1]; // Default color
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawArt {
    //// Assets
    {
        //// button-ideal
        {
            //// Rectangle Drawing
            
            
            //// logo/ideal
            {
                //// Bezier Drawing
                UIBezierPath* bezierPath = [UIBezierPath bezierPath];
                [bezierPath moveToPoint:CGPointMake(34, 10)];
                [bezierPath addLineToPoint:CGPointMake(110, 10)];
                [bezierPath addCurveToPoint:CGPointMake(110, 78) controlPoint1:CGPointMake(128, 44) controlPoint2:CGPointMake(128, 44)];
                [bezierPath addLineToPoint:CGPointMake(34, 78)];

                [bezierPath closePath];
                bezierPath.miterLimit = 4;
                
                bezierPath.usesEvenOddFillRule = YES;
                
                // black
                [self.color setFill];
//                [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha:1];
                [bezierPath fill];
                
                //// start the inner D
                UIBezierPath* bezier2Path = [UIBezierPath bezierPath];

                [bezier2Path moveToPoint:CGPointMake(44, 20)];
                [bezier2Path addLineToPoint:CGPointMake(100, 20)];
                [bezier2Path addCurveToPoint:CGPointMake(100, 68) controlPoint1:CGPointMake(118, 44) controlPoint2:CGPointMake(118, 44)];
                [bezier2Path addLineToPoint:CGPointMake(44, 68)];
                
                [bezier2Path closePath];
                bezier2Path.miterLimit = 4;
                
                bezier2Path.usesEvenOddFillRule = YES;
                
                self.color = [UIColor colorWithRed: 0.9 green: 0.0 blue: 0.5 alpha:1];
                [self.color setFill];
                [bezier2Path fill];
            }
        }
    }
}

- (void)updateConstraints {
    NSLayoutConstraint *aspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:(self.artDimensions.width / self.artDimensions.height)
                                                                              constant:0.0f];
    aspectRatioConstraint.priority = UILayoutPriorityRequired;
    
    [self addConstraints:@[aspectRatioConstraint]];
    
    [super updateConstraints];
}

- (UILayoutPriority)contentCompressionResistancePriorityForAxis:(__unused UILayoutConstraintAxis)axis {
    return UILayoutPriorityRequired;
}

@end
