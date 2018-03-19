//
//  IMBDevicePageWindow.m
//  iOSFiles
//
//  Created by 龙凡 on 2018/1/31.
//  Copyright © 2018年 iMobie. All rights reserved.
//

#import "IMBDevicePageWindow.h"
//#import "IMBNoTitleBarWindow.h"
#import "IMBDrawOneImageBtn.h"
#import "IMBToolbarWindow.h"
#import "IMBiPod.h"
#import "IMBInformation.h"
#import "IMBInformationManager.h"
#import "IMBCommonEnum.h"
#import "IMBTrack.h"
#import "IMBPhotoEntity.h"
#import "IMBDeviceConnection.h"
#import "IMBBooksManager.h"
#import "IMBBookEntity.h"
#import "IMBApplicationManager.h"
#import "IMBAppEntity.h"
#import "IMBDevicePageFolderModel.h"
#import "IMBDetailViewControler.h"
#import "IMBSystemCollectionViewController.h"
#import "LoadingView.h"
#import "IMBStackBox.h"
#import "IMBPhotoCategoryController.h"
#import "IMBToolBarView.h"
#import "IMBPhotoCategoryController.h"
#import "IMBAppsListViewController.h"
#import "IMBCommonDefine.h"
#import <objc/runtime.h>
#import "SystemHelper.h"


#import "IMBDevicePageViewController.h"
static CGFloat const rowH = 40.0f;
static CGFloat const labelY = 10.0f;

@interface IMBDevicePageWindow ()<NSTabViewDelegate,NSTableViewDataSource>
{
    @private
    IMBInformation *_information;
    NSOperationQueue *_opQueue;
    NSMutableArray *_dataArray;
    NSArray *_headerTitleArr;
    NSArray *_folderNameArray;
    IMBDetailViewControler *_detailVc;
    LoadingView *_loadingView;
  
    IBOutlet IMBToolButtonView *_toolBarView;
    IBOutlet NSButton *_backBtn;
    IBOutlet NSScrollView *_scrollView;
    IBOutlet NSTableView *_tableView;
    IMBPhotoCategoryController *_pcVc;
}
@end

@implementation IMBDevicePageWindow

//- (void)windowDidLoad {
//    [super windowDidLoad];
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//}

