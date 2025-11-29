import { ActivityInfo, SignType } from './ActivityListPage';
import { Sign } from '../utils/sign';
import { JSON } from '@kit.ArkTS';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import { ChaoxingUtils } from '../utils/utils';
import { picker } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

const TAG = 'OldSignerPage';
const DOMAIN = 0x0006;

interface userMenu {
  uname: string
  id: number
  SignPermission: number
}

@Reusable
@Component
struct Icon {
  @Prop UserId: number;
  @State ImageData: image.PixelMap | null = null;

  build() {
    Column() {
      Image(this.ImageData)
        .width(50)
        .height(50)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(40)
        .margin({ left: 5 })
        .onAppear(async () => {
          const dbManager = DatabaseManager.getInstance()
          const url =
            (await loginFunction.getUserInfo((await dbManager.getUserByPosition(this.UserId,
              false) as UserDataAndId).cookies)).pic

          this.ImageData = await loginFunction.GetPic(url) as image.PixelMap
        })
    }
  }
}

@Reusable
@Component
struct userItem {
  @State color: Resource = $r('sys.color.button_background_color_transparent')
  @Prop user: userMenu
  @Link @Watch('transformColor') signIdArray: number[]

  transformColor() {

    if (this.signIdArray.includes(this.user.id) &&
      this.color !== $r('sys.color.hds_snackbar_button_background_color')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      }, () => {
        this.color = $r('sys.color.hds_snackbar_button_background_color')
      })

    }
    if (!this.signIdArray.includes(this.user.id) &&
      this.color !== $r('sys.color.button_background_color_transparent')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      }, () => {
        this.color = $r('sys.color.button_background_color_transparent')
      })

    }
  }

  build() {
    Row() {
      Row() {
        Icon({ UserId: this.user.id })
        Row() {
          Text(this.user.uname).margin({ left: 30 }).width('20%')
        }

        Blank()
        Text(this.user.SignPermission === 1 ? '' : this.user.SignPermission === 0 ? '你已经签过到了' : '你没有签到权限')
          .width('20%').margin({ right: 30 })
      }
      .height(60)
      .width('90%')
      .borderRadius(40)
      .backgroundColor(this.color)
    }.justifyContent(FlexAlign.Center)
    .onAttach(() => {

      if (this.signIdArray.includes(this.user.id) &&
        this.color !== $r('sys.color.hds_snackbar_button_background_color')) {
        animateTo({
          duration: 300,
          curve: 'smooth'
        }, () => {
          this.color = $r('sys.color.hds_snackbar_button_background_color')
        })

      }
      if (!this.signIdArray.includes(this.user.id) &&
        this.color !== $r('sys.color.button_background_color_transparent')) {
        animateTo({
          duration: 300,
          curve: 'smooth'
        }, () => {
          this.color = $r('sys.color.button_background_color_transparent')
        })

      }
    })
  }
}

interface CookiesTokenPUID {
  cookies: string
  Token: string
  PUID: string
}

@Reusable
@Component
struct photoPicker {
  @State displayURI: string = ''
  @Link signIdArray: Array<number>
  @State signerInfoArr: CookiesTokenPUID[] = []
  @Link objectidArray: string[]

  build() {
    Column() {

      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.signIdArray, (signId: number, index: number) => {
          Column()
            .width(4)
            .height(4)
            .borderRadius(3)
            .backgroundColor(this.objectidArray[index] ? Color.Green : Color.Red)
            .margin(10)
        })
        Column()
          .width(4)
          .height(4)
          .borderRadius(3)
          .backgroundColor(this.objectidArray[this.signIdArray.length] ? Color.Green : Color.Red)
          .margin(10)
      }.padding(10)
      .width(100)

