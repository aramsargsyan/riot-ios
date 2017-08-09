//
//  TodayViewController.m
//  RiotTodayWidget
//
//  Created by Aram Sargsyan on 8/6/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
//#import "RecentsDataSource.h"

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic) MXKRecentsDataSource *recentsDataSource;

@end

@implementation TodayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.view.backgroundColor = [UIColor redColor];
    self.view.alpha = 0.7;
    
    NSLog(@"SDK version --- %@", MatrixSDKVersion);
    NSLog(@"Kit version --- %@", MatrixKitVersion);
    
    [self prepareSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionSync:) name:kMXSessionDidSyncNotification object:nil];
}

- (void)prepareSession
{
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];
    
    // Start a matrix session for each enabled accounts.
    NSLog(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts");
    [accountManager prepareSessionForActiveAccounts];
    
    // Resume all existing matrix sessions
    NSArray *mxAccounts = accountManager.activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
        [self addMatrixSession:account.mxSession];
    }
}

- (void)onSessionSync:(NSNotification *)notification
{
    self.recentsDataSource = [[MXKRecentsDataSource alloc] initWithMatrixSession:self.mainSession];
    
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

@end
