import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import image from '@ohos.multimedia.image';
import { ClassInfo, CourseAndActivity } from '../utils/classFun';
import fs from '@ohos.file.fs';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { componentSnapshot, curves, UIContext } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import promptAction from '@ohos.promptAction';
import { loginByCommon, loginByURL } from '../Component/loginCom';

@Reusable
@Component
struct ClassListItem {
  @Prop classInfo: ClassInfo;
  @Prop index: number;
  @State animOpacity: number = 0;
  @State translateY: number = 20;
  @State animScale: number = 1;
  @Consume('pathInfos') pathInfos: NavPathStack;

  build() {
    Row() {
      ClassIcon({ imageurl: this.classInfo.imageurl })
      Column() {
        Text(this.classInfo.name)
          .fontSize(16)
          .width('100%')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.classInfo.teacherfactor)
          .fontSize(12)
          .textAlign(TextAlign.Start)
          .width('100%')
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width(200)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 5, right: 15 })
    .opacity(this.animOpacity)
    .translate({ y: this.translateY })
    .scale({ x: this.animScale, y: this.animScale })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .onAppear(() => {
      animateTo({ duration: 500, curve: Curve.EaseOut, delay: 400 + (this.index * 80) }, () => {
        this.animOpacity = 1
        this.translateY = 0
      })
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.animScale = 0.97
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.animScale = 1
      }
    })
  }
}

@Reusable
@Component
struct ClassIcon {
  @Prop imageurl: string;
  @State ImageData: image.PixelMap | null = null;
  @State isLoaded: boolean = false;
  @State animOpacity: number = 0;
  @State animScale: number = 0.8;

  build() {
    Column() {
      Image(this.ImageData)
        .width(60)
        .height(60)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(15)
        .margin(10)
        .opacity(this.animOpacity)
        .scale({ x: this.animScale, y: this.animScale })
        .onAppear(async () => {
          this.ImageData = await loginFunction.GetPic(this.imageurl)
          this.isLoaded = true
          animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
            this.animOpacity = 1
            this.animScale = 1
          })
        })
    }
  }
}

@Reusable
@Component
struct OtherUserItem {
  @Prop userData: UserDataAndId;
  @Prop index: number;
  @Link otherUserList: UserDataAndId[]
  @State userImage: image.PixelMap | null = null;
  @State userName: string = ''
  @State isHovered: boolean = false;
  @State isLoaded: boolean = false;
  @State animOpacity: number = 0;
  @State translateX: number = -20;
  @State animScale: number = 1;
  private dbManger: DatabaseManager = DatabaseManager.getInstance()

  build() {
    Row() {
      Image(this.userImage)
        .width(60)
        .height(60)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(15)
        .margin(10)
      Column() {
        Text(this.userName)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.userData.phone)
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }.margin({ left: 10 })
      .width(140)
      .alignItems(HorizontalAlign.Start)

      Blank()
      Button('删除')
        .backgroundColor($r('sys.color.warning'))
        .onClick(async () => {
          let result = await this.dbManger.deleteUser(this.userData.id)
          if (result === 1) {
            this.otherUserList.splice(this.index, 1)
          }
        })
        .width(100)
        .height('100%')
        .borderRadius({
          topLeft: 0,
          topRight: 20,
          bottomLeft: 0,
          bottomRight: 20
        })

    }
    .onAppear(async () => {
      let userInfo = await loginFunction.getUserInfo(this.userData.cookies)
      this.userName = userInfo.uname
      this.userImage = await loginFunction.GetPic(userInfo.pic)
      this.isLoaded = true
      // Stagger animation based on index
      animateTo({ duration: 500, curve: Curve.EaseOut, delay: this.index * 100 }, () => {
        this.animOpacity = 1
        this.translateX = 0
      })
    })
    .height(80)
    .width('100%')
    .borderRadius(20)
    .backgroundColor($r('app.color.class_button'))
    .shadow({
      radius: 8,
      color: '#00000020',
      offsetX: 0,
      offsetY: 3
    })
    .opacity(this.animOpacity)
    .translate({ x: this.translateX })
    .scale({ x: this.animScale, y: this.animScale })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.animScale = 0.98
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.animScale = 1
      }
    })
  }
}