      Button('选择图片')
        .onClick(async () => {
          this.objectidArray = []
          const dbManager = DatabaseManager.getInstance()
          const cookies = ((await dbManager.getUserByPosition(1, true)) as UserDataAndId).cookies
          const PUID = (await loginFunction.getUserInfo(cookies)).puid
          const Token = await Sign.GetToken(cookies)
          this.signerInfoArr = await Promise.all(
            this.signIdArray.map(async num => {
              let info: CookiesTokenPUID = {
                cookies: '',
                Token: '',
                PUID: ''
              }
              info.cookies = ((await dbManager.getUserByPosition(num)) as UserDataAndId).cookies
              info.PUID = (await loginFunction.getUserInfo(info.cookies)).puid
              info.Token = await Sign.GetToken(info.cookies)
              return info
            }))
          this.signerInfoArr.push({ cookies: cookies, PUID: PUID, Token: Token })

          // 实例化 选项对象
          const photoSelectOptions = new picker.PhotoSelectOptions();
          // 过滤选择媒体文件类型为IMAGE
          photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
          // 选择媒体文件的最大数目
          photoSelectOptions.maxSelectNumber = this.signIdArray.length + 1;
          // 创建 图片选择对象
          const photoViewPicker = new picker.PhotoViewPicker();
          // 调用 select 方法，传入选项对象
          // const context = getContext(this)
          const context = this.getUIContext().getHostContext() as Context

          const res = await photoViewPicker.select(photoSelectOptions)

          const uriArr = res.photoUris
          const signerNum = this.signerInfoArr.length
          for (let index = 0; index < signerNum; index++) {
            const uri = uriArr[signerNum%uriArr.length]
            const fileType = 'jpg'
            // 生成一个新的文件名
            const fileName = ChaoxingUtils.generatePhotoName() + '.' + fileType
            // 通过缓存路径+文件名 拼接出完整的路径
            const copyFilePath = context.cacheDir + '/' + fileName

            // 将文件 拷贝到 临时目录
            const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
            fs.copyFileSync(file.fd, copyFilePath)

            const uploadConfig: request.UploadConfig = {
              url: `https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=${this.signerInfoArr[index].Token}`, // url 地址
              method: 'POST', // 请求方法
              header: {
                // 和接口文档的要求的格式对象
                "Content-Type": "multipart/form-data", // TODO 请求头标准写法
              },
              files: [{
                // internal://cache/ 固定的，后面跟上 咱们上一步拷贝文件名即可
                // name 和接口文档的要求对上
                filename: ChaoxingUtils.generatePhotoName() + '.' + fileType,
                type: fileType,
                name: 'file',
                uri: `internal://cache/${fileName}`
              }], // 文件信息
              data: [{
                name: 'puid',
                value: this.signerInfoArr[index].PUID.toString() /* TODO 这里是 number 类型需要转换 */
              }] // 额外提交的数据，不能省略
            }


            try { // 创建上传任务
              this.uploadPhoto(context, uploadConfig, index)
            } catch (error) {
              hilog.error(DOMAIN, TAG, `Upload photo error: ${JSON.stringify(error)}`);
            }
          }
        })
    }
    .width('100%')
    .padding({ top: 20 })
  }

  private async uploadPhoto(context: Context, uploadConfig: request.UploadConfig, signIndex: number) {
    const task = await request.uploadFile(context, uploadConfig)
    // 失败
    task.on("fail", (event) => {
      AlertDialog.show({
        message: '失败：' + JSON.stringify(event)
      })
    })
    // 这里可以获取到响应的内容
    task.on('headerReceive', (value) => {
      hilog.debug(DOMAIN, TAG, '上传结果:', JSON.stringify(value), signIndex)
      this.objectidArray[signIndex] = (JSON.parse(value['body']) as object)['objectId'] as string
      hilog.debug(DOMAIN, TAG, 'object内容', JSON.stringify(this.objectidArray));

    })
  }
}

@Builder
export function initSignInfo(name: string, activityInfo: ActivityInfo) {
  SignPage({ activityInfo: activityInfo })
}

@Component
export struct SignPage {
  @State canSign: boolean = true;
  @State activityInfo: null | ActivityInfo = null
  @State queryParams: object = JSON.parse('{}') as object
  @State otherUser: Array<userMenu> = []
  @State signIdArray: Array<number> = []
  @State IsSignForHost: boolean = true
  @State ifPhoto: boolean = false
  @State otherUserDialogIsShow: boolean = false
  @State objectidArr: string[] = []
  @State DestinationLocationName: string = '获取中'
  pathInfos: NavPathStack = new NavPathStack();

  private copyText(text: string) {
  const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
  const systemPasteboard = pasteboard.getSystemPasteboard()
  systemPasteboard.setData(pasteboardData) // 将数据放入剪切板
}
  @Builder
  NavigationMenu() {
    Column() {
      Image($r('app.media.ic_contacts_addcontact'))
        .height(30)
        .width(30)
        .onClick(() => {
          this.otherUserDialogIsShow = true
        })
        .bindSheet($$this.otherUserDialogIsShow, this.otherUserMenu, { title: { title: $r('app.string.other_user') } })
        .fillColor($r('app.color.tittle_text'))
        .margin({ right: 20 })

    }.justifyContent(FlexAlign.Center)
    .height('100%')
  }