- (id)initWithiPod:(IMBiPod *)ipod {
    if (self = [super initWithWindowNibName:@"IMBDevicePageWindow"]) {
        _iPod = [ipod retain];
//        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
//    [_topView setIsBommt:YES];
    
    IMBToolButtonView *buttonView = [[IMBToolButtonView alloc]initWithFrame:NSMakeRect(0, 0, 400, 50)];
    [buttonView loadButtons:[NSArray arrayWithObjects:@(0),@(17),@(1),@(2),@(4),@(5),@(12),nil] Target:self DisplayMode:YES];
    [_topView addSubview:buttonView];
    [self.window setTitle:_iPod.deviceInfo.deviceName];
    NSButton *btn =  [self.window standardWindowButton:NSWindowCloseButton];

    NSButton *btn2 =  [self.window standardWindowButton:NSWindowZoomButton];
    [btn2 setFrame:NSMakeRect(0,0, 20, 20)];
    [btn setHidden:YES];
    [btn2 setHidden:YES];
    
    
    [btn2 setAction:@selector(zoomWindow:)];
    [btn2 setTarget:self];
    
    [btn setAction:@selector(closeWindow:)];
    [btn setTarget:self];
    
    [_title setStringValue:_iPod.deviceInfo.deviceName];
    
    IMBDrawOneImageBtn *button = [[IMBDrawOneImageBtn alloc]initWithFrame:NSMakeRect(12, 20, 12, 12)];
    [button mouseDownImage:[NSImage imageNamed:@"windowclose3"] withMouseUpImg:[NSImage imageNamed:@"windowclose"] withMouseExitedImg:[NSImage imageNamed:@"windowclose"] mouseEnterImg:[NSImage imageNamed:@"windowclose2"]];
    [button setEnabled:YES];
    [button setTarget:self];
    [button setAction:@selector(closeWindow:)];
    [button setBordered:NO];
    [_topView initWithLuCorner:YES LbCorner:NO RuCorner:YES RbConer:NO CornerRadius:5];
    [_topView setBackgroundColor:COLOR_DEVICE_Main_WINDOW_TOPVIEW_COLOR];
    [_topView addSubview:button];
   
    [(IMBToolbarWindow *)self.window setTitleBarHeight:0];
    [(IMBToolbarWindow *)self.window setBackgroundColor:[NSColor whiteColor]];
    [self.window setMovableByWindowBackground:YES];

    IMBDevicePageViewController *pageViewController = [[IMBDevicePageViewController alloc]initWithiPod:_iPod];
    [_rootBox setContentView:pageViewController.view];
}

- (void)selectedDeviceDidChangeNoti:(NSNotification *)noti {
    
    IMBBaseInfo *baseInfo = [noti object];
    
    if (_devPopover.isShown) {
        [_devPopover close];
    }
//    [self setDeviceInfosWithiPod:baseInfo];
//    IMBDeviceConnection *deviceConnection = [IMBDeviceConnection singleton];
//    IMBiPod *ipod = [deviceConnection getiPodByKey:baseInfo.uniqueKey];
//    
//    if (!baseInfo.isSelected) {
//        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5/*延迟执行时间*/ * NSEC_PER_SEC));
//        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
//            baseInfo.isSelected = YES;
//            IMBDevicePageWindow *devicePagewindow = [[IMBDevicePageWindow alloc] initWithiPod:ipod];
//            [[devicePagewindow window] center];
//            [devicePagewindow showWindow:self];
//            [_windowControllerDic setObject:devicePagewindow forKey:ipod.uniqueKey];
//            [devicePagewindow release];
//            devicePagewindow = nil;
//        });
//    }else{
//        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5/*延迟执行时间*/ * NSEC_PER_SEC));
//        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
//            IMBDevicePageWindow *devicePagewindow = [_windowControllerDic objectForKey:ipod.uniqueKey];
//            [[devicePagewindow window] center];
//            [devicePagewindow showWindow:self];
//        });
//    }
}

- (void)selectedDeviceBtnClicked:(IMBSelecedDeviceBtn *)sender {
    
    IMBDeviceConnection *deviceConnection = [IMBDeviceConnection singleton];
    if (!_selectedDeviceBtn.isDisable) {
        if (_devPopover != nil) {
            if (_devPopover.isShown) {
                [_devPopover close];
                return;
            }
        }
        if (_devPopover != nil) {
            [_devPopover release];
            _devPopover = nil;
        }
        _devPopover = [[NSPopover alloc] init];
        
        if ([[SystemHelper getSystemLastNumberString] isVersionMajorEqual:@"10"]) {
            _devPopover.appearance = (NSPopoverAppearance)[NSAppearance appearanceNamed:NSAppearanceNameAqua];
        }else {
            _devPopover.appearance = NSPopoverAppearanceMinimal;
        }
        
        _devPopover.animates = YES;
        _devPopover.behavior = 0;
        _devPopover.delegate = self;
        
        IMBDevViewController *devController = [[IMBDevViewController alloc] initWithNibName:@"IMBDevViewController" bundle:nil];
        CGFloat w = 300.0f;
        CGFloat h = 50.0f*deviceConnection.allDevices.count;
        h = h > 200.0f ? 200.0f : h;
        
        devController.view.frame = NSMakeRect(0, 0, w, h);
        
        NSMutableArray *allDevices = [[NSMutableArray alloc] init];
        
        if (deviceConnection.allDevices.count) {
            for (IMBBaseInfo *baseInfo in deviceConnection.allDevices) {
                [allDevices addObject:baseInfo];
            }
            if (_devPopover != nil) {
                _devPopover.contentViewController = devController;
            }
            devController.devices = allDevices;
            NSRectEdge prefEdge = NSMaxYEdge;
            NSRect rect = NSMakeRect(sender.bounds.origin.x, sender.bounds.origin.y, sender.bounds.size.width, sender.bounds.size.height);
            [_devPopover showRelativeToRect:rect ofView:sender preferredEdge:prefEdge];
        }
    }
}

//- (void)setup {
//    [self addNotis];
//    
//    
//    
//    if (_opQueue) {
//        [_opQueue release];
//        _opQueue = nil;
//    }
//    if (_dataArray) {
//        [_dataArray release];
//        _dataArray = nil;
//    }
//    
//    _dataArray = [[NSMutableArray alloc] init];
//    
//    if (!_headerTitleArr) {
//        NSString *path = [[NSBundle mainBundle] pathForResource:IMBDevicePageHeaderTitleNamesPlist ofType:nil];
//        _headerTitleArr = [NSArray arrayWithContentsOfFile:path];
//        
//        path = [[NSBundle mainBundle] pathForResource:IMBDevicePageFolderNamesPlist ofType:nil];
//        _folderNameArray = [NSArray arrayWithContentsOfFile:path];
//    }
//    NSInteger idx = IMBDevicePageWindowFolderEnumPhoto;
//    if (_folderNameArray.count) {
//        for (NSString *name in _folderNameArray) {
//            
//            IMBDevicePageFolderModel *model = [[[IMBDevicePageFolderModel alloc] init] autorelease];
//            model.name = name;
//            model.idx = idx++;
//            model.counts = -1;
//            [_dataArray addObject:model];
//        }
//    }
//    
//    _opQueue = [[NSOperationQueue alloc] init];
//    [_opQueue setMaxConcurrentOperationCount:4];
//    
//    _information = [[IMBInformation alloc] initWithiPod:_iPod];
//    
//    
//    [_opQueue addOperationWithBlock:^{
//        if (_information) {
//            //music
//            [_information refreshMedia];
//            NSArray *audioArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:(int)Audio],
//                                   nil];
//            
//            NSArray *trackArray = [[NSMutableArray alloc] initWithArray:[_information getTrackArrayByMediaTypes:audioArray]];
//            
//            [self setDataArrayWithType:@"Media" handle:^(IMBDevicePageFolderModel *model) {
//                model.trackArray = [trackArray retain];
//            }];
//            
//            IMBFLog(@"%@",trackArray);
//            for (IMBTrack *track in trackArray) {
//                IMBFLog(@"%@",track);
//            }
//            //video
//            NSArray *videoArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:(int)Video],
//                                   [NSNumber numberWithInt:(int)TVShow],
//                                   [NSNumber numberWithInt:(int)MusicVideo],
//                                   [NSNumber numberWithInt:(int)HomeVideo],
//                                   nil];
//            trackArray = [[NSMutableArray alloc] initWithArray:[_information getTrackArrayByMediaTypes:videoArray]];
//            
//            [_information.ipod setMediaLoadFinished:YES];
//            [_information.ipod setVideoLoadFinished:YES];
//            
//            [self setDataArrayWithType:@"Video" handle:^(IMBDevicePageFolderModel *model) {
//                model.trackArray = [trackArray retain];
//            }];
//            
//            
//            IMBFLog(@"%@",trackArray);
//            for (IMBTrack *track in trackArray) {
//                IMBFLog(@"%@",track);
//            }
//            
//            [trackArray release];
//            trackArray = nil;
//            
//        }
//    }];
//    
//    [_opQueue addOperationWithBlock:^{
//        if (_information) {
//            //photo
////            [_information refreshCameraRoll];
////            [_information refreshPhotoStream];
////            [_information refreshPhotoLibrary];
////            [_information refreshVideoAlbum];
//            [_information loadphotoData];
//            
//            [_information.ipod setPhotoLoadFinished:YES];
//            
//            NSMutableArray *photoArray = [[NSMutableArray alloc] init];
//            NSMutableArray *cameraRoll = [[NSMutableArray alloc] init];
////            NSArray *ary = [_information photovideoArray];
//            [cameraRoll addObjectsFromArray:[_information camerarollArray] ? [_information camerarollArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information photovideoArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information photoSelfiesArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information screenshotArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information slowMoveArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information timelapseArray] : [NSArray array]];
//            [cameraRoll addObjectsFromArray:[_information photovideoArray] ? [_information panoramasArray] : [NSArray array]];
//            [photoArray addObject:cameraRoll];
//            [photoArray addObject:[_information photostreamArray] ? [_information photostreamArray] : [NSArray array]];
//            [photoArray addObject:[_information photolibraryArray] ? [_information photolibraryArray] : [NSArray array]];
//            
//            [self setDataArrayWithType:@"Photo" handle:^(IMBDevicePageFolderModel *model) {
//                model.photoArray = [photoArray retain];
//            }];
//            
//            
//            IMBFLog(@"%@",photoArray);
//            for (IMBPhotoEntity *photo in photoArray) {
//                IMBFLog(@"%@",photo);
//            }
//            [cameraRoll release];
//            cameraRoll = nil;
//            [photoArray release];
//            photoArray = nil;
//        }
//    }];
//    
//    [_opQueue addOperationWithBlock:^{
//        if (_information) {
//            //book
//            [_information loadiBook];
//            NSArray *ibooks = [[_information allBooksArray] retain];
//            [_information.ipod setBookLoadFinished:YES];
//            [self setDataArrayWithType:@"Book" handle:^(IMBDevicePageFolderModel *model) {
//                model.booksArray = [ibooks retain];
//            }];
//            
//            
//            for (IMBBookEntity *book in ibooks) {
//                IMBFLog(@"%@",book);
//            }
//            [ibooks release];
//            ibooks = nil;
//        }
//    }];
//    
//    [_opQueue addOperationWithBlock:^{
//        if (_information) {
//            //apps
//            IMBApplicationManager *appManager = [[_information applicationManager] retain];
//            [appManager loadAppArray];
//            NSArray *appArray = [appManager appEntityArray];
//            [_information.ipod setAppsLoadFinished:YES];
//            
//            [self setDataArrayWithType:@"Apps" handle:^(IMBDevicePageFolderModel *model) {
//                model.appsArray = [appArray retain];
//            }];
//            
//            
//            IMBFLog(@"%@",appArray);
//            for (IMBAppEntity *app in appArray) {
//                IMBFLog(@"%@",app);
//            }
//            
//            
//            [appArray release];
//            appArray = nil;
//            
//            [appManager release];
//            appManager = nil;
//        }
//    }];
//    [_opQueue addOperationWithBlock:^{
//        if (_information) {
//            //other
//            [self setDataArrayWithType:@"Other" handle:^(IMBDevicePageFolderModel *model) {
//                model.sizeString = @"-";
//                model.counts = 0;
//                model.countsString = @"-";
//            }];
//        }
//    }];
//    
//}

- (void)setDataArrayWithType:(NSString *)type handle:(void(^)(IMBDevicePageFolderModel *model))handleBlock {
    for (IMBDevicePageFolderModel *model in _dataArray) {
        if ([model.name isEqualToString:type]) {
            model.counts = 0;
            if (handleBlock) {
                handleBlock(model);
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                [_tableView endUpdates];
                
//                [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:model.idx] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
                [_tableView reloadData];
            });
            break;
        }
    }
}

