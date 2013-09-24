#import <QuartzCore/QuartzCore.h>

#import "MPSurvey.h"
#import "MPSurveyNavigationController.h"
#import "MPSurveyQuestion.h"
#import "MPSurveyQuestionViewController.h"
#import "UIImage+MPAverageColor.h"
#import "UIImage+MPImageEffects.h"
#import "UIView+MPSnapshotImage.h"

@interface MPSurveyNavigationController () <MPSurveyQuestionViewControllerDelegate>

@property(nonatomic,retain) IBOutlet UIImageView *view;
@property(nonatomic,retain) IBOutlet UIView *containerView;
@property(nonatomic,retain) IBOutlet UILabel *pageNumberLabel;
@property(nonatomic,retain) IBOutlet UIButton *nextButton;
@property(nonatomic,retain) IBOutlet UIButton *previousButton;
@property(nonatomic,retain) IBOutlet UIImageView *logo;
@property(nonatomic,retain) IBOutlet UIButton *exitButton;
@property(nonatomic,retain) IBOutlet UIView *header;
@property(nonatomic,retain) IBOutlet UIView *footer;
@property(nonatomic,retain) NSMutableArray *questionControllers;
@property(nonatomic) UIViewController *currentQuestionController;
@property(nonatomic,retain) NSArray *currentQuestionConstraints;

@end

@implementation MPSurveyNavigationController

- (void)dealloc
{
    self.mixpanel = nil;
    self.survey = nil;
    self.backgroundImage = nil;
    self.questionControllers = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.image = [_backgroundImage mp_applyDarkEffect];
    self.questionControllers = [NSMutableArray array];
    for (NSUInteger i = 0; i < _survey.questions.count; i++) {
        [_questionControllers addObject:[NSNull null]];
    }
    [self loadQuestion:0];
    [self loadQuestion:1];
    MPSurveyQuestionViewController *firstQuestionController = _questionControllers[0];
    [self addChildViewController:firstQuestionController];
    [_containerView addSubview:firstQuestionController.view];
    [self constrainCurrentQuestionControllerView:firstQuestionController.view];
    [firstQuestionController didMoveToParentViewController:self];
    _currentQuestionController = firstQuestionController;
    [firstQuestionController.view setNeedsUpdateConstraints];
    [self updatePageNumber:0];
    [self updateButtons:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _header.center = CGPointMake(_header.center.x, _header.center.y - _header.bounds.size.height);
    _containerView.center = CGPointMake(_containerView.center.x, _containerView.center.y + self.view.bounds.size.height);
    _footer.center = CGPointMake(_footer.center.x, _footer.center.y + _footer.bounds.size.height);
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.view.alpha = 1.0;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)updatePageNumber:(NSUInteger)index
{
    _pageNumberLabel.text = [NSString stringWithFormat:@"%d of %d", index + 1, _survey.questions.count];
}

- (void)updateButtons:(NSUInteger)index
{
    _previousButton.enabled = index > 0;
    _nextButton.enabled = index < ([_survey.questions count] - 1);
}

- (void)loadQuestion:(NSUInteger)index
{
    if (index < _survey.questions.count) {
        MPSurveyQuestionViewController *controller = _questionControllers[index];
        // replace the placeholder if necessary
        if ((NSNull *)controller == [NSNull null]) {
            MPSurveyQuestion *question = _survey.questions[index];
            NSString *storyboardIdentifier = [NSString stringWithFormat:@"%@ViewController", NSStringFromClass([question class])];
            controller = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];
            if (!controller) {
                NSLog(@"no view controller for storyboard identifier: %@", storyboardIdentifier);
                return;
            }
            controller.delegate = self;
            controller.question = question;
            controller.highlightColor = [[_backgroundImage mp_averageColor] colorWithAlphaComponent:.6];
            controller.view.translatesAutoresizingMaskIntoConstraints = NO;
            _questionControllers[index] = controller;
        }
    }
}

- (void)constrainCurrentQuestionControllerView:(UIView *)view
{
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views];
    constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                                                     options:0
                                                                                                     metrics:nil
                                                                                                       views:views]];
    [_containerView addConstraints:constraints];
    self.currentQuestionConstraints = constraints;

}

