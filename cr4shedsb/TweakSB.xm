#include "../AppSupport/CPDistributedMessagingCenter.h"
#import "../rocketbootstrap/rocketbootstrap.h"
#import "libnotifications.h"
#include <pthread.h>

@interface Cr4shedServer : NSObject
@end

@implementation Cr4shedServer

+ (void)load {
	[self sharedInstance];
}

+ (id)sharedInstance {
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	if ((self = [super init])) {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter runServerOnCurrentThread];

		[messagingCenter registerForMessageName:@"writeString" target:self selector:@selector(writeString:withUserInfo:)];
		[messagingCenter registerForMessageName:@"createDir" target:self selector:@selector(createDir:withUserInfo:)];
		[messagingCenter registerForMessageName:@"sendNotification" target:self selector:@selector(sendNotification:withUserInfo:)];
	}

	return self;
}

-(NSDictionary*)writeString:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* str = userInfo[@"string"];
    NSString* path = userInfo[@"path"];
    [str writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    return nil;
}

-(NSDictionary*)createDir:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* path = userInfo[@"path"];
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:nil error:nil];
    return @{@"success" : @(success)};
}

-(NSDictionary*)sendNotification:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* content = userInfo[@"content"];
	NSString* bundleID = @"com.muirey03.cr4shedgui";
	NSString* title = @"Cr4shed";
    NSDictionary* notifUserInfo = userInfo[@"userInfo"];
    [CPNotification showAlertWithTitle:title
                                message:content
                                userInfo:notifUserInfo
                                badgeCount:1
                                soundName:nil
                                delay:0.
                                repeats:NO
                                bundleId:bundleID];
    return nil;
}
@end

%ctor
{
    [Cr4shedServer load];
}

#pragma mark Testing
#if 0
@interface SpringBoard
-(void)crash;
@end

void test(void) {}

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)arg1
{
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        /*id i;
        i = @[i];*/
        int* op = (int*)0x4141414141414141;
        *op = 5;
        /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int i = 0x41;
            int* p = &i;
            void (*v)(void) = (void (*)(void))p;
            v();
        });*/
    });
}
%end
#endif
