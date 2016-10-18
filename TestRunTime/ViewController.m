//
//  ViewController.m
//  TestRunTime
//
//  Created by ys on 16/6/13.
//  Copyright © 2016年 jzh. All rights reserved.
//

#import "ViewController.h"

#import "CustomClass.h"
#import "TestClass.h"
#include <objc/runtime.h>
#import "CustomClassOther.h"
#import "ClassMethodViewCtr.h"
#import <objc/message.h>
#import <stdio.h>

@interface ViewController ()
{
    float myFloat;
    CustomClass *allObj;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
//    allObj = [CustomClass new];
//    allObj.varTest1 = @"varTest1String";
//    allObj.varTest2 = @"varTest2String";
//    allObj.varTest3 = @"varTest3String";
//    NSString *str = [self nameOfInstance:@"varTest1String"];
//    NSLog(@"str:%@", str);
    
    [self methodSetImplementation];
    [self justLog2];
    
}

// 1、对象copy
- (void)copyObj
{
    CustomClass *obj = [CustomClass new];
    NSLog(@"%p", &obj);
    
    id objTest = object_copy(obj, sizeof(obj));
    NSLog(@"%p", &objTest);
    
    [objTest fun1];
}

// 2、对象释放
- (void)objectDispose
{
    CustomClass *obj = [CustomClass new];
    object_dispose(obj);
    
    [obj release];
    [obj fun1];
}

// 3、更改对象的类、获取对象的类
- (void)setClassTest
{
    CustomClass *obj = [CustomClass new];
    [obj fun1];
    
    Class aClass = object_setClass(obj, [CustomClassOther class]);
    NSLog(@"aClass:%@", NSStringFromClass(aClass));
    NSLog(@"objc class:%@", NSStringFromClass([obj class]));
    
    [obj fun2];
    
}

// 4、获取对象的类名
- (void)getClassName
{
    CustomClass *obj = [CustomClass new];
    NSString *className = [NSString stringWithCString:object_getClassName(obj) encoding:NSUTF8StringEncoding];
    NSLog(@"%@", className);
}

// 5、给一个类添加方法
/**
 * 一个参数
 */
int cfunction(id self, SEL _cmd, NSString *str)
{
    NSLog(@"%@", str);
    return 10;
}

- (void)oneParam
{
    TestClass *instance = [[TestClass alloc] init];
    // 方法添加
    class_addMethod([TestClass class], @selector(ocMethod:), (IMP)cfunction, "i@:@");
    
    if ([instance respondsToSelector:@selector(ocMethod:)]) {
        NSLog(@"Yes, instance respondsToSelector:@selector(ocMethod:)");
    } else {
        NSLog(@"Sorry");
    }
    
    int a = [instance ocMethod:@"我是一个OC的method，C函数实现"];
    NSLog(@"a:%d", a);
}

/**
 * 两个参数
 */
int cfunctionA(id self, SEL _cmd, NSString *str, NSString *str1)
{
    NSLog(@"%@-%@", str, str1);
    return 20;
}
- (void)twoParam
{
    TestClass *instance = [[TestClass alloc] init];
    class_addMethod([TestClass class], @selector(ocMethodA::), (IMP)cfunctionA, "i@:@@");
    
    if ([instance respondsToSelector:@selector(ocMethodA::)]) {
        NSLog(@"Yes, instance respondsToSelector:@selector(ocMethod::)");
    } else {
        NSLog(@"Sorry");
    }
    
    int a = [instance ocMethodA:@"我是一个OC的method， C函数实现" :@"----我是第二个参数"];
    NSLog(@"%d", a);
}

// 6、获取一个类的所有方法
- (void)getClassAllMethod
{
    u_int count;
    Method *methods = class_copyMethodList([UIViewController class], &count);
    for (int i = 0; i < count; i++) {
        SEL name = method_getName(methods[i]);
        NSString *strName = [NSString stringWithCString:sel_getName(name) encoding:NSUTF8StringEncoding];
        NSLog(@"%@", strName);
    }
}

