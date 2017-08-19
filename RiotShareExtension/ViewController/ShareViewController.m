/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ShareViewController.h"
#import "SegmentedViewController.h"
#import "RoomsListViewController.h"
#import "FallbackViewController.h"
#import "ShareRecentsDataSource.h"
#import "ShareExtensionManager.h"


@interface ShareViewController ()

@property (nonatomic) NSArray <MXRoom *> *rooms;

@property (nonatomic) MXKRecentsDataSource *recentsDataSource;

@property (weak, nonatomic) IBOutlet UIView *masterContainerView;
@property (weak, nonatomic) IBOutlet UILabel *tittleLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) SegmentedViewController *segmentedViewController;


@end


@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareSession];
    [self configureViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionSync:) name:kMXSessionDidSyncNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private

- (void)prepareSession
{
    // Apply the application group name
    [MXKAppSettings standardAppSettings].applicationGroup = @"group.im.vector";
    
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

- (void)configureViews
{
    self.masterContainerView.layer.cornerRadius = 7;
    
    if (self.mainSession)
    {
        self.tittleLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"send_to", @"Vector", nil), @""];
        [self configureSegmentedViewController];
    }
    else
    {
        NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
        NSString *bundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        self.tittleLabel.text = bundleDisplayName;
        [self configureFallbackViewController];
    }
}

- (void)configureSegmentedViewController
{
    self.segmentedViewController = [SegmentedViewController segmentedViewController];
    
    NSArray *titles = @[NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil) , NSLocalizedStringFromTable(@"title_people", @"Vector", nil)];
    
    void (^failureBlock)() = ^void() {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ShareExtensionManager sharedManager] terminateExtensionCanceled:NO];
        }];
    };
    
    ShareRecentsDataSource *roomsDataSource = [[ShareRecentsDataSource alloc] initWithMatrixSession:self.mainSession dataSourceMode:RecentsDataSourceModeRooms];
    RoomsListViewController *roomsViewController = [RoomsListViewController listViewControllerWithDataSource:roomsDataSource failureBlock:failureBlock];
    roomsDataSource.delegate = roomsViewController;
    
    ShareRecentsDataSource *peopleDataSource = [[ShareRecentsDataSource alloc] initWithMatrixSession:self.mainSession dataSourceMode:RecentsDataSourceModePeople];
    RoomsListViewController *peopleViewController = [RoomsListViewController listViewControllerWithDataSource:peopleDataSource failureBlock:failureBlock];
    peopleDataSource.delegate = peopleViewController;
    
    [self.segmentedViewController initWithTitles:titles viewControllers:@[roomsViewController, peopleViewController] defaultSelected:0];
    
    [self addChildViewController:self.segmentedViewController];
    [self.contentView addSubview:self.segmentedViewController.view];
    [self.segmentedViewController didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:self.segmentedViewController.view toSuperviewEdges:self.contentView];
}

- (void)configureFallbackViewController
{
    FallbackViewController *fallbackVC = [FallbackViewController new];
    [self addChildViewController:fallbackVC];
    [self.contentView addSubview:fallbackVC.view];
    [fallbackVC didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:fallbackVC.view toSuperviewEdges:self.contentView];
}

- (void)autoPinSubviewEdges:(UIView *)subview toSuperviewEdges:(UIView *)superview
{
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

#pragma mark - Notifications

- (void)onSessionSync:(NSNotification *)notification
{
    if ([notification.object isEqual:self.mainSession] && !self.rooms.count)
    {
        self.recentsDataSource = [[MXKRecentsDataSource alloc] initWithMatrixSession:self.mainSession];
    }
}

#pragma mark - Actions

- (IBAction)close:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[ShareExtensionManager sharedManager] terminateExtensionCanceled:YES];
    }];
}


@end
