import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import image from '@ohos.multimedia.image';
import { ClassInfo, CourseAndActivity } from '../utils/classFun';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { curves, UIContext } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import promptAction from '@ohos.promptAction';
import { loginByCommon, loginByURL } from '../Component/loginCom';
import { OtherUserItem } from '../Component/otherUserCom';
import ShareUtils from '../utils/shareUtils';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common, Want } from '@kit.AbilityKit';
import { AnimButton } from '../Component/AnimButton';
import { SettingsComponent } from '../Component/SettingsComponent';
import { hdsEffect } from '@kit.UIDesignKit';

const TAG = 'IndexPage';
const DOMAIN = 0x0004;

@Reusable
@Component
struct ClassListItem {
  @Prop classInfo: ClassInfo;
  @Prop index: number;
  @State animScale: number = 1;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State itemOpacity: number = 0;
  @State itemTranslateY: number = 50;
  @State isPressed: boolean = false;

  aboutToAppear() {
    animateTo({
      duration: 600,
      curve: curves.springMotion(0.6, 0.8),
      delay: (this.index || 0) < 15 ? (this.index || 0) * 50 : 0
    }, () => {
      this.itemOpacity = 1;
      this.itemTranslateY = 0;
    })
  }

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
    .height(80)
    .backgroundColor($r('app.color.class_button'))
    .borderRadius(20)
    .padding({ left: 5, right: 15 })
    .scale({ x: this.animScale, y: this.animScale })
    .opacity(this.itemOpacity)
    .translate({ y: this.itemTranslateY })
    .shadow(this.isPressed ? {
      radius: 20,
      color: 'rgba(10, 89, 247, 0.3)',
      offsetX: 0,
      offsetY: 0
    } : {
      radius: 10,
      color: '#00000020',
      offsetX: 0,
      offsetY: 3
    })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.3)' })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.animScale = 0.97
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.animScale = 1
        this.isPressed = false
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

  build() {
    Column() {
      Image(this.ImageData)
        .width(60)
        .height(60)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(15)
        .margin(10)
        .alt($r('app.media.foreground'))
        .onAppear(async () => {
          if (!this.isLoaded) {
            this.ImageData = await loginFunction.GetPic(this.imageurl)
            this.isLoaded = true
          }
        })
    }
  }
}

@Entry
@Component
struct UI {
  @State UserListIsShow: boolean = false;
  @State UserListHeight: number = 0;
  @State footerHeight: number = 80;
  @State arrowAngle: number = 0;
  @State currentIndex: number = 0;
  @State HostImageData: image.PixelMap | Resource = $r('app.media.foreground'); // 用于存储下载的图片二进制数据
  @State hostName: Resource | string = $r('app.string.defaultUname')
  @State hostPhone: Resource | string = $r('app.string.defaultPhone')
  @State QRvalue: string = '';
  @State QRCode: image.PixelMap | null = null
  @State QRCodeDialogIsShow: boolean = false
  @State isSettingsOpen: boolean = false
  @State titleName: string = '首页'
  @State classList: ClassInfo[] | null = null
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @State LoginCommonIsShow: boolean = false
  @State LoginURLIsSHow: boolean = false
  @State clickTime: number = 0
  @State otherUserList: UserDataAndId[] = []
  @State shareButtonScale: number = 1
  @State settingsButtonScale: number = 1
  @State baiduButtonScale: number = 1
  @State logoutButtonScale: number = 1
  @State settingsBtnLight: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;
  @State shareBtnLight: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;
  @State logoutBtnLight: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;
  @State userHeaderOpacity: number = 0
  @State userHeaderTranslateY: number = -20
  @State buttonRowOpacity: number = 0
  @State buttonRowTranslateY: number = 20
  @State userListOpacity: number = 0
  @State userListTranslateY: number = 30
  @State userHeaderScale: number = 0.8
  @State buttonRowScale: number = 0.8
  @State userListScale: number = 0.8
  @State githubEmailOpacity: number = 1;
  private controller: TabsController = new TabsController();
  private uiContext: UIContext = this.getUIContext();
  private context: Context = this.uiContext.getHostContext() as Context;
  private openLinkContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private animationTimeoutId: number = -1;

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
  SettingsBuilder() {
    SettingsComponent({ isShow: $isSettingsOpen })
  }