// 7、获取一个类的所有属性
- (void)propertyNameList
{
    u_int count;
    objc_property_t *properties = class_copyMethodList([UIViewController class], &count);
    for (int i = 0; i < count; i++) {
        const char *propertyName = property_getName(properties[i]);
        NSString *strName = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        NSLog(@"%@", strName);
    }
}

// 8、获取、设置类的属性变量
- (void)getInstanceVar
{
    float myFloatValue;
    object_getInstanceVariable(self, "myFloat", (void *)&myFloatValue);
    NSLog(@"%f", myFloatValue);
}
- (void)setInstanceVar
{
    float newValue = 10.00f;
    unsigned int addr = (unsigned int)&newValue;
    // 有问题
    object_setInstanceVariable(self, "myFloat", *(float**)addr);
    NSLog(@"%f", myFloat);
}

// 9、判断类的某个属性的类型
- (void)getVarType
{
    CustomClass *obj = [CustomClass new];
    Ivar var = class_getInstanceVariable(object_getClass(obj), "varTest1");
    const char *typeEncoding = ivar_getTypeEncoding(var);
    NSString *stringType = [NSString stringWithCString:typeEncoding encoding:NSUTF8StringEncoding];
    if ([stringType hasPrefix:@"@"]) {
        NSLog(@"handle class case");
    } else if ([stringType hasPrefix:@"i"]) {
        NSLog(@"handle int case");
    } else if ([stringType hasPrefix:@"f"]) {
        NSLog(@"handle float case");
    } else {
        
    }
}

// 10、通过属性的值来获取其属性的名字（反射机制）
- (NSString *)nameOfInstance:(id)instance
{
    unsigned int numIvars = 0;
    NSString *key = nil;
    
    Ivar *ivars = class_copyIvarList([CustomClass class], &numIvars);
    for (int i = 0; i < numIvars; i++) {
        Ivar thisIvar = ivars[i];
        
        const char *type = ivar_getTypeEncoding(thisIvar);
        NSString *stringType = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        
        if (![stringType hasPrefix:@"@"]) {
            continue;
        }
        if (object_getIvar(allObj, thisIvar) == instance) {
            key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
            break;
        }
    }
    free(ivars);
    
    return key;
}

// 11、系统类的方法实现部分替换
- (void)methodExchange
{
    Method m1 = class_getInstanceMethod([NSString class], @selector(lowercaseString));
    Method m2 = class_getInstanceMethod([NSString class], @selector(uppercaseString));
    method_exchangeImplementations(m1, m2);
    NSLog(@"%@", [@"sssAAAAss" lowercaseString]);
    NSLog(@"%@", [@"sssAAAAss" uppercaseString]);
}

// 12、自定义类的方法实现部分替换
- (void)justLog1
{
    NSLog(@"justLog1");
}
- (void)justLog2
{
    NSLog(@"justLog2");
}
- (void)methodSetImplementation
{
    Method method = class_getInstanceMethod([ClassMethodViewCtr class], @selector(justLog1));
    IMP originalImp = method_getImplementation(method);
    Method m1 = class_getInstanceMethod([ClassMethodViewCtr class], @selector(justLog2));
    method_setImplementation(m1, originalImp);
    
}

// 13、覆盖系统方法
//IMP cFuncPointer;
//IMP cFuncPointer1;
//IMP cFuncPointer2;
//
//- (void)replaceMethod
//{
//    cFuncPointer = [NSString instanceMethodForSelector:@selector(uppercaseString)];
//    class_replaceMethod([NSString class], @selector(uppercaseString), (IMP)CustomUppercaseString, "@@:");
//    cFuncPointer1 = [NSString instanceMethodForSelector:@selector(componentsSeparatedByString:)];
//    class_replaceMethod([NSString class], @selector(componentsSeparatedByString:), (IMP)CustomComponentsSeparatedByString, "@@:@");
//    cFuncPointer2 = [NSString instanceMethodForSelector:@selector(isEqualToString:)];
//    class_replaceMethod([NSString class], @selector(isEqualToString:), (IMP)CustomIsEqualToString, "B@:@");
//    
//}
//NSString *CustomUppercaseString(id self, SEL _cmd)
//{
//    printf("真正起作用的是本函数的CustomUppercaseString\r\n");
//    NSString *string = cFuncPointer(self, _cmd); // 有问题
//    return string;
//}
//
//NSArray *CustomComponentsSeparatedByString(id self, SEL _cmd, NSString *str)
//{
//    printf("真正起作用的是本函数的CustomIsEqualToString\r\n");
//    NSString *string = cFuncPointer1(self, _cmd, str); // 有问题
//    return string;
//}
//
//bool *CustomIsEqualToString(id self, SEL _cmd, NSString *str)
//{
//    printf("真正起作用的是本函数的CustomIsEqualToString\r\n");
//    NSString *string = cFuncPointer2(self, _cmd, str); // 有问题
//    return string;
//}

