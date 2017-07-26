
@interface SCFeedItem : NSObject
@property (copy) NSString *feedId;
@property (copy) NSDate *interactionTimestamp;
@end

@interface Friend : NSObject
@property (copy) NSString *display;
@property (copy) NSString *atomicName;
@end

@interface SCRecentFriends : NSObject
@property (copy) NSArray *recentFriends;
-(void)removeFriend:(id)arg1;
@end

@interface Friends : NSObject
@property (copy) SCRecentFriends *recentFriends;
- (Friend *)friendForUserId:(NSString *)arg1;
- (id)userIdForUsername:(NSString *)arg1;
- (void)updateRecentsWithUsernames:(id)arg1;
@end

@interface SCFeedChatCellViewModel : NSObject
@property (copy) SCFeedItem *feedItem;
- (NSString *)subLabelText;
@end

@interface SCConversationFeedDataSource : NSObject
@property (copy) NSMutableArray *unreadUsernames;
+ (NSArray *)nz9_getUnreadFriends;
+ (void)nz9_addNewRecentFriends;
@end


static NSMutableArray *unreadUsernames = [[NSMutableArray alloc] init];
static Friends *sharedFriends;
static int count = 0; // Fixes some crashing issues magically, don't question it


%hook Friends
- (id)allFriends {
	sharedFriends = self;
	return 	%orig;
}
%end

%hook SCConversationFeedDataSource
- (void)reloadFeed {
	%orig;
	if(count >= 10) {
		NSArray *recentViewModels = MSHookIvar<NSArray *>(self, "_recentViewModels");
		[unreadUsernames removeAllObjects];
		for(SCFeedChatCellViewModel *cellViewModel in recentViewModels)
		{
			SCFeedItem *item = cellViewModel.feedItem;
			Friend *aFriend = [sharedFriends friendForUserId:[sharedFriends userIdForUsername:item.feedId]];
			NSMutableArray *displayArray = [[NSMutableArray alloc] init];
			[displayArray addObjectsFromArray:[aFriend.display componentsSeparatedByString:@" "]];
			if([[[[cellViewModel subLabelText] componentsSeparatedByString:@" "] objectAtIndex:0] isEqualToString: @"Received"] && ([item.interactionTimestamp timeIntervalSinceNow] >= -86400)) {
				[unreadUsernames addObject:item.feedId];
				if(![[displayArray lastObject] isEqualToString:@"🕒"]) {
					if(![aFriend.display isEqualToString:@""]) {
						[aFriend setDisplay:[NSString stringWithFormat:@"%@ 🕒", aFriend.display]];
					}
					else {
						[aFriend setDisplay:[NSString stringWithFormat:@"%@ 🕒", aFriend.atomicName]];
					}
				}
			}
			else if([[displayArray lastObject] isEqualToString:@"🕒"]){
				[displayArray removeLastObject];
				[aFriend setDisplay:[displayArray componentsJoinedByString:@" "]];
			}
		}
		[sharedFriends updateRecentsWithUsernames:unreadUsernames];
	}
	else {
		count++;
	}
}
%end
