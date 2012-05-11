#import "LostPassAppDelegate.h"
#import "LoginViewController.h"
#import "UnlockViewController.h"
#import "SmokeScreenView.h"
#import "Settings.h"

namespace
{

NSTimeInterval const SMOKE_SCREEN_ANIMATION_DURATION = 0.4;
NSTimeInterval const RESET_ANIMATION_DURATION = 2;

NSString *WELCOME_MESSAGE =
	@"Welcome to LostPass!\n\n"
	@"Before you start please choose your personal 4-digit unlock code.\n\n"
	@"Tap to continue.";

NSString *WELCOME_BACK_MESSAGE =
	@"Welcome back to LostPass!\n\n"
	@"The app has been reset. Please choose your new personal 4-digit unlock code.\n\n"
	@"Tap to continue.";

NSString *RESET_MESSAGE =
	@"Hi, this is LostPass!\n\n"
	@"You entered the unlock code incorrectly too many times. The app is going to reset itself and you'll have to start over.  See you in a moment.\n\n"
	@"Tap to continue.";

}

@implementation LostPassAppDelegate

@synthesize window = window_;
@synthesize navigationController = navigationController_;
@synthesize rootController = rootController_;

+ (LostPassAppDelegate *)instance
{
	return [UIApplication sharedApplication].delegate;
}

+ (void)setDatabaseToRoot:(std::auto_ptr<LastPass::Parser>)database
{
	[[self instance].rootController setDatabase:database];
}

+ (void)resetDatabase
{
	[self setDatabaseToRoot:std::auto_ptr<LastPass::Parser>(0)];
	[Settings setDatabase:@"" encryptionKey:@""];
}

+ (void)loadDatabase
{
	assert([Settings haveDatabaseAndKey]);
	[self setDatabaseToRoot:std::auto_ptr<LastPass::Parser>(new LastPass::Parser(
		[[Settings database] UTF8String], 
		[[Settings encryptionKey] UTF8String]))];
}

- (void)pushWelcomeSequence:(NSString *)welcomeText
{
	LoginViewController *loginScreen = [LoginViewController loginScreen];
	[self.navigationController presentModalViewController:loginScreen animated:NO];

	UnlockViewController *unlockScreen = [UnlockViewController chooseScreen];
	unlockScreen.onCodeSet = ^(NSString *code) { 
		[Settings setUnlockCode:code];
		[loginScreen dismissModalViewControllerAnimated:YES];
	};
	[loginScreen presentModalViewController:unlockScreen animated:NO];
	
	// Welcome screen
	UIViewController *welcomeScreen = [SmokeScreenView smokeScreenController:welcomeText autoDismiss:YES];
	[unlockScreen presentModalViewController:welcomeScreen animated:NO];
}

- (void)resetEverything:(SmokeScreenView *)smokeScreen
{
	[self.navigationController dismissModalViewControllerAnimated:NO];
	[self pushWelcomeSequence:WELCOME_BACK_MESSAGE];
	
	// Simulate some busy work by showing the spinning star to the user.
	UIActivityIndicatorView *busyIcon = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	busyIcon.frame = CGRectOffset(
		busyIcon.frame, 
		smokeScreen.frame.size.width / 2 - busyIcon.frame.size.width / 2, 
		smokeScreen.frame.size.height / 2 - busyIcon.frame.size.height / 2 );
	[smokeScreen addSubview:busyIcon];
	[busyIcon startAnimating];
	
	dispatch_after(
		dispatch_time(DISPATCH_TIME_NOW, RESET_ANIMATION_DURATION * NSEC_PER_SEC), 
		dispatch_get_current_queue(), 
		^{
			[smokeScreen slideOut:SMOKE_SCREEN_ANIMATION_DURATION
				onCompletion:^ {
					[smokeScreen removeFromSuperview];
				}];
		});
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[Settings initialize];

	[self.window addSubview:self.navigationController.view];
	[self.window makeKeyAndVisible];
	
	BOOL haveCode = [Settings haveUnlockCode];
	BOOL haveDatabase = [Settings haveDatabaseAndKey];

	if (haveCode)
	{
		UIViewController *screen = nil;
		
		if (haveDatabase)
		{
			// The unlock code is set and we have the database downloaded.
			// Show the unlock screen and go straigh to the accounts.
			// This should be the most common sittuation.
			UnlockViewController *unlockScreen = [UnlockViewController verifyScreen:[Settings unlockCode]];
			
			unlockScreen.onCodeAccepted = ^{
				[LostPassAppDelegate loadDatabase];
				[self.navigationController dismissModalViewControllerAnimated:YES];
			};
			
			unlockScreen.onCodeRejected = ^{
				// Note: __block is needed to avoid a retain cycle within the block.
				__block SmokeScreenView *smokeScreen = [SmokeScreenView smokeScreenView:RESET_MESSAGE];
				[self.window addSubview:smokeScreen];

				smokeScreen.onTouched = ^{
					[self resetEverything:smokeScreen];
				};
			
				[smokeScreen slideIn:SMOKE_SCREEN_ANIMATION_DURATION onCompletion:^{}];

				[LostPassAppDelegate resetDatabase];
			};
			
			screen = unlockScreen;
		}
		else
		{
			// The code is set, but there's no database, so there's no need for unlocking.
			// Go to the login screen.
			screen = [[[LoginViewController alloc] initWithNibName:nil bundle:nil] autorelease];
		}

		[self.navigationController presentModalViewController:screen animated:NO];
	}
	else
	{
		if (haveDatabase)
		{
			// We have the database, but no code has been set.  This is strange.
			// Just wipe the database and make the user login.
			[LostPassAppDelegate resetDatabase];
		}

		[self pushWelcomeSequence:WELCOME_MESSAGE];
	}

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
	[rootController_ release];
	[navigationController_ release];
	[window_ release];

	[super dealloc];
}

@end