// 14、自动序列化
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    Class cls = [self class];
    while (cls != [NSObject class]) {
        unsigned int numberOfIvars = 0;
        Ivar *ivars = class_copyIvarList(cls, &numberOfIvars);
        for (const Ivar *p = ivars; ivars + numberOfIvars; p++) {
            Ivar const ivar = *p;
            const char *type = ivar_getTypeEncoding(ivar);
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            id value = [self valueForKey:key];
            if (value) {
                switch (type[0]) {
                    case _C_STRUCT_B: {
                        
                        NSUInteger ivarSize = 0;
                        NSUInteger ivarAlignment = 0;
                        NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                        NSData *data = [NSData dataWithBytes:(const char *)self + ivar_getOffset(ivar) length:ivarSize];
                        [aCoder encodeObject:data forKey:key];
                        
                    }
                        break;
                        
                    default:
                        [aCoder encodeObject:value forKey:key];
                        break;
                }
            }
        }
        free(ivars);
        cls = class_getSuperclass(cls);
    }
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        Class cls = [self class];
        while (cls != [NSObject class]) {
            unsigned int numberOfIvars = 0;
            Ivar *ivars = class_copyIvarList(cls, &numberOfIvars);
            
            for (const Ivar *p = ivars; p < ivars + numberOfIvars; p++) {
                Ivar const ivar = *p;
                const char *type = ivar_getTypeEncoding(ivar);
                NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
                id value = [aDecoder decodeObjectForKey:key];
                if (value) {
                    switch (type[0]) {
                        case _C_STRUCT_B: {
                         
                            NSUInteger ivarSize = 0;
                            NSUInteger ivarAlignment = 0;
                            NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                            NSData *data = [aDecoder decodeObjectForKey:key];
                            char *sourceIvarLocation = (char *)self + ivar_getOffset(ivar);
                            [data getBytes:sourceIvarLocation length:ivarSize];
                            
                        }
                            break;
                            
                        default:
                            [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
                            break;
                    }
                }
            }
            free(ivars);
        }
    }
    
    return self;
}