@Entry
@Component
struct UI {
  @State currentIndex: number = 0;
  @State HostImageData: image.PixelMap | Resource = $r('app.media.foreground'); // 用于存储下载的图片二进制数据
  @State hostName: Resource | string = $r('app.string.defaultUname')
  @State hostPhone: Resource | string = $r('app.string.defaultPhone')
  @State QRvalue: string = '';
  @State QRCode: image.PixelMap | null = null
  @State titleName: string = '首页'
  @State classList: ClassInfo[] | null = null
  @State QRCodeIsShow: boolean = false
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @State LoginCommonIsShow: boolean = false
  @State LoginURLIsSHow: boolean = false
  @State clickTime: number = 0
  @State otherUserList: UserDataAndId[] = []
  @State searchOpacity: number = 0
  @State searchScale: number = 0.9
  @State headerOpacity: number = 0
  @State headerTranslateY: number = -20
  @State qrButtonScale: number = 1
  @State selectorButtonScale: number = 1
  @State urlButtonScale: number = 1
  @State shareButtonScale: number = 1
  private controller: TabsController = new TabsController();
  private uiContext: UIContext = this.getUIContext();

  @Builder
  tabBuilder(title: string, targetIndex: number) {
    Column() {
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Bold : FontWeight.Regular)
        .fontSize(this.currentIndex === targetIndex ? $r('sys.float.Caption_L') : $r('sys.float.Caption_M'))
        .onClick(() => {
          this.currentIndex = targetIndex;
          this.controller.changeIndex(targetIndex);
        })

      if (this.currentIndex === targetIndex) {
        Divider()
          .strokeWidth(2)
          .color($r('sys.color.icon_emphasize'))
          .width(20)
          .margin({ top: 4 })
      }
    }
    .width('25%')
    .height(20)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  shareTitle() {
    Text('分享')
      .fontSize(40)
      .textAlign(TextAlign.Center)
  }

