//
//  GJGCRecentChatViewController.m
//  ZYChat
//
//  Created by ZYVincent on 15/7/11.
//  Copyright (c) 2015年 ZYProSoft. All rights reserved.
//

#import "GJGCRecentChatViewController.h"
#import "GJGCRecentChatCell.h"
#import "GJGCChatFriendViewController.h"
#import "GJGCChatGroupViewController.h"
#import "GJGCRecentChatDataManager.h"
#import "GJGCRecentChatTitleView.h"

@interface GJGCRecentChatViewController ()<UITableViewDelegate,UITableViewDataSource,GJGCRecentChatDataManagerDelegate>

@property (nonatomic,strong)GJGCRecentChatDataManager *dataManager;

@property (nonatomic,strong)UITableView *listTable;

@property (nonatomic,strong)GJGCRecentChatTitleView *titleView;

@property (nonatomic,strong)dispatch_source_t updateListSource;

@end

@implementation GJGCRecentChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //缓冲更新队列
    self.updateListSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(self.updateListSource, ^{
       
        [self conversationListUpdate];
        
    });
    dispatch_resume(self.updateListSource);
    
    self.dataManager = [[GJGCRecentChatDataManager alloc]init];
    self.dataManager.delegate = self;
    
    self.titleView = [[GJGCRecentChatTitleView alloc]init];
    self.navigationItem.titleView = self.titleView;
    GJGCRecentChatConnectState result = [[EaseMob sharedInstance].chatManager isConnected]? GJGCRecentChatConnectStateSuccess:GJGCRecentChatConnectStateFaild;
    self.titleView.connectState = result;
    
    self.listTable = [[UITableView alloc]init];
    self.listTable.delegate = self;
    self.listTable.dataSource = self;
    self.listTable.frame = self.view.bounds;
    self.listTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.listTable];
    
    [self.dataManager loadRecentConversations];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //重新刷新一下会话
    [self.dataManager loadRecentConversations];
}

#pragma mark - tableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataManager.totalCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    GJGCRecentChatCell *recentCell = (GJGCRecentChatCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!recentCell) {
        
        recentCell = [[GJGCRecentChatCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [recentCell setContentModel:[self.dataManager contentModelAtIndexPath:indexPath]];
    
    return recentCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataManager contentHeightAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    GJGCRecentChatModel *contenModel = [self.dataManager contentModelAtIndexPath:indexPath];
    
    if (contenModel.isGroupChat) {
        
        GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc]init];
        talk.talkType = GJGCChatFriendTalkTypeGroup;
        talk.toId = contenModel.toId;
        talk.toUserName = contenModel.name.string;
        
        GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc]initWithTalkInfo:talk];
        
        [self.navigationController pushViewController:groupChat animated:YES];
        
        return;
    }
    
    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc]init];
    talk.talkType = GJGCChatFriendTalkTypePrivate;
    talk.toId = contenModel.toId;
    talk.toUserName = contenModel.name.string;
    talk.conversation = contenModel.conversation;

    GJGCChatFriendViewController *privateChat = [[GJGCChatFriendViewController alloc]initWithTalkInfo:talk];
    [self.navigationController pushViewController:privateChat animated:YES];
    
}

#pragma mark - dispatch缓冲刷新会话列表

- (void)conversationListUpdate
{
    if (self.view.window != nil) {
        [self.listTable reloadData];
    }
}

#pragma mark - RecentDataManager

- (void)dataManagerRequireRefresh:(GJGCRecentChatDataManager *)dataManager
{
    dispatch_async(dispatch_get_main_queue(), ^{
       
        dispatch_source_merge_data(self.updateListSource, 1);
        
    });
}

- (void)dataManager:(GJGCRecentChatDataManager *)dataManager requireUpdateTitleViewState:(GJGCRecentChatConnectState)connectState
{
    self.titleView.connectState = connectState;
}


@end