/**
 *  设置view
 */
- (void)setupView {
    if (_rootBox) {
        objc_setAssociatedObject(_iPod, &kIMBDevicePageRootBoxKey, _rootBox, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    objc_setAssociatedObject(_iPod, &kIMBDevicePageWindowKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [_rootBox setContentView:_scrollView];
    NSInteger count = _tableView.tableColumns.count;
    for (NSInteger i = 0; i < count; i++) {
        [_tableView removeTableColumn:_tableView.tableColumns[0]];
    }
    _scrollView.hasHorizontalScroller = NO;
    //注册该表的拖动类型
    
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    
    if (!_headerTitleArr) {
        NSString *path = [[NSBundle mainBundle] pathForResource:IMBDevicePageHeaderTitleNamesPlist ofType:nil];
        _headerTitleArr = [NSArray arrayWithContentsOfFile:path];
    }
    
    if (_headerTitleArr.count) {
        NSInteger count = _headerTitleArr.count;
        CGFloat cW = _tableView.frame.size.width/count;
        for (NSInteger i = 0; i < count; i++) {
            NSTableHeaderCell *cell = [[NSTableHeaderCell alloc] initTextCell:_headerTitleArr[i]];
            cell.alignment = NSCenterTextAlignment;
            NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:_headerTitleArr[i]];
            
            [column setHeaderCell:cell];
            [column setWidth:cW];
            [_tableView addTableColumn:column];
        }
        
    }
}


- (void)addNotis {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startLoadingAnim:) name:IMBDevicePageStartLoadingAnimNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopLoadingAnim:) name:IMBDevicePageStopLoadingAnimNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showToolbar:) name:IMBDevicePageShowToolbarNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideToolbar:) name:IMBDevicePageHideToolbarNoti object:nil];
}

