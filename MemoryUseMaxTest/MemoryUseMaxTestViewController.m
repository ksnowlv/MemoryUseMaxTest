//
//  MemoryUseMaxTestViewController.m
//  MemoryUseMaxTest
//
//  Created by ksnowlv on 14-6-20.
//  Copyright (c) 2014年 alibaba. All rights reserved.
//

#import "MemoryUseMaxTestViewController.h"
#import "mach/mach.h"
#import <sys/types.h>
#import <sys/sysctl.h>

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}


@interface MemoryUseMaxTestViewController ()
{
    NSTimer *_timer;
    void *_pMemory[100000000];
    NSInteger _count;
}


@end

@implementation MemoryUseMaxTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    int mib[2], maxproc;
    size_t len;
    
    //the following retrieves the maximum number of processes allowed in the system:
    mib[0] = CTL_KERN;
    mib[1] = KERN_MAXPROC;
    len = sizeof(maxproc);
    sysctl(mib, 2, &maxproc, &len, NULL, 0);
    
    
    NSLog(@"maxProc number = %zu",len);
    
    //To retrieve the standard search path for the system utilities:
    char *p;
    
    mib[0] = CTL_USER;
    mib[1] = USER_CS_PATH;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    p = malloc(len);
    sysctl(mib, 2, p, &len, NULL, 0);
     NSLog(@"system utilities = %zu",len);
    free(p);
    

    size_t length;
    uint64_t physicalMemorySize = 0;
    mib[0] = CTL_HW;
    //HW_PHYSMEM
    mib[1] = HW_PHYSMEM;
    length = sizeof(int64_t);
    sysctl(mib, 2, &physicalMemorySize, &length, NULL, 0);
     NSLog(@"HW_PHYSMEM = %llu",physicalMemorySize);
    
    mib[0] = CTL_HW;
    //HW_PHYSMEM
    mib[1] = HW_PAGESIZE;
    length = sizeof(int64_t);
    sysctl(mib, 2, &physicalMemorySize, &length, NULL, 0);
    NSLog(@"HW_PAGESIZE = %llu",physicalMemorySize);//1024*16// 16384
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"------------------------memory warning");
    [self mallocMemory];
    NSLog(@"------------------------memory warningx");
}

- (IBAction)startMallocEvent:(id)sender
{
    if (_timer.isValid) {
        [_timer invalidate];
    }
   _timer =  [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(mallocMemory) userInfo:nil repeats:YES];
}

- (void)mallocMemory
{
    const CGFloat KMemoryLength = 1024.0f * 1024.0f;
    _pMemory[_count]  = malloc(KMemoryLength);
    memset(_pMemory[_count], 0, KMemoryLength);
    ++_count;
    

    //
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t error = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    long curMemorySize = 0;
    long curVirtualMemorySize = 0;
    
    if (error == KERN_SUCCESS) {
        curMemorySize = info.resident_size;
        curVirtualMemorySize = info.virtual_size;
    }
    
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    
    
    long freeMemorySize =  vm_stat.free_count * pagesize;
    
    NSLog(@"curMemorySize = %5.1fM,VirtualMemorySize = %5.1fM,freeMemorySize = %5.1fM",
          curMemorySize/KMemoryLength,
          curVirtualMemorySize/KMemoryLength,
          freeMemorySize/KMemoryLength);
    
    uint64_t physicalMemorySize = 0;
    uint64_t userMemorySize = 0;
    
    int mib[2];
    size_t length;
    mib[0] = CTL_HW;
    
    mib[1] = HW_MEMSIZE;
    length = sizeof(int64_t);
    sysctl(mib, 2, &physicalMemorySize, &length, NULL, 0);
    
    mib[1] = HW_USERMEM;
    length = sizeof(int64_t);
    sysctl(mib, 2, &userMemorySize, &length, NULL, 0);
    
    NSLog(@"physicalMemorySize = %5.1fM,userMemorySize = %5.1fM",
          physicalMemorySize/KMemoryLength,
          userMemorySize/KMemoryLength);
    
    printf("sss");
}

@end