  @Builder
  QRCodeDialog() {
    Column() {
      // Handle bar
      Row()
        .width(40)
        .height(5)
        .backgroundColor($r('sys.color.ohos_id_color_text_tertiary'))
        .borderRadius(2.5)
        .margin({ top: 10, bottom: 20 })

      Text('二维码名片')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 20, bottom: 20 })

      if (this.QRvalue) {
        Column() {
          Column() {
            QRCode(this.QRvalue)
              .width(200)
              .height(200)
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({ radius: 12, color: '#00000010', offsetY: 4 })

          Text(this.hostName)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 20 })
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 40 })

        Button() {
          Row() {
            Image($r('app.media.share'))
              .height(24)
              .width(24)
              .fillColor($r('sys.color.ohos_id_color_text_primary_activated'))
              .margin({ right: 8 })
            Text('分享名片')
              .fontSize(18)
              .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
              .fontWeight(FontWeight.Medium)
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .height(50)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(25)
        .shadow({ radius: 8, color: '#00000020', offsetY: 4 })
        .scale({ x: this.shareButtonScale, y: this.shareButtonScale })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.shareButtonScale = 0.96
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.shareButtonScale = 1
          }
        })
        .onClick(async () => {
          if (!this.QRvalue) {
            promptAction.showToast({ message: '请等待数据加载完成' })
            return
          }
          const shareUtils = new ShareUtils(this.context, this.QRvalue)
          await shareUtils.getQRCode()
          await shareUtils.write(true)
          this.share(shareUtils.FileUri, this.QRvalue)
        })
      } else {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
            .color($r('sys.color.ohos_id_color_text_secondary'))
          Text('正在加载用户信息...')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 20 })
        }
        .height(300)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  loginCommon() {
    loginByCommon({ isShow: this.LoginCommonIsShow, otherUserList: this.otherUserList })
  }

  @Builder
  loginURL() {
    loginByURL({ isShow: this.LoginURLIsSHow, otherUserList: this.otherUserList })
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
                      // [End Search_start]
                      .onTouch((event: TouchEvent) => {
                        if (event.type === TouchType.Up) {
                          // set search animation
                          this.showSearchPage();
                        }
                      })
                  }
                  .size({
                    width: '100%',
                    height: 40
                  })
                }
              }

              ForEach(this.classList, (classInfo: ClassInfo, index: number) => {
                ListItem() {
                  ClassListItem({ classInfo: classInfo, index: index })
                }
                .width('100%')
                .onClick(() => {
                  this.pathInfos.pushPath({ name: 'ActivityListPage', param: classInfo });
                })
              }, (classInfo: ClassInfo) => classInfo.id)
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
          hilog.debug(DOMAIN, TAG, 'Loading class list');
          this.classList = (await CourseAndActivity.getClassList(cookies)).classList
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

                Button() {
                  Column() {
                    Image($r('app.media.settings'))
                      .height(30).width(30).fillColor($r('app.color.icon'))
                  }
                  .height(45)
                  .width(45)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }
                .margin({ right: 10 })
                .onClick(() => {
                  this.isSettingsOpen = !this.isSettingsOpen
                })
                .bindSheet($$this.isSettingsOpen, this.SettingsBuilder(), {
                  height: 'auto',
                  detents: [SheetSize.MEDIUM, SheetSize.LARGE],
                  backgroundColor: $r('sys.color.ohos_id_color_sub_background'),
                  onWillDismiss: () => {
                    this.isSettingsOpen = false
                  }
                })
                .borderRadius(30)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.settingsButtonScale, y: this.settingsButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: this.settingsBtnLight,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER
                  })
                  .buildEffect())
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.settingsButtonScale = 0.92
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.settingsBtnLight = hdsEffect.PointLightSourceType.BRIGHT;
                    })
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.settingsButtonScale = 1
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.settingsBtnLight = hdsEffect.PointLightSourceType.NONE;
                    })
                  }
                })

                Button() {
                  Column() {
                    Image($r('app.media.share'))
                      .height(30).width(30).fillColor($r('app.color.icon'))
                  }
                  .height(45)
                  .width(45)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }
                .margin({ right: 10 })
                .onClick(() => {
                  this.QRCodeDialogIsShow = !this.QRCodeDialogIsShow
                })
                .bindSheet($$this.QRCodeDialogIsShow, this.QRCodeDialog, {
                  height: 'auto',
                  detents: [SheetSize.MEDIUM, SheetSize.LARGE],
                  backgroundColor: $r('sys.color.ohos_id_color_sub_background'),
                  onWillDismiss: () => {
                    this.QRCodeDialogIsShow = false
                  }
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
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: this.shareBtnLight,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER
                  })
                  .buildEffect())
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.shareButtonScale = 0.92
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.shareBtnLight = hdsEffect.PointLightSourceType.BRIGHT;
                    })
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.shareButtonScale = 1
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.shareBtnLight = hdsEffect.PointLightSourceType.NONE;
                    })
                  }
                })

                Button() {
                  Column() {
                    Image($r('app.media.ic_public_quit')).height(30).width(30).fillColor(Color.Red)
                  }.height(45).width(45).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                }
                .onClick(() => {
                  this.showLogoutDialog()
                })
                .margin({ right: 10 })
                .borderRadius(30)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .shadow({
                  radius: 8,
                  color: '#00000020',
                  offsetX: 0,
                  offsetY: 3
                })
                .scale({ x: this.logoutButtonScale, y: this.logoutButtonScale })
                .animation({ duration: 200, curve: Curve.EaseInOut })
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: this.logoutBtnLight,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER
                  })
                  .buildEffect())
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.logoutButtonScale = 0.92
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.logoutBtnLight = hdsEffect.PointLightSourceType.BRIGHT;
                    })
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.logoutButtonScale = 1
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                      this.logoutBtnLight = hdsEffect.PointLightSourceType.NONE;
                    })
                  }
                })
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
              .scale({ x: this.userHeaderScale, y: this.userHeaderScale })
              .opacity(this.userHeaderOpacity)
              .translate({ y: this.userHeaderTranslateY })
            }.width('100%')
            .justifyContent(FlexAlign.Start)

            Column() {
              Row() {

                AnimButton({
                  content: () => {
                    this.ScanButtonContent()
                  },
                  onClickAction: () => {
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
                            let loginMSG = await loginFunction.LoginByURL(result.originalValue)
                            promptAction.showToast({ message: loginMSG })
                            let dbManager = DatabaseManager.getInstance();
                            this.otherUserList = await dbManager.getAllUsers()
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
                  }
                })

                AnimButton({
                  content: () => {
                    this.SelectorButtonContent()
                  },
                  onClickAction: () => {
                    this.LoginCommonIsShow = !this.LoginCommonIsShow
                  }
                })
                  .bindSheet($$this.LoginCommonIsShow, this.loginCommon, {
                    height: 'auto',
                    detents: [SheetSize.MEDIUM, SheetSize.LARGE],
                    backgroundColor: $r('sys.color.ohos_id_color_sub_background'),
                    onWillDismiss: () => {
                      this.LoginCommonIsShow = false
                    }
                  })

                AnimButton({
                  content: () => {
                    this.UrlButtonContent()
                  },
                  onClickAction: () => {
                    this.LoginURLIsSHow = true
                  }
                })
                  .bindSheet($$this.LoginURLIsSHow, this.loginURL(), {
                    height: 'auto',
                    detents: [SheetSize.MEDIUM, SheetSize.LARGE],
                    backgroundColor: $r('sys.color.ohos_id_color_sub_background'),
                    onWillDismiss: () => {
                      this.LoginURLIsSHow = false
                    }
                  })

                AnimButton({
                  content: () => {
                    this.ArrowButtonContent()
                  },
                  onClickAction: () => {
                    animateTo({ curve: curves.springMotion(0.6, 0.8) }, () => {
                      this.UserListIsShow = !this.UserListIsShow;
                      this.arrowAngle = this.UserListIsShow ? 180 : 0;
                      this.UserListHeight = this.UserListIsShow ? 400 : 0;
                      this.footerHeight = this.UserListIsShow ? 0 : 80;
                      this.githubEmailOpacity = this.UserListIsShow ? 0 : 1;
                      this.userListOpacity = this.UserListIsShow ? 1 : 0;
                    })
                  }
                })
                  .margin({ right: 15 })

              }
              .padding({ top: 15, bottom: 15 })
              .justifyContent(FlexAlign.SpaceAround)
              .width('100%')

              Column() {
                List() {
                  ForEach(this.otherUserList, (item: UserDataAndId, index) => {
                    ListItem() {
                      OtherUserItem({ userData: item, otherUserList: this.otherUserList, index: index })
                    }.width('96%')
                    .margin({ bottom: '2%' })
                  }, (item: UserDataAndId) => item.id.toString())
                }
                .width('100%')
                .height(this.UserListHeight)
                .opacity(this.userListOpacity)
                .alignListItem(ListItemAlign.Center)

                Row() {
                  AnimButton({
                    content: () => {
                      this.GithubButtonContent()
                    },
                    onClickAction: () => {
                      this.openLinkContext.openLink('https://github.com/ASCII-58/chaoxingsignfacker')
                        .catch((error: BusinessError<void>) => {
                          hilog.error(0x0000, 'testTag', 'Execution failed, code = %{public}d, message = %{public}s',
                            error.code, error.message);
                        });
                    }
                  })
                    .margin({ right: 30 })

                  AnimButton({
                    content: () => {
                      this.EmailButtonContent()
                    },
                    onClickAction: () => {
                      let want: Want = {
                        action: 'ohos.want.action.viewData',
                        uri: 'mailto:xyxy1029@petalmail.com'
                      };
                      this.openLinkContext.startAbility(want)
                        .catch((error: BusinessError) => {
                          hilog.error(0x0000, 'testTag',
                            'Start ability failed, code = %{public}d, message = %{public}s',
                            error.code, error.message);
                        });
                    }
                  })
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')
                .height(this.footerHeight)
                .opacity(this.githubEmailOpacity)
              }
              .width('100%')
            }
            .width('97%')
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius(25)
            .margin({ top: 15 })
            .scale({ x: this.buttonRowScale, y: this.buttonRowScale })
            .opacity(this.buttonRowOpacity)
            .translate({ y: this.buttonRowTranslateY })
            .shadow({
              radius: 30,
              color: 'rgba(10, 89, 247, 0.2)',
              offsetX: 0,
              offsetY: 5
            })
            .border({ width: 1, color: 'rgba(255, 255, 255, 0.6)' })
          }.height('100%')
        }.tabBar($r('app.string.user'))
        .onAppear(() => {
          // Animate user center elements with staggered timing
          animateTo({
            duration: 500,
            curve: curves.springMotion(0.6, 0.9),
            delay: 100
          }, () => {
            this.userHeaderOpacity = 1
            this.userHeaderTranslateY = 0
            this.userHeaderScale = 1
          })

          animateTo({
            duration: 500,
            curve: curves.springMotion(0.6, 0.9),
            delay: 200
          }, () => {
            this.buttonRowOpacity = 1
            this.buttonRowTranslateY = 0
            this.buttonRowScale = 1
          })

          animateTo({
            duration: 500,
            curve: curves.springMotion(0.6, 0.9),
            delay: 300
          }, () => {
            this.userListOpacity = 1
            this.userListTranslateY = 0
            this.userListScale = 1
          })
        })

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
          hilog.error(DOMAIN, TAG, `Failed to fetch host user info: ${HostUser.msg}`);
          this.uiContext.getRouter().replaceUrl({ url: 'pages/Login' });
          return
        }
        this.otherUserList = await dbManager.getAllUsers()
        hilog.debug(DOMAIN, TAG, `Loaded ${this.otherUserList.length} other users`);
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
        hilog.error(DOMAIN, TAG, `Error in onAppear: ${e.message}`);
      }
    })

  }

  @Builder
  ScanButtonContent() {
    Image($r('app.media.qrcode'))
      .height(30)
      .width(30)
      .fillColor($r('app.color.icon'))
      .margin(15)
  }

  @Builder
  SelectorButtonContent() {
    Image($r('app.media.selector'))
      .height(30)
      .width(30)
      .fillColor($r('app.color.icon'))
      .margin(15)
  }

  @Builder
  UrlButtonContent() {
    Image($r('app.media.paperclip'))
      .height(30)
      .width(30)
      .fillColor($r('app.color.icon'))
      .margin(15)
  }

  @Builder
  ArrowButtonContent() {
    Image($r('sys.media.ohos_ic_public_arrow_down'))
      .height(30)
      .width(30)
      .fillColor($r('app.color.icon'))
      .margin(15)
      .rotate({ angle: this.arrowAngle })
      .animation({ duration: 300, curve: Curve.FastOutSlowIn })
  }

  @Builder
  GithubButtonContent() {
    Image($r('app.media.github'))
      .height(40)
      .width(40)
      .fillColor($r('app.color.icon'))
      .margin(10)
  }

  @Builder
  EmailButtonContent() {
    Image($r('app.media.envelope'))
      .height(30)
      .width(30)
      .fillColor($r('app.color.icon'))
      .margin(15)
  }

  private async share(ShareUri: string, ShareStr: string) {
    const uiContext: UIContext = this.getUIContext();

    let uri: string | undefined = undefined;
    try {
      uri = ShareUri
    } catch (error) {
      console.error(`getUriFromPath error. Code: ${error?.code}, message: ${error?.message}`);
    }

    if (!uri) {
      console.error('getUriFromPath error.');
      return;
    }

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.IMAGE,
      uri: uri,
      title: '分享二维码',
      description: '分享二维码',
      label: '二维码'
    });

    try {
      shareData.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: ShareStr,
        title: '分享url',
        description: '可通过分享的url添加账号',
        label: 'url',
      });
    } catch (error) {
      console.error(`addRecord error. Code: ${error?.code}, message: ${error?.message}`);
    }

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL,
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error?.code}, message: ${error?.message}`);
    });
  }

  private async showLogoutDialog() {
    AlertDialog.show({
      title: '退出登录',
      message: `确认退出登录吗？\n`,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '退出',
        action: async () => {
          const dbManager = DatabaseManager.getInstance()
          try {
            await dbManager.clearHostUserTable()
          } catch (error) {
            hilog.error(DOMAIN, TAG, `Failed to clear host user: ${error.message}`);
          }
          this.hostName = $r('app.string.defaultUname')
          this.hostPhone = $r('app.string.defaultPhone')
          this.uiContext.getRouter().replaceUrl({ url: 'pages/LoginPage' });
        }
      }
    })
  }

  private showSearchPage(): void {
    // 使用animateTo包裹页面跳转，实现一镜到底动画
    this.getUIContext().animateTo({
      curve: curves.interpolatingSpring(0, 1, 342, 38)
    }, () => {
      this.pathInfos.pushPath({ name: 'SearchCoursePage' }, false);
    })
  }
}