  @Builder
  QRCodeDialog() {
    Column() {
      if (this.QRvalue) {
        Column() {
          Column() {
            Column() {
              QRCode(this.QRvalue).width(240).height(240).margin({ top: 10 })
            }
            .margin(10)
            .width(260)
            .height(260)
            .backgroundColor($r('sys.color.white'))
            .borderRadius(10)
          }
          .margin(20)
          .borderRadius(20)
          .borderColor('#3388ff')
          .borderWidth(3)
          .backgroundColor('#dddddd')

          Text('用户:' + this.hostName)
            .fontSize(20)
        }.id('shareImage')
        .onAppear(async () => {
          try {
            const pixelMap: image.PixelMap = await componentSnapshot.get('shareImage')
            let buffer = new ArrayBuffer(pixelMap.getPixelBytesNumber()); // 计算所需缓冲区大小
            pixelMap.readPixelsToBuffer(buffer);
            const context = this.getUIContext().getHostContext() as Context
            const sandboxPath: string = context.filesDir + '/images/';
            const filePathName: string = sandboxPath + 'share' + encodeURIComponent(this.hostName.toString())
            const file = fs.openSync(filePathName, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
            await fs.write(file.fd, buffer);
            fs.closeSync(file);
          } catch (error) {
            console.error('fuck,图片获取失败')
          }
        })

        Button()
      } else {
        Column() {
          Text('未读取到用户信息')
            .fontSize(30)
            .margin(10)
            .width(260)
            .height(260)
            .borderRadius(10)
        }
      }
    }.margin({ top: 30 })
  }

  @Builder
  loginCommon() {
    loginByCommon({ isShow: this.LoginCommonIsShow, otherUserList: this.otherUserList }).margin({ top: 90 })
  }

  @Builder
  loginURL() {
    loginByURL({ isShow: this.LoginURLIsSHow, otherUserList: this.otherUserList }).margin({ top: 90 })
  }

  build() {
      Navigation(this.pathInfos) {
        Tabs({ controller: this.controller }) {
          TabContent() {
            Column() {

              List({ space: 12, initialIndex: 0 }) {
                ListItemGroup() {
                  ListItem() {
                    Column().height(56)
                  }

                  ListItem() {
                    Column({ space: 20 }) {
                      // [Start Search_start]
                      Search({ placeholder: '搜索课程...' })
                        .height(40)
                        .width('100%')
                        .borderRadius(20)
                        .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
                        .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
                        // set geometry transition
                        .geometryTransition('SEARCH_ONE_SHOT_DEMO_TRANSITION_ID', { follow: true })
                        .defaultFocus(false)
                        .focusOnTouch(false)
                        .focusable(false)
                        .shadow({
                          radius: 6,
                          color: '#00000020',
                          offsetX: 0,
                          offsetY: 2
                        })
                        .opacity(this.searchOpacity)
                        .scale({ x: this.searchScale, y: this.searchScale })
                        // [End Search_start]
                        .onTouch((event: TouchEvent) => {
                          if (event.type === TouchType.Up) {
                            // set search animation
                            this.showSearchPage();
                          }
                        })
                        .onAppear(() => {
                          animateTo({ duration: 500, curve: Curve.EaseOut, delay: 200 }, () => {
                            this.searchOpacity = 1
                            this.searchScale = 1
                          })
                        })
                    }
                    .size({
                      width: '90%',
                      height: '20%'
                    })
                  }
                }

                ForEach(this.classList, (classInfo: ClassInfo, index: number) => {
                  ListItem() {
                    ClassListItem({ classInfo: classInfo, index: index })
                  }
                  .width('100%')
                  .backgroundColor($r('app.color.class_button'))
                  .height(80)
                  .borderRadius(20)
                  .shadow({
                    radius: 10,
                    color: '#00000020',
                    offsetX: 0,
                    offsetY: 3
                  })
                  .onClick(() => {
                    this.pathInfos.pushPath({ name: 'ActivityListPage', param: classInfo });
                  })
                })
              }
              .height('100%')
              .width('100%')
            }.height('100%')
            .width('100%')

          }.tabBar($r('app.string.class_list'))
          .onAppear(async () => {
            // 加载课程列表
            const dbManager = DatabaseManager.getInstance()
            const cookies = (await dbManager.getUserByPosition(1, true) as UserDataAndId).cookies
            console.log('fuck' + cookies)
            this.classList = (await CourseAndActivity.getClassList(cookies)).classList
            this.classList.forEach(element => {
              console.log('fuck' + JSON.stringify(element))
            });
          })

          TabContent() {
            Column() {
              Column().height(56)
              Column() {
                Row() {
                  Image(this.HostImageData)
                    .width(50)
                    .height(50)
                    .borderRadius(90)// 设置圆角
                    .objectFit(ImageFit.Cover)// 图片填充模式
                    .alt($r('app.media.foreground'))
                    .margin({ left: 7.5 })
                    .onClick(() => {
                      if ((++this.clickTime) > 9) {
                        this.clickTime = 0
                        this.pathInfos.pushPath({ name: 'TestPage' });
                      }
                    })

                  Column() {
                    Text(this.hostName)
                      .fontSize(20)
                      .fontWeight(FontWeight.Medium)
                      .textAlign(TextAlign.Start)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.hostPhone)
                      .fontSize(12)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }
                  .margin({ left: 10 })
                  .alignItems(HorizontalAlign.Start)

                  Blank().layoutWeight(1)
                  Button('退出', { buttonStyle: ButtonStyleMode.NORMAL, role: ButtonRole.ERROR })
                    .fontSize(20)
                    .onClick(async () => {

                      const dbManager = DatabaseManager.getInstance()
                      try {
                        await dbManager.clearHostUserTable()
                      } catch (error) {
                        console.error('fuck')
                      }
                      this.hostName = $r('app.string.defaultUname')
                      this.hostPhone = $r('app.string.defaultPhone')
                      this.uiContext.getRouter().replaceUrl({ url: 'pages/LoginPage' });
                    })
                    .margin({ right: 15 })
                    .height(40)
                    .borderRadius(20)
                }
                .width('97%')
                .height(70)
                .backgroundColor($r('app.color.header_background'))
                .borderRadius(35)
                .padding({ left: 5, right: 5 })
                .zIndex(999999)
                .shadow({
                  radius: 10,
                  color: '#00000025',
                  offsetX: 0,
                  offsetY: 4
                })
                .opacity(this.headerOpacity)
                .translate({ y: this.headerTranslateY })
                .onAppear(() => {
                  animateTo({ duration: 600, curve: Curve.EaseOut, delay: 200 }, () => {
                    this.headerOpacity = 1
                    this.headerTranslateY = 0
                  })
                })
              }.width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {

                Button() {
                  Image($r('app.media.qrcode'))
                    .height(30)
                    .width(30)
                    .fillColor($r('app.color.icon'))
                    .margin(15)
                }.borderRadius(999)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.qrButtonScale, y: this.qrButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.qrButtonScale = 0.92
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.qrButtonScale = 1
                  }
                })
                .onClick(() => {
                  let options: scanBarcode.ScanOptions = {
                    scanTypes: [scanCore.ScanType.ALL],
                    enableMultiMode: true,
                    enableAlbum: true
                  };
                  try {
                    // 可调用getHostContext接口获取当前页面关联的Context
                    if (canIUse("SystemCapability.Multimedia.Scan.ScanBarcode")) {
                      scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
                        .then(async (result: scanBarcode.ScanResult) => {
                          if (canIUse("SystemCapability.Multimedia.Scan.ScanBarcode")) {
                            let loginMSG = await loginFunction.LoginByURL(result.originalValue)
                            promptAction.showToast({ message: loginMSG })
                            let dbManager = DatabaseManager.getInstance();
                            this.otherUserList = await dbManager.getAllUsers()
                          } else {
                            promptAction.showToast({ message: '权限错误' })
                          }
                          // loginFunction.LoginChaoXing()
                          // 解析码值结果跳转应用服务页
                          hilog.info(0x0001, '[Scan CPSample]',
                            `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
                        })
                        .catch((error: BusinessError) => {
                          hilog.error(0x0001, '[Scan CPSample]',
                            `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                        });
                    } else {
                      // Fallback for unsupported SystemCapability
                    }
                  } catch (error) {
                    hilog.error(0x0001, '[Scan CPSample]',
                      `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
                  }
                })

                Button() {
                  Image($r('app.media.selector'))
                    .height(30)
                    .width(30)
                    .fillColor($r('app.color.icon'))
                    .margin(15)
                }
                .onClick(() => {
                  this.LoginCommonIsShow = !this.LoginCommonIsShow
                })
                .borderRadius(999)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.selectorButtonScale, y: this.selectorButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.selectorButtonScale = 0.92
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.selectorButtonScale = 1
                  }
                })
                .bindSheet($$this.LoginCommonIsShow, this.loginCommon, {
                  height: '90%', onWillDismiss: () => {
                    this.LoginCommonIsShow = false
                  }
                })

                Button() {
                  Image($r('app.media.paperclip')).height(30)
                    .width(30)
                    .fillColor($r('app.color.icon'))
                    .margin(15)
                }
                .onClick(() => {
                  this.LoginURLIsSHow = true
                })
                .borderRadius(999)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.urlButtonScale, y: this.urlButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.urlButtonScale = 0.92
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.urlButtonScale = 1
                  }
                })
                .bindSheet($$this.LoginURLIsSHow, this.loginURL(), {
                  height: '90%', onWillDismiss: () => {
                    this.LoginURLIsSHow = false
                  }
                })

                Button() {
                  Column() {
                    Image($r('app.media.share'))
                      .height(30).width(30).fillColor($r('app.color.icon'))
                  }.height(60).width(60).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                }
                .onClick(() => {
                  this.QRCodeIsShow = true
                })
                .borderRadius(30)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.shareButtonScale, y: this.shareButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.shareButtonScale = 0.92
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.shareButtonScale = 1
                  }
                })
                .bindSheet($$this.QRCodeIsShow, this.QRCodeDialog,
                  {
                    height: '90%',
                    backgroundColor: $r('app.color.dialog'),
                    title: this.shareTitle,
                    onWillDismiss: () => {
                      this.QRCodeIsShow = false
                    }
                  })
              }.margin({ top: 15, left: '1.5%' }).justifyContent(FlexAlign.SpaceAround).width('97%')

              Column() {
                List() {
                  ForEach(this.otherUserList, (item: UserDataAndId, index) => {
                    ListItem() {
                      OtherUserItem({ userData: item, otherUserList: this.otherUserList, index: index })
                    }.width('100%')
                    .margin({ bottom: '2%' })
                  })
                }
                .margin({ top: '2%' })
                .alignListItem(ListItemAlign.Center)
                .width('96%')
                .height(300)
              }
              .margin({ top: 30 })
              .borderRadius(25)
              .backgroundColor($r('sys.color.comp_background_secondary'))
              .width('98%')
            }
            .height('100%')
          }.tabBar($r('app.string.user'))

        }
        .height('100%')
        .barWidth('100%')
        .barHeight(50)
        .vertical(false)
        .barPosition(BarPosition.End)
        .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
        .fadingEdge(true)
        .barMode(BarMode.Fixed)
        .animationDuration(0)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider') })
        .scrollable(false)
        .onChange((index) => {
          this.titleName = index === 0 ? '首页' : '用户中心'
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .mode(NavigationMode.Auto)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .title(this.titleName, {
        backgroundBlurStyle: BlurStyle.BACKGROUND_THICK, barStyle: BarStyle.STACK, backgroundBlurStyleOptions: {
          colorMode: ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.AVERAGE,
          blurOptions: { grayscale: [20, 20] },
          scale: 1
        },

      })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
    .backgroundImageSize({ width: '100%', height: '100%' })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .height('100%')
    .width('100%')
    .onAppear(async () => {
      try {
        const dbManager = DatabaseManager.getInstance()
        const HostUser =
          await loginFunction.getUserInfo((await dbManager.getUserByPosition(1, true) as UserDataAndId).cookies)
        if (HostUser.msg !== 'successful') {
          console.error('资源获取失败' + HostUser.msg)
          this.uiContext.getRouter().replaceUrl({ url: 'pages/Login' });
          return
        }
        this.otherUserList = await dbManager.getAllUsers()
        console.log(this.otherUserList.length.toString())
        let url = HostUser.pic
        this.HostImageData = await loginFunction.GetPic(url) as image.PixelMap
        this.hostName = HostUser.uname
        this.hostPhone = (await dbManager.getUserByPosition(1, true) as UserDataAndId).phone
        this.QRvalue =
          `http://cdn.aquamarine5.fun/?phone=${this.hostPhone}&pwd=${encodeURIComponent((await dbManager.getUserByPosition(1,
            true) as UserDataAndId).pwd)}&name=${decodeURIComponent(this.hostName)}`
        if (this.hostName.toString() === $r('app.string.defaultUname').toString()) {
          this.uiContext.getRouter().pushUrl({ url: 'pages/Login' });
        }
      } catch (e) {
        console.error('fuck' + e)
      }
    })


  }

  private showSearchPage(): void {
    this.pathInfos.pushPath({ name: 'SearchCoursePage' }, false);
  }
}