//
//  ViewController.m
//  TestNew
//
//  Created by iMobie on 18/1/8.
//  Copyright © 2018年 iMobie. All rights reserved.
//

#import "ViewController.h"


#include <unistd.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/dirent.h>
#include <mach/error.h>
#include <AppKit/NSApplication.h>
#include "NSString+Category.h"
#include "NSData+Category.h"
#include "NSDictionary+Category.h"
#import <CommonCrypto/CommonDigest.h>
#import "IMBNotificationDefine.h"
#import <AppKit/AppKit.h>

#import "ZLFileTool.h"


#pragma mark -------------------------------------Begin --- MobileDevice.framework internals
// opaque structures
typedef struct _afc_directory			*afc_directory;
typedef struct _afc_dictionary			*afc_dictionary;
typedef struct _afc_operation			*afc_operation;

// Messages passed to device notification callbacks: passed as part of
// am_device_notification_callback_info.
typedef enum {
    ADNCI_MSG_CONNECTED		= 1,
    ADNCI_MSG_DISCONNECTED	= 2,
    ADNCI_MSG_UNSUBSCRIBED	= 3
} adnci_msg;

struct am_device_notification_callback_info {
    am_device	dev;				// 0    device
    uint32_t	msg;				// 4    one of adnci_msg
} __attribute__ ((packed));

// The type of the device notification callback function.
typedef void (*am_device_notification_callback)(struct am_device_notification_callback_info *,void* callback_data);

// notification related functions
mach_error_t AMDeviceNotificationSubscribe(
                                           am_device_notification_callback callback,
                                           uint32_t unused0,
                                           uint32_t unused1,
                                           void *callback_data,
                                           am_device_notification *notification);

mach_error_t AMDeviceNotificationUnsubscribe(
                                             am_device_notification subscription);

// device related functions
mach_error_t	AMDeviceConnect(am_device device);
mach_error_t	AMDeviceDisconnect(am_device device);
uint32_t		AMDeviceGetInterfaceType(am_device device);
//uint32_t		AMDeviceGetInterfaceSpeed(am_device device);
//uint32_t		AMDeviceGetConnectionID(am_device device);
//CFStringRef		AMDeviceCopyDeviceIdentifier(am_device device);
CFStringRef		AMDeviceCopyValue(am_device device, CFStringRef domain,CFStringRef key);
mach_error_t    AMDeviceSetValue(am_device device, CFStringRef domain, CFStringRef name, CFTypeRef value);
mach_error_t	AMDeviceRetain(am_device device);
mach_error_t	AMDeviceRelease(am_device device);

// I can see these in the framework, but they don't seem to be exported
// in a way that lets us link directly against them
//?notexp? CFStringRef AMDeviceCopyDeviceLocation(am_device device);
//		looks to just return dword[device+28]
//?notexp? uint32_t AMDeviceUSBDeviceID(am_device device);
//?notexp? uint32_t AMDeviceUSBLocationID(am_device device);
//?notexp? uint32_t AMDeviceUSBProductID(am_device device);

int AMDevicePair(am_device device);
int AMDeviceIsPaired(am_device device);
// 000039f5 T _AMDevicePair (am_device)
mach_error_t AMDeviceValidatePairing(am_device device);
// 000037e6 T _AMDeviceUnpair (am_device)

mach_error_t AMDeviceLookupApplications(am_device device, CFStringRef apptype, CFDictionaryRef *result);