- (void)removeNotis {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IMBDevicePageStartLoadingAnimNoti object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IMBDevicePageStopLoadingAnimNoti object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IMBDevicePageShowToolbarNoti object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IMBDevicePageHideToolbarNoti object:nil];
}
-(void)dealloc {
    
    [self cleanMemory];
    [self removeNotis];
    [_systemCollectionViewController release];
    _systemCollectionViewController = nil;
    [super dealloc];
}

- (void)zoomWindow:(id)sender {

}

- (void)closeWindow:(id)sender {
//    [self cleanMemory];
//    IMBDeviceConnection *deviceConnection = [IMBDeviceConnection singleton];
//    for (IMBBaseInfo *baseInfo in deviceConnection.allDevices) {
//        if ([baseInfo.uniqueKey isEqualToString:_iPod.uniqueKey]) {
//            baseInfo.isSelected = NO;
//        }
//    }
    [self.window close];
//    [self.window release];
}

- (void)cleanMemory {
    if (_information) {
        [_information release];
        _information = nil;
    }
    
    if (_opQueue) {
        [_opQueue cancelAllOperations];
        [_opQueue release];
        _opQueue = nil;
    }
    
    if (_iPod) {
        [_iPod release];
        _iPod = nil;
    }
    
    if (_dataArray) {
        [_dataArray release];
        _dataArray = nil;
    }
    
    if (_pcVc) {
        [_pcVc release];
        _pcVc = nil;
    }
    
    if (_detailVc) {
        [_detailVc release];
        _detailVc = nil;
    }
}
#pragma mark --  NSTabViewDelegate,NSTableViewDataSource

