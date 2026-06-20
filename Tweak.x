#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wobjc-method-access"

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

// ============================================================
// BIẾN TOÀN CỤC LƯU TRẠNG THÁI
// ============================================================
static BOOL isBlockEnabled = YES;

// ============================================================
// LƯU TRẠNG THÁI
// ============================================================
static void saveState() {
    NSDictionary *dict = @{@"enabled": @(isBlockEnabled)};
    [dict writeToFile:@"/var/mobile/Library/Preferences/com.sigmabotg.nocapcutnotifications.plist" atomically:YES];
}

static void loadState() {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.sigmabotg.nocapcutnotifications.plist"];
    if (dict) {
        isBlockEnabled = [dict[@"enabled"] boolValue];
    }
}

// ============================================================
// TẠO NÚT BẬT/TẮT
// ============================================================
@interface ToggleButton : UIButton
@end

@implementation ToggleButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupButton];
    }
    return self;
}

- (void)setupButton {
    [self setTitle:@"🔇 Đang chặn" forState:UIControlStateNormal];
    [self setTitle:@"🔊 Đang bật" forState:UIControlStateSelected];
    
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    self.backgroundColor = [UIColor systemRedColor];
    self.layer.cornerRadius = 12;
    self.layer.masksToBounds = YES;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    
    self.selected = !isBlockEnabled;
    
    [self addTarget:self action:@selector(toggleState) forControlEvents:UIControlEventTouchUpInside];
}

- (void)toggleState {
    isBlockEnabled = !isBlockEnabled;
    self.selected = !isBlockEnabled;
    saveState();
    
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    if (window) {
        NSString *msg = isBlockEnabled ? @"✅ Đã chặn thông báo CapCut" : @"🔕 Đã bật thông báo CapCut";
        UIAlertController *alert = [UIAlertController 
            alertControllerWithTitle:@"CapCut" 
            message:msg 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

@end

// ============================================================
// HOOK CAPCUT - THÊM NÚT VÀO GIAO DIỆN
// ============================================================
%hook UIViewController

- (void)viewDidLoad {
    %orig;
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.lemon.lvoverseas"] || 
        [bundleID isEqualToString:@"com.lemon.lv"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat width = 120;
            CGFloat height = 40;
            CGFloat x = self.view.bounds.size.width - width - 20;
            CGFloat y = 60;
            
            ToggleButton *button = [[ToggleButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            button.tag = 9999;
            
            UIView *oldButton = [self.view viewWithTag:9999];
            if (oldButton) [oldButton removeFromSuperview];
            
            [self.view addSubview:button];
        });
    }
}
%end  // <--- ĐÓNG HOOK UIViewController

// ============================================================
// CHẶN LOCAL NOTIFICATION
// ============================================================
%hook UIApplication

- (void)presentLocalNotificationNow:(UILocalNotification *)notification {
    if (isBlockEnabled) return;
    %orig;
}

- (void)scheduleLocalNotification:(UILocalNotification *)notification {
    if (isBlockEnabled) return;
    %orig;
}

- (void)setApplicationIconBadgeNumber:(NSInteger)badgeNumber {
    if (isBlockEnabled) {
        %orig(0);
        return;
    }
    %orig(badgeNumber);
}
%end  // <--- ĐÓNG HOOK UIApplication

// ============================================================
// CHẶN PUSH NOTIFICATION
// ============================================================
%hook AppDelegate

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (isBlockEnabled) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    %orig;
}
%end  // <--- ĐÓNG HOOK AppDelegate

// ============================================================
// CHẶN UNUserNotificationCenter (iOS 10+)
// ============================================================
%hook UNUserNotificationCenter

- (void)addNotificationRequest:(UNNotificationRequest *)request withCompletionHandler:(void (^)(NSError *error))completionHandler {
    if (isBlockEnabled) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    %orig;
}
%end  // <--- ĐÓNG HOOK UNUserNotificationCenter

// ============================================================
// KHỞI TẠO
// ============================================================
%ctor {
    loadState();
    NSLog(@"=========================================");
    NSLog(@"🚀 CapCut Notification Blocker Loaded!");
    NSLog(@"📌 Trạng thái: %@", isBlockEnabled ? @"BẬT" : @"TẮT");
    NSLog(@"=========================================");
}
// <--- KHÔNG CÓ %end Ở ĐÂY