// 0000251f T _AMDeviceActivate (am_device, int32 )
// 000088ad T _AMDeviceArchiveApplication (am_device, int32, int32, int32, int32)
// 0000891e T _AMDeviceBrowseApplications (am_device, int32)
// 00008ecd T _AMDeviceCheckCapabilitiesMatch
// 0000179b T _AMDeviceConvertError
// 00009063 T _AMDeviceCopyProvisioningProfiles
// 00004133 T _AMDeviceCreate
// 000041d7 T _AMDeviceCreateFromProperties
// 0000243d T _AMDeviceDeactivate (am_device)
// 0000235b T _AMDeviceEnterRecovery (am_device)
// 00008c74 T _AMDeviceInstallApplication
// 0000a598 T _AMDeviceInstallPackage
// 00008f59 T _AMDeviceInstallProvisioningProfile
// 0000159a T _AMDeviceIsValid
// 00008710 T _AMDeviceLookupApplicationArchives
// 00008990 T _AMDeviceLookupApplications (am_device, int32, int32)
// 00009353 T _AMDeviceMountImage
// 000087cb T _AMDeviceRemoveApplicationArchive
// 00008fde T _AMDeviceRemoveProvisioningProfile
// 00002608 T _AMDeviceRemoveValue
// 0000883c T _AMDeviceRestoreApplication
// 0000121a T _AMDeviceSerialize
// 0000280f T _AMDeviceSetValue(am_device, CFStringRef, CFStringRef, CFTypeRef)
// 00005ec5 T _AMDeviceSoftwareUpdate
// 0000794b T _AMDeviceTransferApplication
// 00008a91 T _AMDeviceUninstallApplication
// 0000a232 T _AMDeviceUninstallPackage
// 00003e21 T _AMDeviceUnserialize
// 00008b02 T _AMDeviceUpgradeApplication
// 000035d3 T _AMDeviceValidatePairing

// session related functions

mach_error_t AMDeviceStartSession(am_device device);
mach_error_t AMDeviceStopSession(am_device device);
// service related functions
mach_error_t AMDeviceStartService(am_device device,CFStringRef service_name,am_service *handle,uint32_t *unknown);
mach_error_t AMDeviceSecureStartService(am_device device, CFStringRef service_name, uint32_t *unknown, am_service *handle);
uint32 AMDServiceConnectionGetSocket(am_service handle);
mach_error_t AMDServiceConnectionInvalidate(am_service service);
// 00002f48 T _AMDeviceStartServiceWithOptions
// 000067f9 T _AMDeviceStartHouseArrestService

uint32_t AMDeviceSetWirelessBuddyFlags(am_device device, uint32_t wifi);
uint32_t AMDeviceGetWirelessBuddyFlags(am_device device, uint32_t *wifi);

//  stop backuprestore
mach_error_t AMSCancelBackupRestore(CFStringRef lpudid);

// AFC connection functions
afc_error_t AFCConnectionOpen(am_service handle,uint32_t io_timeout,afc_connection *conn);
afc_error_t AFCConnectionClose(afc_connection conn);
// int _AFCConnectionIsValid(afc_connection *conn)
uint32_t AFCConnectionGetContext(afc_connection conn);
uint32_t AFCConnectionSetContext(afc_connection conn, uint32_t ctx);
uint32_t AFCConnectionGetFSBlockSize(afc_connection conn);
uint32_t AFCConnectionSetFSBlockSize(afc_connection conn, uint32_t size);
uint32_t AFCConnectionGetIOTimeout(afc_connection conn);
uint32_t AFCConnectionSetIOTimeout(afc_connection conn, uint32_t timeout);
uint32_t AFCConnectionGetSocketBlockSize(afc_connection conn);
uint32_t AFCConnectionSetSocketBlockSize(afc_connection conn, uint32_t size);

CFStringRef AFCCopyErrorString(afc_connection a);
CFTypeRef AFCConnectionCopyLastErrorInfo(afc_connection a);

// 0001b8e6 T _AFCConnectionCopyLastErrorInfo
// 0001a8b6 T _AFCConnectionCreate
// 0001b8ca T _AFCConnectionGetStatus
// 0001a867 T _AFCConnectionGetTypeID
// 0001ae99 T _AFCConnectionInvalidate
// 0001b8c1 T _AFCConnectionProcessOperations
// 0001abdc T _AFCConnectionScheduleWithRunLoop
// 0001b623 T _AFCConnectionSubmitOperation
// 0001ad5a T _AFCConnectionUnscheduleFromRunLoop

// 000000000000603e T _AFCConnectionProcessOperations
// 0000000000005df8 T _AFCConnectionSetCallBack
// 00000000000064cc T _AFCConnectionSubmitOperation

