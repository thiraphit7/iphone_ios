/*
 * AppDelegate.m - SEPwn iOS App Delegate Implementation
 */

#import "AppDelegate.h"
#import "jailbreak.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[SEPwn] Application launched");
    NSLog(@"[SEPwn] Version: %s", SEPWN_VERSION);
    NSLog(@"[SEPwn] Target: iOS %s (%s)", TARGET_IOS_VERSION, TARGET_BUILD);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
    jailbreak_cleanup();
}

@end