- (void)tableViewDoubleClicked:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    NSLog(@"Double Clicked.%ld ",rowNumber);
    // ...
    IMBDevicePageFolderModel *model = [_dataArray objectAtIndex:rowNumber];
    if (rowNumber == 4) {
        [_backBtn setHidden:NO];
        _systemCollectionViewController = [[IMBSystemCollectionViewController alloc] initWithIpod:_iPod withCategoryNodesEnum:0 withDelegate:self];
        [_rootBox pushView:_systemCollectionViewController.view];
        
    }else {
        if (model && model.countsString) {
            //显示详情
            [_backBtn setHidden:NO];
            _title.stringValue = model.name;
            
            if (model.idx == IMBDevicePageWindowFolderEnumPhoto) {
                
                if (_pcVc) {
                    [_pcVc release];
                    _pcVc = nil;
                }
                if (_detailVc) {
                    [_detailVc release];
                    _detailVc = nil;
                }
                _pcVc = [[IMBPhotoCategoryController alloc] initWithNibName:@"IMBPhotoCategoryController" bundle:nil];
                _pcVc.folderModel = [model retain];
                _pcVc.iPod = [_iPod retain];
                [_rootBox pushView:_pcVc.view];
            } else if (model.idx == IMBDevicePageWindowFolderEnumApps) {
                if ([_iPod.deviceInfo.productVersion isVersionMajor:@"8.3"]) {
                    if (_detailVc) {
                        [_detailVc release];
                        _detailVc = nil;
                    }
                    _detailVc = [[IMBDetailViewControler alloc] initWithNibName:@"IMBDetailViewControler" bundle:nil];
                    if (_detailVc.folderModel) {
                        [_detailVc.folderModel release];
                        _detailVc.folderModel = nil;
                    }
                    _detailVc.iPod = [_iPod retain];
                    
                    _detailVc.folderModel = [model retain];
                    [_rootBox pushView:_detailVc.view];
                }else {
                    IMBAppsListViewController *listViewController = [[IMBAppsListViewController alloc]initWithIpod:_iPod];
                    [_rootBox pushView:listViewController.view];
                }
                
            } else {
                if (_detailVc) {
                    [_detailVc release];
                    _detailVc = nil;
                }
                _detailVc = [[IMBDetailViewControler alloc] initWithNibName:@"IMBDetailViewControler" bundle:nil];
                if (_detailVc.folderModel) {
                    [_detailVc.folderModel release];
                    _detailVc.folderModel = nil;
                }
                _detailVc.iPod = [_iPod retain];
                
                _detailVc.folderModel = [model retain];
                [_rootBox pushView:_detailVc.view];
            }
        }
    }
    
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _dataArray.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return rowH;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}


- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    return proposedSelectionIndexes;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *strIdt = [tableColumn identifier];
    NSTableCellView *aView = [tableView makeViewWithIdentifier:strIdt owner:self];
    if (!aView)
        aView = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, rowH)];
    else
        for (NSView *view in aView.subviews)[view removeFromSuperview];
    
    IMBDevicePageFolderModel *model = [_dataArray objectAtIndex:row];
    NSTextField *textField = [[NSTextField alloc] initWithFrame:CGRectMake(0, labelY, tableColumn.width, rowH - 2*labelY)];
    if (model) {
        if ([tableColumn.identifier isEqualToString:@"Name"]) {
            textField.stringValue = model.name;
        }else if ([tableColumn.identifier isEqualToString:@"Time"]) {
            if (model.counts == -1) {
                textField.stringValue = @"loading";
            }else {
                textField.stringValue = model.time;
            }
            
        }else if ([tableColumn.identifier isEqualToString:@"Size"]) {
            if (model.counts == -1) {
                textField.stringValue = @"loading";
            }else {
                textField.stringValue = model.sizeString;
            }
        }else if ([tableColumn.identifier isEqualToString:@"Counts"]) {
            if (model.counts == -1) {
                textField.stringValue = @"loading";
            }else {
                textField.stringValue = model.countsString;
            }
        
        }
    }
    
    textField.font = [NSFont systemFontOfSize:12.0f];
    textField.alignment = NSCenterTextAlignment;
    textField.drawsBackground = NO;
    textField.bordered = NO;
    textField.focusRingType = NSFocusRingTypeNone;
    textField.editable = NO;
    [aView addSubview:textField];
    return aView;
}

#pragma mark -- 按钮点击

- (IBAction)backClicked:(NSButton *)sender {
    [_rootBox popView];
//    IMBPhotoCategoryController *pc = objc_getAssociatedObject(_iPod, &kIMBPhotoCategoryControllerKey);
    if ([_rootBox currentContentView] == _scrollView) {
        [_tableView reloadData];
        [_backBtn setHidden:YES];
        if (_pcVc) {
            [_pcVc release];
            _pcVc = nil;
        }
        _title.stringValue = _iPod.deviceInfo.deviceName;
    }else if ([_rootBox currentContentView] == _pcVc.view) {
        _title.stringValue = @"Photo";
        [_pcVc reloadData];
    }

    
    
}


//- (IBAction)refreshBtnClicked:(NSButton *)sender {
//    IMBInformation *information = [_information retain];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageRefreshClickedNoti object:information];
//    [information release];
//    information = nil;
//}
//
//- (IBAction)toMacBtnClicked:(NSButton *)sender {
//    IMBInformation *information = [_information retain];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageToMacClickedNoti object:information];
//    [information release];
//    information = nil;
//}
//- (IBAction)addToDeviceBtnClicked:(NSButton *)sender {
//    IMBInformation *information = [_information retain];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageAddToDeviceClickedNoti object:information];
//    [information release];
//    information = nil;
//}
//
//- (IBAction)deleteBtnClicked:(NSButton *)sender {
//     IMBInformation *information = [_information retain];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageDeleteClickedNoti object:information];
//    [information release];
//    information = nil;
//}
//- (IBAction)toDeviceBtnClicked:(NSButton *)sender {
//    IMBInformation *information = [_information retain];
//    [[NSNotificationCenter defaultCenter] postNotificationName:IMBDevicePageToDeviceClickedNoti object:information];
//    [information release];
//    information = nil;
//}

#pragma mark -- 通知
- (void)startLoadingAnim:(NSNotification *)noti {
    NSString *key = [noti object];
    if (![key isEqualToString:_iPod.uniqueKey]) return;
    
    _backBtn.enabled = NO;
    if (!_loadingView) {
        _loadingView = [[LoadingView alloc] initWithFrame:_rootBox.bounds];
        _loadingView.layer.backgroundColor = [NSColor whiteColor].CGColor;
        _loadingView.wantsLayer = YES;
        [_rootBox pushView:_loadingView];
        [_loadingView startAnimation];
    }
}
- (void)stopLoadingAnim:(NSNotification *)noti {
    NSString *key = [noti object];
    if (![key isEqualToString:_iPod.uniqueKey]) return;
    if (_loadingView.isAnimating == NO) return;
    
    _backBtn.enabled = YES;
    [_loadingView endAnimation];
    [_rootBox popView];
    [_loadingView release];
    _loadingView = nil;
    
}

- (void)showToolbar:(NSNotification *)noti {
    NSString *key = [noti object];
    if (![key isEqualToString:_iPod.uniqueKey]) return;
    
}

- (void)hideToolbar:(NSNotification *)noti {
    NSString *key = [noti object];
    if (![key isEqualToString:_iPod.uniqueKey]) return;

    
}

- (void)setTitleStr:(NSString *)title {
    _title.stringValue = title;
}
@end