// 0000000000008512 t _AFCLockCreate
// 0000000000007a83 t _AFCLockFree
// 00000000000084db t _AFCLockGetTypeID
// 0000000000007e69 t _AFCLockLock
// 00000000000083f2 t _AFCLockTryLock
// 000000000000810c t _AFCLockUnlock

const char * AFCGetClientVersionString(void);		// "@(#)PROGRAM:afc  PROJECT:afc-80"

// directory related functions
afc_error_t AFCDirectoryOpen(afc_connection conn,const char *path,afc_directory *dir);
afc_error_t AFCDirectoryRead(afc_connection conn,afc_directory dir,char **dirent);
afc_error_t AFCDirectoryClose(afc_connection conn,afc_directory dir);

afc_error_t AFCDirectoryCreate(afc_connection conn,const char *dirname);
afc_error_t AFCRemovePath(afc_connection conn,const char *dirname);
afc_error_t AFCRenamePath(afc_connection conn,const char *from,const char *to);
afc_error_t AFCLinkPath(afc_connection conn,uint64_t mode, const char *target,const char *link);
//	NSLog(@"linkpath returned %#lx",AFCLinkPath(_afc,(1=hard,2=sym)"/tmp/aaa","/tmp/bbb"));

// file i/o functions
afc_error_t AFCFileRefOpen(afc_connection conn, const char *path, uint64_t mode,afc_file_ref *ref);
afc_error_t AFCFileRefClose(afc_connection conn,afc_file_ref ref);
afc_error_t AFCFileRefSeek(afc_connection conn,	afc_file_ref ref, int64_t offset, uint64_t mode);
afc_error_t AFCFileRefTell(afc_connection conn, afc_file_ref ref, uint64_t *offset);
afc_error_t AFCFileRefRead(afc_connection conn,afc_file_ref ref,void *buf, afc_long *len);
afc_error_t AFCFileRefSetFileSize(afc_connection conn,afc_file_ref ref, afc_long offset);
afc_error_t AFCFileRefWrite(afc_connection conn,afc_file_ref ref, const void *buf, afc_long len);
afc_error_t AFCFileRefLock(afc_connection conn, afc_file_ref ref);
afc_error_t AFCFileRefUnlock(afc_connection conn, afc_file_ref ref);
// afc_error_t AFCFileRefLock(afc_connection *conn, afc_file_ref ref, ...);
// 00019747 T _AFCFileRefUnlock
// device/file information functions
afc_error_t AFCDeviceInfoOpen(afc_connection conn, afc_dictionary *info);
afc_error_t AFCFileInfoOpen(afc_connection conn, const char *path, afc_dictionary *info);
afc_error_t AFCKeyValueRead(afc_dictionary dict, const char **key, const char **val);
afc_error_t AFCKeyValueClose(afc_dictionary dict);

// Notification stuff - only call these on "com.apple.mobile.notification_proxy" (AMSVC_NOTIFICATION_PROXY)
mach_error_t AMDPostNotification(am_service socket, CFStringRef notification, CFStringRef userinfo);
mach_error_t AMDShutdownNotificationProxy(am_service socket);
mach_error_t AMDObserveNotification(am_service socket, CFStringRef notification);
typedef void (*NOTIFY_CALLBACK)(CFStringRef notification, void* data);
mach_error_t AMDListenForNotifications(am_service socket, NOTIFY_CALLBACK cb, void* data);

// New style - seems to formalise the creation of the "request packet" seperately
// from the execution.
afc_error_t AFCConnectionProcessOperation(afc_connection a1, afc_operation op, double timeout);
afc_error_t AFCOperationGetResultStatus(afc_operation op);
CFTypeRef AFCOperationGetResultObject(afc_operation op);
CFTypeID AFCOperationGetTypeID(afc_operation op);
// 0000000000002dd3 T _AFCOperationGetState
// 00000000000030c5 T _AFCOperationCopyPacketData
afc_error_t AFCOperationSetContext(afc_operation op, void *ctx);
void *AFCOperationGetContext(afc_operation op);