  @Builder
  otherUserMenu() {

    List() {
      ForEach(this.otherUser, (user: userMenu) => {
        ListItem() {
          userItem({ user, signIdArray: this.signIdArray })
        }.onClick(() => {
          hilog.debug(DOMAIN, TAG, `Sign ID array: ${this.signIdArray.toString()}`);
          if (this.signIdArray.includes(user.id)) {
            hilog.debug(DOMAIN, TAG, 'Removing user from sign list');
            this.signIdArray = this.signIdArray.filter(num => num !== user.id)
          } else {
            hilog.debug(DOMAIN, TAG, 'Adding user to sign list');
            this.signIdArray.push(user.id)
          }
        })
        .width('100%')

      })
    }.width('100%')
  }

  build() {
    NavDestination() {

      if (this.activityInfo) {
        Column() {
          Stack() {
            if (this.activityInfo?.signType === SignType.NORMAL) {
              if (this.ifPhoto) {
                photoPicker({ signIdArray: this.signIdArray, objectidArray: this.objectidArr })
              } else {
                Text('这是点击签到').fontSize(20)
              }
            } else if (this.activityInfo?.signType === SignType.QRCODE) {
            } else if (this.activityInfo?.signType === SignType.LOCATION) {
              Column() {
                Column(){
                  Text('要求位置: ')
                    .fontSize(20)
                  Row(){
                    Text(this.DestinationLocationName)
                      .onAppear(async () => {
                        const dbManager = DatabaseManager.getInstance()
                        const userInfo = await dbManager.getUserByPosition(1, true)
                        const cookies = (userInfo as UserDataAndId).cookies
                        this.DestinationLocationName =
                          await Sign.GetLocationSignInfo(cookies, this.activityInfo?.ActivityId as string)
                      })
                      .width(120)
                    Button('复制')
                      .onClick(() => {
                        this.copyText(this.DestinationLocationName)
                      })
                      .height(20)
                  }

                }.borderRadius(10)
                .borderColor($r('app.color.class_button'))
                .borderWidth(2)
                Text(this.queryParams?.['address'] ? this.queryParams?.['address'] : '请先点击下方按钮选择位置')
                  .textAlign(TextAlign.Center)
                Text(this.queryParams?.['address'] ? '经度: ' + this.queryParams?.['longitude'] : '选择位置后显示')
                  .textAlign(TextAlign.Center)
                Text(this.queryParams?.['address'] ? '维度: ' + this.queryParams?.['latitude'] : '选择位置后显示')
                  .textAlign(TextAlign.Center)
                FunctionalButton({
                  params: {
                    // OpenType.CHOOSE_LOCATION表示该按钮用于在地图上选择位置。
                    openType: functionalButtonComponentManager.OpenType.CHOOSE_LOCATION,
                    label: '地图选点',
                    // 调整按钮样式。
                    styleOption: {
                      bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
                      size: functionalButtonComponentManager.SizeType.DEFAULT,
                      plain: false,
                      disabled: false,
                      loading: false,
                      hoverClass: functionalButtonComponentManager.HoverClassType.HOVER_CLASS,
                      hoverStartTime: 0,
                      hoverStayTime: 0,
                      styleConfig: new functionalButtonComponentManager.ButtonConfig()
                        .fontSize(20)
                    },
                  },
                  // 当OpenType设置为CHOOSE_LOCATION时，回调必须为onChooseLocation。
                  controller: new functionalButtonComponentManager.FunctionalButtonController()
                    .onChooseLocation((err, data) => {
                      if (err) {
                        // 错误日志处理。
                        hilog.error(DOMAIN, TAG, `Location error: ${err.code} - ${err.message}`);
                        return;
                      }
                      // 成功日志处理。
                      hilog.info(0x0000, "testTag", "succeeded in choosing location");
                      const LoginLocation = ChaoxingUtils.gcj02_to_bd09(data.latitude, data.longitude)
                      this.queryParams['address'] = data.name as string;
                      this.queryParams['longitude'] = LoginLocation.lon as number;
                      this.queryParams['latitude'] = LoginLocation.lat as number;

                    })
                })
              }
            }else {
              Text('未知签到类型')
            }
          }.height('50%')
          .width('80%')
          .align(Alignment.Center)

          Button('签到')
            .enabled(this.canSign)
            .onClick(async () => {
              if (this.signIdArray.length !== this.objectidArr.length - 1 && this.ifPhoto) {
                AlertDialog.show({ message: '请等待图片上传完成' })
                return
              }
              this.canSign = false
              const hashTable = new Map<string, string[]>();
              const dbManager = DatabaseManager.getInstance()
              const info = await dbManager.getUserByPosition(1, true) as UserDataAndId
              const userInfo = await loginFunction.getUserInfo(info.cookies)
              const uid = info.uid
              const name = userInfo.uname
              const fid = userInfo.fid
              this.queryParams['uid'] = uid
              this.queryParams['name'] = name
              this.queryParams['fid'] = fid
              if (this.ifPhoto) {
                this.queryParams['objectId'] = this.objectidArr[this.objectidArr.length - 1]
              }
              const cookies = info.cookies
              const result = await Sign.DoSignIn(cookies, this.queryParams, true)

              for (let i = 0; i < this.signIdArray.length; i++) {
                const dbManager = DatabaseManager.getInstance()
                const otherInfo = await dbManager.getUserByPosition(this.signIdArray[i]) as UserDataAndId
                const userInfo = await loginFunction.getUserInfo(otherInfo.cookies)
                const uid = userInfo.uid
                const name = userInfo.uname
                const fid = userInfo.fid
                this.queryParams['uid'] = uid
                this.queryParams['name'] = name
                this.queryParams['fid'] = fid
                if (this.ifPhoto) {
                  this.queryParams['objectId'] = this.objectidArr[i]
                }
                const cookiesOther = otherInfo.cookies
                let result = await Sign.DoSignIn(cookiesOther, this.queryParams)
                if (result.includes('500 Internal Server Error')) {
                  result = '签到不合法：服务器返回错误 (500)'
                }
                if (hashTable.has(result)) {
                  hashTable.get(result)!.push(name);
                } else {
                  hashTable.set(result, [name]);
                }
              }
              const messages: Record<string, string> = {
                "success": `用户${name}签到成功`,
                "validate": '签到需要验证码',
                '您已签到过了': `用户${name}已签到过了`
              };

              let message = '';

              // 判断是否是服务器返回的 HTML 错误页（特别是 500 错误）
              if (typeof result === 'string' &&
                (result.includes('<html') || result.includes('500 Internal Server Error'))) {
                message = '签到不合法：服务器返回错误 (500)';
              } else {
                // 正常逻辑处理 result
                message = messages[result] || `签到失败: 签到返回的结果为\n${result}`;
              }

              // 如果有其他用户的签到统计数据，追加显示
              if (hashTable.size > 0) {
                let statsMessage = '\n\n其他用户的签到统计数据:\n';
                hashTable.forEach((names, result) => {
                  statsMessage += `${result}\n${names.join(', ')} (共 ${names.length} 人)\n`;
                });

                message += statsMessage;
              }
              this.canSign = true

              // 统一弹窗提示
              AlertDialog.show({ message });

            })
        }.justifyContent(FlexAlign.Center)
        .height('100%')
        .width('100%')
      } else {
        Text('参数错误')
      }
    }
    .height('100%')
    .width('100%')
    .title('签到')
    .menus(this.NavigationMenu())
    .onReady((ctx: NavDestinationContext) => {
      // NavDestinationContext获取当前所在的导航控制器
      this.pathInfos = ctx.pathStack;
    })
    .onAppear(async () => {
      hilog.debug(DOMAIN, TAG, `Sign type: ${this.activityInfo?.signType}`);

      const dbManager = DatabaseManager.getInstance()
      const cookies = (await dbManager.getUserByPosition(1, true))?.cookies as string
      if (this.activityInfo) {
        this.ifPhoto = await Sign.ifPhoto(cookies, this.activityInfo.ActivityId)
      }
      this.queryParams['activeId'] = this.activityInfo?.ActivityId
      const userCount = await dbManager.getTableCount('OtherUser')

      // Load all users in parallel for better performance using allSettled
      const userPromises: Promise<userMenu | null>[] = []
      for (let i: number = 1; i <= userCount; i++) {
        userPromises.push(this.loadUserForOldSignerPage(dbManager, i))
      }

      const results = await Promise.allSettled(userPromises)
      // Filter out rejected or null results and update the user list
      this.otherUser = results
        .filter((result): result is PromiseFulfilledResult<userMenu> =>
          result.status === 'fulfilled' && result.value !== null)
        .map(result => result.value)
      console.log(this.ifPhoto.toString())
    })
  }

  /**
   * Load a single user for the old signer page
   */
  private async loadUserForOldSignerPage(dbManager: DatabaseManager, position: number): Promise<userMenu | null> {
    try {
      const userInfo = await dbManager.getUserByPosition(position)
      if (userInfo && this.activityInfo) {
        const info = await loginFunction.getUserInfo(userInfo.cookies)
        const SignPermission = await Sign.PreSignIn(
          this.activityInfo.ActivityId,
          this.activityInfo.ClassId,
          this.activityInfo.CourseId,
          info.uid,
          userInfo.cookies
        )
        return {
          uname: info.uname,
          id: position,
          SignPermission: SignPermission
        }
      }
      return null
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to load user ${position}`, e)
      return null
    }
  }
}