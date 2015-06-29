//
//  RNActivityView.h
//  Created by  Romilson Nunes
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@protocol RNActivityViewDelegate;


typedef enum {
	/** Progress is shown using an UIActivityIndicatorView. This is the default. */
	RNActivityViewModeIndeterminate,
	/** Progress is shown using a round, pie-chart like, progress view. */
	RNActivityViewModeDeterminate,
	/** Progress is shown using a horizontal progress bar */
	RNActivityViewModeDeterminateHorizontalBar,
	/** Progress is shown using a ring-shaped progress view. */
	RNActivityViewModeAnnularDeterminate,
	/** Shows a custom view */
	RNActivityViewModeCustomView,
	/** Shows only labels */
	RNActivityViewModeText
} RNActivityViewMode;

typedef enum {
	/** Opacity animation */
	RNActivityViewAnimationFade,
	/** Opacity + scale animation */
	RNActivityViewAnimationZoom,
	RNActivityViewAnimationZoomOut = RNActivityViewAnimationZoom,
	RNActivityViewAnimationZoomIn
} RNActivityViewAnimation;


#ifndef rn_instancetype
#if __has_feature(objc_instancetype)
	#define rn_instancetype instancetype
#else
	#define rn_instancetype id
#endif
#endif

typedef void (^RNActivityViewCompletionBlock)();

@interface RNActivityView : UIView

+ (rn_instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;

+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;

+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated;

+ (rn_instancetype)HUDForView:(UIView *)view;

+ (NSArray *)allHUDsForView:(UIView *)view;

- (id)initWithWindow:(UIWindow *)window;
- (id)initWithView:(UIView *)view;

- (void)show:(BOOL)animated;
- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block;
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block completionBlock:(RNActivityViewCompletionBlock)completion;
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue;
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
		  completionBlock:(RNActivityViewCompletionBlock)completion;

- (void)hide:(BOOL)animated;
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay;

- (void) setupDefaultValues;

@property (copy) RNActivityViewCompletionBlock completionBlock;
@property (assign) RNActivityViewMode mode; // default is RNActivityViewModeIndeterminate.
@property (assign) RNActivityViewAnimation animationType;
@property (strong) UIView *customView;
@property (weak) id<RNActivityViewDelegate> delegate;
@property (copy) NSString *labelText; // then no message is displayed.
@property (copy) NSString *detailsLabelText;
@property (assign) float opacity; // Defaults to 0.8 (80% opacity)
@property (strong) UIColor *color;

/** 
 * The x-axis offset of the HUD relative to the centre of the superview. 
 */
@property (assign) float xOffset;

/** 
 * The y-axis offset of the HUD relative to the centre of the superview. 
 */
@property (assign) float yOffset;

@property (assign) float margin; // Defaults to 20.0
@property (assign) float cornerRadius; // Defaults to 10.0
@property (assign) BOOL dimBackground; // Cover the HUD background view with a radial gradient

/*
 * Grace period is the time (in seconds) that the invoked method may be run without 
 * showing the HUD. If the task finishes before the grace time runs out, the HUD will
 * not be shown at all. 
 * This may be used to prevent HUD display for very short tasks.
 * Defaults to 0 (no grace time).
 * Grace time functionality is only supported when the task status is known!
 * @see taskInProgress
 */
@property (assign) float graceTime;

// The minimum time (in seconds) that the HUD is shown.
// Defaults 0 (no minimum show time).
@property (assign) float minShowTime;

@property (assign) BOOL taskInProgress;

@property (assign) BOOL removeFromSuperViewOnHide; // Defaults NO

@property (strong) UIFont* labelFont;
@property (strong) UIColor* labelColor;
@property (strong) UIFont* detailsLabelFont;
@property (strong) UIColor* detailsLabelColor;

@property (assign) float progress; // 0.0 to 1.0
@property (assign) CGSize minSize; // Defaults to CGSizeZero (no minimum size)
@property (assign, getter = isSquare) BOOL square;

@end

/*
    Protocol
*/
@protocol RNActivityViewDelegate <NSObject>
@optional
- (void)hudWasHidden:(RNActivityView *)hud;
@end


/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */
@interface RNRoundProgressView : UIView 

@property (nonatomic, assign) float progress; // Progress (0.0 to 1.0)
@property (nonatomic, strong) UIColor *progressTintColor; // Defaults White
@property (nonatomic, strong) UIColor *backgroundTintColor; // Defaults to translucent white (alpha 0.1)
@property (nonatomic, assign, getter = isAnnular) BOOL annular; // Display mode - NO = round or YES = annular. Defaults to round.

@end


/**
 * A flat bar progress view.
 */
@interface RNBarProgressView : UIView

@property (nonatomic, assign) float progress; // Progress (0.0 to 1.0)
@property (nonatomic, strong) UIColor *lineColor; // Defaults to white
@property (nonatomic, strong) UIColor *progressRemainingColor; // Defaults to clear
@property (nonatomic, strong) UIColor *progressColor; // Defaults to white

@end
