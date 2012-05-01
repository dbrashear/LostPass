#import "LostPassAppDelegate.h"
#import "RootViewController.h"
#import "LoginViewController.h"
#import "UnlockViewController.h"
#import "Settings.h"

std::auto_ptr<LastPass::Parser> lastPassDatabase;

@implementation LostPassAppDelegate

@synthesize window = window_;
@synthesize navigationController = navigationController_;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[Settings initialize];

	[self.window addSubview:self.navigationController.view];
	[self.window makeKeyAndVisible];
	
	LoginViewController *loginScreen = [[[LoginViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	[self.navigationController presentModalViewController:loginScreen animated:NO];

	UnlockViewController *unlockScreen = [[[UnlockViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	unlockScreen.mode = UnlockViewControllerModeChoose;
//	unlockScreen.mode = UnlockViewControllerModeVerify;
//	unlockScreen.code = @"0000";
	[loginScreen presentModalViewController:unlockScreen animated:NO];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	/*
	 Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
	 */
}

- (void)dealloc
{
	[navigationController_ release];
	[window_ release];

	[super dealloc];
}

@end