// 用C代替OC：(有问题)
//extern int UIApplicationMain (int argc,char *argv[],void *principalClassName,void *delegateClassName);
//
//
//struct Rect {
//    float x;
//    float y;
//    float width;
//    float height;
//};
//typedef struct Rect Rect;
//
//
//void *navController;
//static int numberOfRows =100;
//
//
//
//int tableView_numberOfRowsInSection(void *receiver,structobjc_selector *selector, void *tblview,int section) {
//    returnnumberOfRows;
//}
//
//void *tableView_cellForRowAtIndexPath(void *receiver,structobjc_selector *selector, void *tblview,void *indexPath) {
//    Class TableViewCell = (Class)objc_getClass("UITableViewCell");
//    void *cell = class_createInstance(TableViewCell,0);
//    objc_msgSend(cell, sel_registerName("init"));
//    char buffer[7];
//    int row = (int) objc_msgSend(indexPath, sel_registerName("row"));
//    sprintf (buffer, "Row %d", row);
//    void *label =objc_msgSend(objc_getClass("NSString"),sel_registerName("stringWithUTF8String:"),buffer);
//    objc_msgSend(cell, sel_registerName("setText:"),label);
//    return cell;
//}
//
//void tableView_didSelectRowAtIndexPath(void *receiver,structobjc_selector *selector, void *tblview,void *indexPath) {
//    Class ViewController = (Class)objc_getClass("UIViewController");
//    void * vc = class_createInstance(ViewController,0);
//    objc_msgSend(vc, sel_registerName("init"));
//    char buffer[8];
//    int row = (int) objc_msgSend(indexPath, sel_registerName("row"));
//    sprintf (buffer, "Item %d", row);
//    void *label =objc_msgSend(objc_getClass("NSString"),sel_registerName("stringWithUTF8String:"),buffer);
//    objc_msgSend(vc, sel_registerName("setTitle:"),label);
//    objc_msgSend(navController,sel_registerName("pushViewController:animated:"),vc,1);
//}
//
//void *createDataSource() {
//    Class superclass = (Class)objc_getClass("NSObject");
//    Class DataSource = objc_allocateClassPair(superclass,"DataSource",0);
//    class_addMethod(DataSource,sel_registerName("tableView:numberOfRowsInSection:"), (void(*))tableView_numberOfRowsInSection,nil);
//    class_addMethod(DataSource,sel_registerName("tableView:cellForRowAtIndexPath:"), (void(*))tableView_cellForRowAtIndexPath,nil);
//    objc_registerClassPair(DataSource);
//    returnclass_createInstance(DataSource,0);
//}
//
//void * createDelegate() {
//    Class superclass = (Class)objc_getClass("NSObject");
//    Class DataSource = objc_allocateClassPair(superclass,"Delegate",0);
//    class_addMethod(DataSource,sel_registerName("tableView:didSelectRowAtIndexPath:"), (void(*))tableView_didSelectRowAtIndexPath,nil);
//    objc_registerClassPair(DataSource);
//    returnclass_createInstance(DataSource,0);
//}
//
//
//
//void applicationdidFinishLaunching(void *receiver,structobjc_selector *selector, void *application) {
//    Class windowClass = (Class)objc_getClass("UIWindow");
//    void * windowInstance = class_createInstance(windowClass, 0);
//    
//    objc_msgSend(windowInstance, sel_registerName("initWithFrame:"),(Rect){0,0,320,480});
//    
//    //Make Key and Visiable
//    objc_msgSend(windowInstance,sel_registerName("makeKeyAndVisible"));
//    
//    //Create Table View
//    Class TableViewController = (Class)objc_getClass("UITableViewController");
//    void *tableViewController = class_createInstance(TableViewController, 0);
//    objc_msgSend(tableViewController, sel_registerName("init"));
//    void *tableView = objc_msgSend(tableViewController,sel_registerName("tableView"));
//    objc_msgSend(tableView, sel_registerName("setDataSource:"),createDataSource());
//    objc_msgSend(tableView, sel_registerName("setDelegate:"),createDelegate());
//    
//    Class NavController = (Class)objc_getClass("UINavigationController");
//    navController = class_createInstance(NavController,0);
//    objc_msgSend(navController,sel_registerName("initWithRootViewController:"),tableViewController);
//    void *view =objc_msgSend(navController,sel_registerName("view"));
//    
//    //Add Table View To Window
//    objc_msgSend(windowInstance, sel_registerName("addSubview:"),view);
//}
//
//
////Create an class named "AppDelegate", and return it's name as an instance of class NSString
//void *createAppDelegate() {
//    Class mySubclass = objc_allocateClassPair((Class)objc_getClass("NSObject"),"AppDelegate",0);
//    structobjc_selector *selName =sel_registerName("application:didFinishLaunchingWithOptions:");
//    class_addMethod(mySubclass, selName, (void(*))applicationdidFinishLaunching,nil);
//    objc_registerClassPair(mySubclass);
//    returnobjc_msgSend(objc_getClass("NSString"),sel_registerName("stringWithUTF8String:"),"AppDelegate");
//}
//
//
//int main(int argc, char *argv[]) {
//    returnUIApplicationMain(argc, argv,0,createAppDelegate());
//}



@end