- (void)showQuestionAtIndex:(NSUInteger)index animatingForward:(BOOL)forward
{
    if (index < [_survey.questions count]) {
        [self loadQuestion:index];
        UIViewController *fromController = _currentQuestionController;
        UIViewController *toController = _questionControllers[index];
        [fromController willMoveToParentViewController:nil];
        [self addChildViewController:toController];
        NSArray *priorConstraints = _currentQuestionConstraints;
        NSLog(@"_containerView constraints before: %@", _containerView.constraints);
        toController.view.alpha = 0.0;
        [self transitionFromViewController:fromController
                          toViewController:toController
                                  duration:1.0
                                   options:UIViewAnimationOptionCurveEaseIn
                                animations:^{
//                                    [_containerView removeConstraints:priorConstraints];
                                    [self constrainCurrentQuestionControllerView:toController.view];
//                                    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//                                    anim.duration = 1.0;
//                                    anim.byValue = @(M_PI_2);
//                                    [fromController.view.layer addAnimation:anim forKey:@"blah"];
//
//
////                                    CGPoint center = toController.view.center;
////                                    center.x += 200;
////                                    toController.view.center = center;
                                    CGAffineTransform transform = CGAffineTransformRotate(fromController.view.transform, M_PI_2);
                                    fromController.view.transform = transform;
                                    fromController.view.alpha = 0.0;

                                    transform = CGAffineTransformRotate(fromController.view.transform, M_PI_2);
                                    toController.view.transform = transform;
                                    toController.view.alpha = 1.0;

                               }
                                completion:^(BOOL finished){
                                    fromController.view.transform = CGAffineTransformIdentity;
                                    [fromController removeFromParentViewController];
                                    [toController didMoveToParentViewController:self];
                                    NSLog(@"_containerView constraints after: %@", _containerView.constraints);
                                    _currentQuestionController = toController;
                                }];
        [self updatePageNumber:index];
        [self updateButtons:index];
        [self loadQuestion:index - 1];
        [self loadQuestion:index + 1];
    } else {
        NSLog(@"attempt to navigate to invalid question index");
    }
}

- (NSUInteger)currentIndex
{
    return [_questionControllers indexOfObject:_currentQuestionController];
}

- (IBAction)showNextQuestion
{
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex < (_survey.questions.count - 1)) {
        [self showQuestionAtIndex:currentIndex + 1 animatingForward:YES];
    }
}

- (IBAction)showPreviousQuestion
{
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex > 0) {
        [self showQuestionAtIndex:currentIndex - 1 animatingForward:NO];
    }
}

- (IBAction)dismiss
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.view.alpha = 0.0;
                         _header.center = CGPointMake(_header.center.x, _header.center.y - 100);
                         _containerView.center = CGPointMake(_containerView.center.x, _containerView.center.y + self.view.bounds.size.height);
                         _footer.center = CGPointMake(_footer.center.x, _footer.center.y + 100);
                     }
                     completion:^(BOOL finished){
                         [_delegate surveyNavigationControllerWasDismissed:self];
                     }];
    [_mixpanel.people union:@{@"$surveys": @[@(_survey.ID)],
                              @"$collections": @[@(_survey.collectionID)]}];
}

- (void)questionViewController:(MPSurveyQuestionViewController *)controller
    didReceiveAnswerProperties:(NSDictionary *)properties
{
    NSMutableDictionary *answer = [NSMutableDictionary dictionaryWithDictionary:properties];
    [answer addEntriesFromDictionary:@{@"$survey_id": @(_survey.ID),
                                       @"$collection_id": @(_survey.collectionID),
                                       @"$question_id": @(controller.question.ID),
                                       @"$question_type": controller.question.type,
                                       @"$time": [NSDate date]}];
    [_mixpanel.people append:@{@"$answers": answer}];
    if ([self currentIndex] < ([_survey.questions count] - 1)) {
        [self showNextQuestion];
    } else {
        [self dismiss];
    }
}

@end
