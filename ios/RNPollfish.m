
#import "RNPollfish.h"

NSString *const kPollfishSurveyReceived = @"surveyReceived";
NSString *const kPollfishSurveyCompleted = @"surveyCompleted";
NSString *const kPollfishUserNotEligible = @"userNotEligible";
NSString *const kPollfishSurveyNotAvailable = @"surveyNotAvailable";
NSString *const kPollfishSurveyOpened = @"surveyOpened";
NSString *const kPollfishSurveyClosed = @"surveyClosed";

@implementation RNPollfish {
    bool isInitialized;
}

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents {
    return @[kPollfishSurveyReceived,
             kPollfishSurveyCompleted,
             kPollfishUserNotEligible,
             kPollfishSurveyNotAvailable,
             kPollfishSurveyOpened,
             kPollfishSurveyClosed
             ];
}

#pragma mark exported methods

// Initialize Pollfish
RCT_EXPORT_METHOD(initialize :(NSString *)apiKey :(BOOL *)debugMode :(BOOL *)customMode :(BOOL *)offerWallMode :(NSString *)userId)
{
    if (!isInitialized) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyNotAvailable) name:@"PollfishSurveyNotAvailable" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollfishOpened) name:@"PollfishOpened" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollfishClosed) name:@"PollfishClosed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollfishUsernotEligible) name:@"PollfishUserNotEligible" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollfishCompleted:) name:@"PollfishSurveyCompleted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pollfishReceived:) name:@"PollfishSurveyReceived" object:nil];
        isInitialized = YES;
    }

    NSLog(@"initialize Pollfish");

    PollfishParams *pollfishParams =  [PollfishParams initWith:^(PollfishParams *pollfishParams) {
        pollfishParams.releaseMode = !debugMode;
        pollfishParams.offerwallMode = offerWallMode;
        pollfishParams.rewardMode = customMode;
        pollfishParams.requestUUID = userId;
    }];
    
    [Pollfish initWithAPIKey:apiKey andParams:pollfishParams];
}

RCT_EXPORT_METHOD(show)
{
    NSLog(@"show Pollfish");
    [Pollfish show];
}

RCT_EXPORT_METHOD(hide)
{
    NSLog(@"hide Pollfish");
    [Pollfish hide];
}

RCT_EXPORT_METHOD(destroy)
{
    NSLog(@"destroy Pollfish");
    [Pollfish destroy];
}

RCT_REMAP_METHOD(surveyAvailable, surveyAvailableWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BOOL isPresent = [Pollfish isPollfishPresent];
    NSLog(@"isPollfishPresent");
    NSLog(isPresent ? @"YES" : @"NO");
    resolve([NSNumber numberWithBool:isPresent]);
}

#pragma mark delgate events

- (void)pollfishReceived:(NSNotification *)notification
{
    BOOL playfulSurvey = [[[notification userInfo] valueForKey:@"playfulSurvey"] boolValue];
    int surveyPrice = [[[notification userInfo] valueForKey:@"surveyPrice"] intValue];
    NSDictionary *surveyInfo = @{
        @"surveyPrice" : [NSNumber numberWithInt:surveyPrice],
        @"playfulSurvey" : [NSNumber numberWithBool:playfulSurvey]
    };
    NSLog(@"Pollfish Survey Received - Playful Survey: %@ with survey price: %d" , playfulSurvey?@"YES":@"NO", surveyPrice);
    [self sendEventWithName:kPollfishSurveyReceived body:surveyInfo];
}

- (void)pollfishCompleted:(NSNotification *)notification
{
    BOOL playfulSurvey = [[[notification userInfo] valueForKey:@"playfulSurvey"] boolValue];
    int surveyPrice = [[[notification userInfo] valueForKey:@"surveyPrice"] intValue];
    NSDictionary *surveyInfo = @{
        @"surveyPrice" : [NSNumber numberWithInt:surveyPrice],
        @"playfulSurvey" : [NSNumber numberWithBool:playfulSurvey]
    };
    NSLog(@"Pollfish Survey Completed - Playful Survey: %@ with survey price: %d" , playfulSurvey?@"YES":@"NO", surveyPrice);
    [self sendEventWithName:kPollfishSurveyCompleted body:surveyInfo];
}

- (void)pollfishUsernotEligible
{
    NSLog(@"Pollfish User Not Eligible");
    [self sendEventWithName:kPollfishUserNotEligible body:nil];
}

- (void)surveyNotAvailable
{
    NSLog(@"Pollfish Survey Not Available!");
    [self sendEventWithName:kPollfishSurveyNotAvailable body:nil];
}

- (void)pollfishOpened
{
    NSLog(@"Pollfish is opened!");
    [self sendEventWithName:kPollfishSurveyOpened body:nil];
}

- (void)pollfishClosed
{
    NSLog(@"Pollfish is closed!");
    [self sendEventWithName:kPollfishSurveyClosed body:nil];
}
@end
