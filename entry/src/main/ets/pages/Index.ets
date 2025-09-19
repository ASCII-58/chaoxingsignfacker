import { DatabaseManager } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import image from '@ohos.multimedia.image';
import { ClassInfo, CourseAndActivity } from '../utils/classFun';

@CustomDialog
struct QRCodeDialog {
  controller: CustomDialogController;
  @Prop value: string

  build() {
    Column() {
      if (this.value) {
        Column() {
          Column() {
            QRCode(this.value).width(240).height(240).margin({ top: 10 })
          }
          .margin(10)
          .width(260)
          .height(260)
          .backgroundColor($r('sys.color.white'))
          .borderRadius(10)
        }.margin(20).borderRadius(20).borderColor('#3388ff').borderWidth(3)
      } else {
        Column() {
          Text('未读取到用户信息')
        }
      }
      Button('关闭')
        .onClick(() => {
          this.controller.close() // 调用controller的close方法关闭弹窗
        }).margin({ bottom: 30 })
    }.backgroundColor($r('sys.color.ohos_id_color_background')).borderRadius(20)
  }
}


@Reusable
@Component
struct ClassIcon {
  @Prop imageurl: string;
  @State ImageData: image.PixelMap | null = null;

  build() {
    Column() {
      Image(this.ImageData)
        .width(50)
        .height(50)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(10)
        .margin(10)
        .onAppear(async () => {
          this.ImageData = await loginFunction.GetPic(this.imageurl)
        })
    }
  }
}


@Entry
@Component
struct UI {
  @State currentIndex: number = 0;
  @State HostImageData: image.PixelMap | Resource = $r('app.media.foreground'); // 用于存储下载的图片二进制数据
  @State hostName: Resource | string = $r('app.string.defaultUname')
  @State hostPhone: Resource | string = $r('app.string.defaultPhone')
  @State value: string = '';
  @State titleName: string = '首页'
  @State classList: ClassInfo[] | null = null
  @State QRCode: boolean = false
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  private controller: TabsController = new TabsController();
  private uiContext: UIContext = this.getUIContext();
  private QRCodeDialogController: CustomDialogController = new CustomDialogController({
    builder: QRCodeDialog({ value: this.value }),
    alignment: DialogAlignment.Center,
    customStyle: true,
    cornerRadius: 10,
    width: 300,
    height: 300,
    backgroundColor: Color.White,
  })

  @Builder
  tabBuilder(title: string, targetIndex: number) {
    Column() {
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Bold : FontWeight.Regular)
        .fontSize(this.currentIndex === targetIndex ? $r('sys.float.Caption_L') : $r('sys.float.Caption_M'))
        .onClick(() => {
          animateTo({
            duration: 100,
            curve: Curve.Ease
          }, () => {
            this.currentIndex = targetIndex;
            this.controller.changeIndex(targetIndex);
          });
        })

      if (this.currentIndex === targetIndex) {
        Divider()
          .strokeWidth(2)
          .color($r('sys.color.icon_emphasize'))
          .width(20)
          .margin({ top: 4 })
          .scale({ x: 1, y: 1 })
          .animation({
            duration: 100,
            curve: Curve.Ease,
            delay: 0,
            iterations: 1,
            playMode: PlayMode.Normal
          })
      }
    }
    .width('25%')
    .height(20)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Navigation(this.pathInfos) {
        Tabs({ controller: this.controller }) {
          //首页
          TabContent() {
            Column() {
              List({ space: 12, initialIndex: 0 }) {
                ForEach(this.classList, (classInfo: ClassInfo) => {
                  ListItem() {
                    Row() {
                      ClassIcon({ imageurl: classInfo.imageurl })
                      Column() {
                        Text(classInfo.name).fontSize(15).width('100%')
                        Text(classInfo.teacherfactor).fontSize(10).textAlign(TextAlign.Start).width('100%')
                      }.width(200)
                    }.width('100%')
                  }
                  .width('100%')
                  .backgroundColor($r('app.color.class_button'))
                  .height(70)
                  .borderRadius(20)
                  .onClick(() => {
                    this.pathInfos.pushPath({ name: 'ActivityListPage', param: classInfo });
                  })
                })
              }.height('100%')
              .width('100%')
            }.height('100%')
            .width('100%')

          }.tabBar($r('app.string.class_list'))
          .onAppear(async () => {
            // 加载课程列表
            const dbManager = DatabaseManager.getInstance()
            const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
            console.log('fuck' + cookies)
            this.classList = (await CourseAndActivity.getClassList(cookies)).classList
            this.classList.forEach(element => {
              console.log('fuck' + JSON.stringify(element))
            });
          })

          TabContent() {
            Column() {
              Column() {
                Row() {
                  Image(this.HostImageData)
                    .width(50)
                    .height(50)
                    .borderRadius(10)// 设置圆角
                    .objectFit(ImageFit.Cover)// 图片填充模式
                    .alt($r('app.media.foreground'))
                    .margin({ left: 7.5 })

                  Column() {
                    Text(this.hostName)
                      .fontSize(20)
                      .textAlign(TextAlign.Center)
                    Text(this.hostPhone)
                      .fontSize(10)
                  }
                  .margin({ left: 10 })

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
                      this.HostImageData = $r('app.media.foreground')
                      this.uiContext.getRouter().replaceUrl({ url: 'pages/LoginPage' });
                    })
                    .margin({ right: 15 })
                    .height(40)
                    .borderRadius(20)
                }
                .width('97%')
                .height(70)
                .backgroundColor($r('app.color.header_background'))
                .borderRadius({
                  topLeft: 15,
                  bottomLeft: 15,
                  bottomRight: 35,
                  topRight: 35
                })
                .padding({ left: 5, right: 5 })
                .zIndex(999999)
              }.width('100%')
              .justifyContent(FlexAlign.Start)

              Row() {
                Button() {
                  Column() {
                    Image($r('sys.media.ohos_ic_public_share'))
                      .height(40).width(40)
                  }.height(70).width(70).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                }
              }
              .onClick(() => {
                this.QRCodeDialogController.open()
              })
            }
            .height('100%')
          }.tabBar($r('app.string.user'))

        }
        .height('100%')
        .barWidth('100%')
        .barHeight(35)
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
      .title(this.titleName, { backgroundBlurStyle: BlurStyle.BACKGROUND_THICK, backgroundColor: Color.Transparent })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
    }
    .justifyContent(FlexAlign.Center)
    .backgroundImageSize({ width: '100%', height: '100%' })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .height('100%')
    .width('100%')
    .onAppear(async () => {
      try {
        const dbManager = DatabaseManager.getInstance()
        const url = await dbManager.getUserInfoById(true, 1, 'pic') as string
        this.HostImageData = await loginFunction.GetPic(url) as image.PixelMap
        this.hostName = await dbManager.getUserInfoById(true, 1, 'name') as string
        this.hostPhone = await dbManager.getUserInfoById(true, 1, 'phone') as string
        this.value =
          `http://cdn.aquamarine5.fun/?phone=${this.hostPhone}&pwd=${encodeURIComponent(await dbManager.getUserInfoById(true,1, 'pwd') as string)}&name=${decodeURIComponent(this.hostName)}`
        if (this.hostName.toString() === $r('app.string.defaultUname').toString()) {
          this.uiContext.getRouter().pushUrl({ url: 'pages/Login' });
        }
      } catch (e) {
        console.error('fuck' + e)
      }
    })
  }
}