// each of these returns an op, with the appropriate request encoded.  The value of ctx is
// available via AFCOperationGetContext()
afc_operation AFCOperationCreateGetConnectionInfo(CFAllocatorRef allocator, void *ctx);
afc_operation AFCOperationCreateGetDeviceInfo(CFAllocatorRef allocator, void *ctx);
afc_operation AFCOperationCreateGetFileHash(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateGetFileInfo(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateLinkPath(CFAllocatorRef allocator, uint32_t mode, CFStringRef filename1, CFStringRef filename2, void *ctx);
afc_operation AFCOperationCreateMakeDirectory(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateOpenFile(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateReadDirectory(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateRemovePath(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateRenamePath(CFAllocatorRef allocator, CFStringRef oldname, CFStringRef newname, void *ctx);
afc_operation AFCOperationCreateSetConnectionOptions(CFAllocatorRef allocator, CFDictionaryRef dict, void *ctx);
afc_operation AFCOperationCreateSetModTime(CFAllocatorRef allocator, CFStringRef filename, uint64_t mtm, void *ctx);


#pragma mark -------------------------------------End --- MobileDevice.framework internals

#pragma mark --  ViewController

@interface ViewController()
{
    BOOL _subscribed;
    am_device_notification _notification;
    bool _isNeedInputPassCode,_insession,_connected;
    am_device _amDevice;
    
    
    NSString *_lasterror;
    NSString *_deviceName;
    NSString *_udid;
    NSString *_totalDiskCapacity;
    NSString *_serialNumber;
    
    NSString * _deviceClass;
    NSString * _productType;
    NSString *_productVersion;
    NSString *_totalDataAvailable;
    NSDictionary *_dataDic;
    
//    AMDevice *_deviceHandle;
    
    afc_connection _afc;
}

@end

@implementation ViewController



- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupView];
}


- (void)setupView {
    _subscribed = NO;
    _isNeedInputPassCode = NO;
    _connected = NO;
    _insession = NO;
    
    [self startListen];
}

- (void)startListen {
    if (!_subscribed) {
        // try to subscribe for notifications - pass self as the callback_data
        int ret = AMDeviceNotificationSubscribe(notify_callback, 0, 0, self, &_notification);
        if (ret == 0) {
            _subscribed = YES;
        } else {
            // we should throw or something in here...
            NSLog(@"AMDeviceNotificationSubscribe failed: %d", ret);
        }
    }
}

- (void)stopListen {
    int ret = AMDeviceNotificationUnsubscribe(_notification);
    if (ret == 0) {
        _subscribed = NO;
    } else {
        NSLog(@"AMDeviceNotificationUnsubscribe failed: %d", ret);
    }
}
/////////监听回调方法
// this is called back by AMDeviceNotificationSubscribe()
// we just punt back into a regular method//我们仅仅是把它放在一个常规的方法里进行回调
static void notify_callback(struct am_device_notification_callback_info *info, void* arg)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [(ViewController*)arg notify:info];
    [pool drain];
}

// this is (indirectly) called back by AMDeviceNotificationSubscribe()
// whenever something interesting happens//当某些有趣的事情发生的时候就会由AMDeviceNotificationSubscribe()这个方法进行（间接）回调
- (void)notify:(struct am_device_notification_callback_info *)info
{
//    AMDevice *d;
    switch (info->msg) {
        default: {
            NSLog(@"Ignoring unknown message(忽略不明消息): %d",info->msg);
            return;
        }
            
        case ADNCI_MSG_UNSUBSCRIBED: {
            return;
        }
            
        case ADNCI_MSG_CONNECTED: {
            int connectType = AMDeviceGetInterfaceType(info->dev);
            if (connectType == 1) {
                // 1:有线连接
                [self connectDevice:info->dev];
            } else if (connectType == 2) {
                
            } else {
                // 默认有线连接
            }
            break;
        }
            
        case ADNCI_MSG_DISCONNECTED: {
            int connectType = AMDeviceGetInterfaceType(info->dev);
            _amDevice = info->dev;
            if (connectType == 2) {//wifi连接设备断开
            }else {//1则为数据线连接设备断开
                [self disConnectDevice:info->dev];
            }
            break;
        }
    }
}

- (void)connectDevice:(am_device)dev {
    _amDevice = dev;
    
    
    _deviceName = [[self deviceValueForKey:@"DeviceName"] retain];
    _udid = [[self deviceValueForKey:@"UniqueDeviceID"] retain];
    _productType = [[self deviceValueForKey:@"ProductType"] retain];
    _deviceClass = [[self deviceValueForKey:@"DeviceClass"] retain];
    _productVersion = [[self deviceValueForKey:@"ProductVersion"] retain];
    _serialNumber = [[self deviceValueForKey:@"SerialNumber"] retain];
    _totalDiskCapacity = [[self deviceValueForKey:@"TotalDiskCapacity" inDomain:@"com.apple.disk_usage"] retain];
    _totalDataAvailable = [[self deviceValueForKey:@"TotalDataAvailable" inDomain:@"com.apple.disk_usage"] retain];
    _dataDic = [self deviceValueForKey:nil inDomain:@"com.apple.mobile.iTunes"];
    
    
    [ZLFileTool zl_writeDataPlsitWithDataDic:_dataDic fileName:@"iTunesData"];

}

- (void)disConnectDevice:(am_device)dev {
    _amDevice = dev;
}

#pragma mark -- 注销监听
- (void)dealloc {
    
    [self stopListen];
    
    [super dealloc];
}

#pragma mark -- Others 

- (bool)checkStatus:(int)ret from:(const char *)func
{
    if (ret != 0) {
        NSString *retStr = [NSString stringWithFormat:@"%x",ret];
        if ([@"e8000025" isEqualToString:retStr]) {
            _isNeedInputPassCode = TRUE;
        }
        return NO;
    }
    return YES;
}


- (id)deviceValueForKey:(NSString*)key
{
    return [self deviceValueForKey:key inDomain:nil];
}

- (id)deviceValueForKey:(NSString*)key inDomain:(NSString*)domain
{
    BOOL opened_connection = NO;
    BOOL opened_session = NO;
    id result = nil;
    
    // first, check for a connection
    if (!_connected) {
        if (![self deviceConnect]) goto bail;
        opened_connection = YES;
    }
    
    // one way or another, we have a connection, look for a session
    if (!_insession) {
        if (![self startSession]) goto bail;
        opened_session = YES;
    }
    
    // ok we have a session running, just query and set up to return
    result = (id)AMDeviceCopyValue(_amDevice,(CFStringRef)domain,(CFStringRef)key);
    
bail:
    if (opened_session) [self stopSession];
    if (opened_connection) [self deviceDisconnect];
    return [result autorelease];
}

#pragma mark --- deviceConnetion And deviceDisconnection
- (bool)deviceConnect
{
    if (![self checkStatus:AMDeviceConnect(_amDevice) from:"AMDeviceConnect"]) return NO;
    _connected = YES;
    return YES;
}

- (bool)startSession
{
    if ([self checkStatus:AMDeviceStartSession(_amDevice) from:"AMDeviceStartSession"]) {
        _insession = YES;
        return YES;
    }
    return NO;
}

- (bool)stopSession
{
    if ([self checkStatus:AMDeviceStopSession(_amDevice) from:"AMDeviceStopSession"]) {
        _insession = NO;
        return YES;
    }
    return NO;
}

- (bool)deviceDisconnect
{
    if ([self checkStatus:AMDeviceDisconnect(_amDevice) from:"AMDeviceDisconnect"]) {
        _connected = NO;
        return YES;
    }
    return NO;
}

#pragma mark --- 文件相关操作

- (BOOL)copyRemoteFile:(NSString*)path1 toLocalFile:(NSString*)path2
{
    // NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    BOOL result = NO;
    if ([self ensureConnectionIsOpen]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        // make sure local file doesn't exist
        if ([fm fileExistsAtPath:path2]) {
        } else {
            // open remote file for read
            AFCFileReference *in = [self openForRead:path1];
            if (in) {
                uint32_t bufsz = 10240;
                uint32_t filesize = [[[self getFileInfo:path1] valueForKey:@"st_size"] intValue];
                if (filesize>102400*5) {
                    bufsz = 102400*5;
                }else if (filesize<=102400*5&&filesize>102400){
                    bufsz = 102400*5;
                }else if (filesize<=102400){
                    bufsz = 102400;
                }
                // open local file for write - stupidly we need to create it before
                // we can make an NSFileHandle
                [fm createFileAtPath:path2 contents:nil attributes:nil];
                NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:path2];
                if (!out) {
                } else {
                    // copy all content across 10K at a time...  use
                    // malloc for the buffer rather than NSData because I've noticed
                    // strange problems in the debugger
                    //NSLog(@"after fileHandleForWritingAtPath1");
                    char *buff = (char*)malloc(bufsz);
                    uint64_t done = 0;
                    while (1) {
                        uint64_t n = [in readN:bufsz bytes:buff];
                        if (n==0) break;
                        NSData *b2 = [[NSData alloc]
                                      initWithBytesNoCopy:buff length:n freeWhenDone:NO];
                        [out writeData:b2];
                        [b2 release];
                        done += n;
                    }
                    free(buff);
                    [out closeFile];
                    result = YES;
                }
                [in closeFile];
            }
        }
    }
    return result;
}

- (AFCFileReference*)openForRead:(NSString*)path
{
    if (![self ensureConnectionIsOpen]) return nil;
    AFCFileReference *afcFile = nil;
    @synchronized(self) {
        afc_file_ref ref = 0;
        //        NSLog(@"open path:%@  socket_fd:%d  [path UTF8String]:%s  _afc:%@",path,socket_fd,[path UTF8String],_afc);
        @try {
            afc_error_t openRet = AFCFileRefOpen(_afc, [path UTF8String], 1, &ref);
            bool ret = [self checkStatus:openRet from:"AFCFileRefOpen"];
            if (ret) {
                afcFile = [[[AFCFileReference alloc] initWithPath:path reference:ref afc:_afc] autorelease];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"exception:%@",exception.reason);
        }
    }
    // if mode==0, ret=7
    // if file does not exist, ret=8
    return afcFile;
}

- (bool)ensureConnectionIsOpen
{
    if (_afc) return YES;
//    [self setLastError:@"Connection is not open"];
    return NO;
}


- (NSDictionary*)getFileInfo:(NSString*)path
{
    if (!path) {
//        [self setLastError:@"Input path is nil"];
        return nil;
    }
    
    if ([self ensureConnectionIsOpen]) {
        afc_dictionary dict;
        if ([self checkStatus:AFCFileInfoOpen(_afc, [path UTF8String], &dict) from:"AFCFileInfoOpen"]) {
            NSMutableDictionary *result = [self readAfcDictionary:dict];
            [result setObject:path forKey:@"path"];
            AFCKeyValueClose(dict);
//            [self clearLastError];
            
            // fix the ones we know are dates
            [self fix_date_entry:@"st_birthtime" in:result];
            [self fix_date_entry:@"st_mtime" in:result];
            return [NSDictionary dictionaryWithDictionary:result];
        }
    }
    return nil;
}
-(void)fix_date_entry:(NSString*)key in:(NSMutableDictionary *)dict
{
    id d = [dict objectForKey:key];
    if (d) {
        long v = [d doubleValue] / 1000000000.0;
        d = [NSDate dateWithTimeIntervalSince1970:v];
        [dict setObject:d forKey:key];
    }
}
- (NSMutableDictionary*)readAfcDictionary:(afc_dictionary)dict
{
    NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
    const char *k, *v;
    while (0 == AFCKeyValueRead(dict, &k, &v)) {
        if (!k) break;
        if (!v) break;
        
        // if all the characters in the value are digits, pass it back as
        // as 'long long' in a dictionary - else pass it back as a string
        const char *p;
        for (p=v; *p; p++) if (*p<'0' | *p>'9') break;
        if (*p) {
            /* its a string */
            [result setObject:[NSString stringWithUTF8String:v] forKey:[NSString stringWithUTF8String:k]];
        } else {
            [result setObject:[NSNumber numberWithLongLong:atoll(v)] forKey:[NSString stringWithUTF8String:k]];
        }
    }
    return result;
}
@end

#pragma mark ------ AFCFileReference

@implementation AFCFileReference

@synthesize lasterror = _lasterror;

- (void)clearLastError
{
    [_lasterror release];
    _lasterror = nil;
}

- (void)setLastError:(NSString*)msg
{
    [self clearLastError];
    _lasterror = [msg retain];
}

- (bool)checkStatus:(afc_error_t)ret from:(const char *)func
{
    if (ret != 0) {
        [self setLastError:[NSString stringWithFormat:@"%s failed: %d",func,ret]];
        return NO;
    }
    [self clearLastError];
    return YES;
}

- (bool)ensureFileIsOpen
{
    if (_ref) return YES;
    [self setLastError:@"File is not open"];
    return NO;
}

- (void)dealloc
{
    [self closeFile];
    [_lasterror release];
    [super dealloc];
}

- (id)initWithPath:(NSString*)path reference:(afc_file_ref)ref afc:(afc_connection)afc
{
    if (self=[super init]) {
        _ref = ref;
        _afc = afc;
    }
    return self;
}

- (bool)closeFile
{
    if (![self ensureFileIsOpen]) return NO;
    if (![self checkStatus:AFCFileRefClose(_afc, _ref) from:"AFCFileRefClose"]) return NO;
    _ref = 0;
    return YES;
}

- (bool)seek:(int64_t)offset mode:(int)m
{
    if (![self ensureFileIsOpen]) return NO;
    return [self checkStatus:AFCFileRefSeek(_afc, _ref, offset, m) from:"AFCFileRefSeek"];
}

- (bool)tell:(uint64_t*)offset
{
    if (![self ensureFileIsOpen]) return NO;
    return [self checkStatus:AFCFileRefTell(_afc, _ref, offset) from:"AFCFileRefTell"];
}

- (afc_long)readN:(afc_long)n bytes:(char *)buff
{
    //NSLog(@"ensureFileIsOpen before");
    if (![self ensureFileIsOpen]) return NO;
    afc_long afcSize = n;
    if (![self checkStatus:AFCFileRefRead(_afc, _ref, buff, &afcSize) from:"AFCFileRefRead"]) return 0;
    //NSLog(@"ensureFileIsOpen after afcSize");
    return afcSize;
}

- (bool)writeN:(afc_long)n bytes:(const char *)buff
{
    if (![self ensureFileIsOpen]) return NO;
    if (n>0) {
        return [self checkStatus:AFCFileRefWrite(_afc, _ref, buff, n) from:"AFCFileRefWrite"];
    }
    return YES;
}

- (bool)writeNSData:(NSData*)data
{
    return [self writeN:[data length] bytes:[data bytes]];
}

- (bool)setFileSize:(uint64_t)size
{
    if (![self ensureFileIsOpen]) return NO;
    return [self checkStatus:AFCFileRefSetFileSize(_afc, _ref, size) from:"AFCFileRefSetFileSize"];
}

- (void)lock:(int)tries {
    BOOL ret = NO;
    @try {
        for (int i = 0; i < tries; i++) {
            ret = [self checkStatus:AFCFileRefLock(_afc, _ref) from:"AFCFileRefLock"];
            if (ret == YES) {
                break;
            }
            [NSThread sleepForTimeInterval:250];
        }
    }
    @catch (NSException *exception) {
        ret = NO;
    }
}

- (void)unLock {
    BOOL ret = NO;
    @try {
        ret = [self checkStatus:AFCFileRefUnlock(_afc, _ref) from:"AFCFileRefUnlock"];
    }
    @catch (NSException *exception) {
        ret = NO;
    }
}

@end

