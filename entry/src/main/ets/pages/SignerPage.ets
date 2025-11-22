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
import { Context, common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

// 定义用户对象接口
interface userMenu {
  uname: string
  id: number
  SignPermission: number
}

// 定义图片上传需要的 Token 接口
interface CookiesTokenPUID {
  cookies: string
  Token: string
  PUID: string
}

// ---------------------------------------------------------------
// 组件 1: 用户头像图标
// 优化：增加加载占位、适配深色模式边框
// ---------------------------------------------------------------
@Reusable
@Component
struct Icon {
  @Prop UserId: number;
  @State ImageData: image.PixelMap | null = null;
  @State isLoaded: boolean = false;

  build() {
    Stack() {
      if (this.ImageData) {
        Image(this.ImageData)
          .width(48)
          .height(48)
          .borderRadius(24) // 圆形
          .objectFit(ImageFit.Cover)
          .border({ width: 1, color: $r('sys.color.ohos_id_color_separator') }) // 系统分割线颜色
      } else {
        // 加载占位图
        Circle({ width: 48, height: 48 })
          .fill($r('sys.color.ohos_id_color_component_normal')) // 系统组件默认色
      }
    }
    .margin({ right: 12 })
    .onAppear(async () => {
      try {
        const dbManager = DatabaseManager.getInstance()
        const userData = await dbManager.getUserByPosition(this.UserId, false) as UserDataAndId;
        if (userData) {
          const url = (await loginFunction.getUserInfo(userData.cookies)).pic
          this.ImageData = await loginFunction.GetPic(url) as image.PixelMap
          this.isLoaded = true;
        }
      } catch (e) {
        console.error(`[Icon] Load failed for user ${this.UserId}:`, e);
      }
    })
  }
}

// ---------------------------------------------------------------
// 组件 2: 用户列表项
// 优化：交互动画优化、使用 Checkbox 指示选中状态、适配深色模式
// ---------------------------------------------------------------
@Reusable
@Component
struct userItem {
  @State bgColor: Resource = $r('sys.color.ohos_id_color_card_bg'); // 默认卡片背景
  @Prop user: userMenu
  @Link @Watch('onSelectionChange') signIdArray: number[]

  onSelectionChange() {
    const isSelected = this.signIdArray.includes(this.user.id);
    animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
      // 选中时稍微改变背景色以示强调（可选），这里主要靠 Checkbox
      // this.bgColor = isSelected ? $r('sys.color.ohos_id_color_emphasize', 0.1) : $r('sys.color.ohos_id_color_card_bg');
    })
  }

  build() {
    Row() {
      Icon({ UserId: this.user.id })

      Column() {
        Text(this.user.uname)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))

        Text(this.user.SignPermission === 1 ? '可签到' : this.user.SignPermission === 0 ? '已签到' : '无权限')
          .fontSize(12)
          .fontColor(this.user.SignPermission === 1 ? $r('sys.color.ohos_id_color_text_secondary') : $r('sys.color.ohos_id_color_warning'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 使用 Checkbox 代替纯背景色变化，交互更明确
      Checkbox()
        .select(this.signIdArray.includes(this.user.id))
        .selectedColor($r('sys.color.ohos_id_color_connected'))
        .hitTestBehavior(HitTestMode.None) // 让点击事件穿透到 Row
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.bgColor)
    .borderRadius(12)
    .margin({ bottom: 8 })
  }
}

// ---------------------------------------------------------------
// 组件 3: 图片选择器
// 优化：UI 样式微调，逻辑保持不变
// ---------------------------------------------------------------
@Reusable
@Component
struct photoPicker {
  @State displayURI: string = ''
  @Link signIdArray: Array<number>
  @State signerInfoArr: CookiesTokenPUID[] = []
  @Link objectidArray: string[]

  build() {
    Column() {
      // 状态指示点
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.signIdArray, (signId: number, index: number) => {
          Circle({ width: 8, height: 8 })
            .fill(this.objectidArray[index] ? $r('sys.color.ohos_id_color_success') : $r('sys.color.ohos_id_color_warning'))
            .margin(4)
        })
        Circle({ width: 8, height: 8 })
          .fill(this.objectidArray[this.signIdArray.length] ? $r('sys.color.ohos_id_color_success') : $r('sys.color.ohos_id_color_warning'))
          .margin(4)
      }
      .padding(10)
      .width('100%')

      Button('选择图片 / 拍照')
        .type(ButtonType.Capsule)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        .width('60%')
        .margin({ top: 12 })
        .onClick(async () => {
          // ... (保留原有的图片选择和上传逻辑，未修改核心业务逻辑)
          this.handlePhotoSelect()
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(16)
  }

  // 抽离图片处理逻辑，保持 build 干净
  private async handlePhotoSelect() {
    this.objectidArray = []
    const dbManager = DatabaseManager.getInstance()
    const cookies = ((await dbManager.getUserByPosition(1, true)) as UserDataAndId).cookies
    const PUID = (await loginFunction.getUserInfo(cookies)).puid
    const Token = await Sign.GetToken(cookies)

    this.signerInfoArr = await Promise.all(
      this.signIdArray.map(async num => {
        let info: CookiesTokenPUID = { cookies: '', Token: '', PUID: '' }
        info.cookies = ((await dbManager.getUserByPosition(num)) as UserDataAndId).cookies
        info.PUID = (await loginFunction.getUserInfo(info.cookies)).puid
        info.Token = await Sign.GetToken(info.cookies)
        return info
      }))
    this.signerInfoArr.push({ cookies: cookies, PUID: PUID, Token: Token })

    const photoSelectOptions = new picker.PhotoSelectOptions();
    photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = this.signIdArray.length + 1;
    const photoViewPicker = new picker.PhotoViewPicker();
    const context = this.getUIContext().getHostContext() as Context

    const res = await photoViewPicker.select(photoSelectOptions)
    const uriArr = res.photoUris
    const signerNum = this.signerInfoArr.length

    for (let index = 0; index < signerNum; index++) {
      const uri = uriArr[signerNum % uriArr.length] // 逻辑维持原样
      const fileType = 'jpg'
      const fileName = ChaoxingUtils.generatePhotoName() + '.' + fileType
      const copyFilePath = context.cacheDir + '/' + fileName

      try {
        const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
        fs.copyFileSync(file.fd, copyFilePath)

        const uploadConfig: request.UploadConfig = {
          url: `https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=${this.signerInfoArr[index].Token}`,
          method: 'POST',
          header: { "Content-Type": "multipart/form-data" },
          files: [{
            filename: fileName,
            type: fileType,
            name: 'file',
            uri: `internal://cache/${fileName}`
          }],
          data: [{ name: 'puid', value: this.signerInfoArr[index].PUID.toString() }]
        }
        this.uploadPhoto(context, uploadConfig, index)
      } catch (error) {
        console.error('File processing failed', JSON.stringify(error))
      }
    }
  }

  private async uploadPhoto(context: Context, uploadConfig: request.UploadConfig, signIndex: number) {
    try {
      const task = await request.uploadFile(context, uploadConfig)
      task.on("fail", (event) => {
        promptAction.showToast({ message: '上传失败' })
      })
      task.on('headerReceive', (value) => {
        if (value && value['body']) {
          this.objectidArray[signIndex] = (JSON.parse(value['body']) as object)['objectId'] as string
        }
      })
    } catch (e) {
      console.error("Upload task creation failed", e);
    }
  }
}

// ---------------------------------------------------------------
// 全局 Builder
// ---------------------------------------------------------------

@Builder
export function initSignInfo(name: string, activityInfo: ActivityInfo) {
  SignPage({ activityInfo: activityInfo })
}

// ---------------------------------------------------------------
// 主页面: SignPage
// 优化：重构布局、使用 Scroll、layoutWeight、抽离逻辑、深色模式适配
// ---------------------------------------------------------------
@Component
export struct SignPage {
  // State Definitions
  @State canSign: boolean = true;
  @State activityInfo: null | ActivityInfo = null
  @State queryParams: object = JSON.parse('{}') as object
  @State otherUser: Array<userMenu> = []
  @State signIdArray: Array<number> = []
  @State ifPhoto: boolean = false
  @State otherUserDialogIsShow: boolean = false
  @State objectidArr: string[] = []
  @State DestinationLocationName: string = '获取中...' // 初始状态

  pathInfos: NavPathStack = new NavPathStack();

  // 1. 逻辑方法：复制文本
  private copyText(text: string) {
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制到剪贴板', duration: 1500 })
  }

  // 2. 逻辑方法：初始化数据（替代原 onAppear 中的杂乱逻辑）
  private async initPageData() {
    const dbManager = DatabaseManager.getInstance()
    // 获取当前用户信息
    const currentUser = await dbManager.getUserByPosition(1, true) as UserDataAndId;

    if (!this.activityInfo || !currentUser) return;

    const cookies = currentUser.cookies;
    this.queryParams['activeId'] = this.activityInfo.ActivityId

    // 检查是否需要拍照
    this.ifPhoto = await Sign.ifPhoto(cookies, this.activityInfo.ActivityId)

    // 如果是位置签到，获取位置信息
    if (this.activityInfo.signType === SignType.LOCATION) {
      try {
        const locName = await Sign.GetLocationSignInfo(cookies, this.activityInfo.ActivityId)
        this.DestinationLocationName = locName ? locName : '该签到无要求位置'
      } catch (e) {
        this.DestinationLocationName = '位置信息获取失败'
      }
    }

    // 加载其他可签到用户
    this.loadOtherUsers(dbManager, this.activityInfo);
  }

  private async loadOtherUsers(dbManager: DatabaseManager, actInfo: ActivityInfo) {
    const userCount = await dbManager.getTableCount('OtherUser')
    const newUserList: userMenu[] = []

    // 建议：实际开发中尽量避免循环 await，这里仅做重构保留逻辑
    for (let i: number = 1; i <= userCount; i++) {
      try {
        const userInfo = await dbManager.getUserByPosition(i)
        if (userInfo) {
          const loginInfo = await loginFunction.getUserInfo(userInfo.cookies)
          const permission = await Sign.PreSignIn(actInfo.ActivityId, actInfo.ClassId, actInfo.CourseId, loginInfo.uid, userInfo.cookies)
          newUserList.push({
            uname: loginInfo.uname,
            id: i,
            SignPermission: permission
          })
        }
      } catch (e) {
        console.error(`Failed to load user ${i}`, e)
      }
    }
    this.otherUser = newUserList;
  }

  // 3. 逻辑方法：处理签到动作
  private async handleSignAction() {
    if (this.signIdArray.length !== this.objectidArr.length - 1 && this.ifPhoto) {
      promptAction.showToast({ message: '请等待图片上传完成' })
      return
    }
    this.canSign = false
    const hashTable = new Map<string, string[]>();
    const dbManager = DatabaseManager.getInstance()

    // 主用户签到
    try {
      const info = await dbManager.getUserByPosition(1, true) as UserDataAndId
      await this.performSingleSign(info, this.objectidArr.length > 0 ? this.objectidArr[this.objectidArr.length - 1] : undefined, hashTable, true)
    } catch (e) {
      console.error('Main user sign error', e)
    }

    // 其他用户签到
    for (let i = 0; i < this.signIdArray.length; i++) {
      try {
        const otherInfo = await dbManager.getUserByPosition(this.signIdArray[i]) as UserDataAndId
        await this.performSingleSign(otherInfo, this.objectidArr[i], hashTable, false)
      } catch (e) {
        console.error(`Other user ${i} sign error`, e)
      }
    }

    this.showSignResult(hashTable);
    this.canSign = true
  }

  private async performSingleSign(userInfo: UserDataAndId, photoObjId: string | undefined, map: Map<string, string[]>, isMainUser: boolean) {
    const loginInfo = await loginFunction.getUserInfo(userInfo.cookies)

    this.queryParams['uid'] = userInfo.uid
    this.queryParams['name'] = loginInfo.uname
    this.queryParams['fid'] = loginInfo.fid
    if (this.ifPhoto && photoObjId) {
      this.queryParams['objectId'] = photoObjId
    }

    let result = await Sign.DoSignIn(userInfo.cookies, this.queryParams, isMainUser)

    if (typeof result === 'string' && (result.includes('<html') || result.includes('500 Internal Server Error'))) {
      result = '服务端错误 (500)';
    }

    if (map.has(result)) {
      map.get(result)!.push(loginInfo.uname);
    } else {
      map.set(result, [loginInfo.uname]);
    }
  }

  private showSignResult(hashTable: Map<string, string[]>) {
    let message = '';
    let isSuccess = false;

    hashTable.forEach((names, result) => {
      if (result === 'success') {
        isSuccess = true;
        message += `✅ 成功: ${names.join(', ')}\n`
      } else if (result === '您已签到过了') {
        message += `⚠️ 已签: ${names.join(', ')}\n`
      } else {
        message += `❌ ${result}: ${names.join(', ')}\n`
      }
    });

    if (message === '') message = '未进行任何签到操作';

    AlertDialog.show({
      title: '签到结果',
      message: message,
      confirm: {
        value: '确定',
        action: () => {}
      }
    })
  }


  // 4. UI Builders
  @Builder
  NavigationMenu() {
    Row() {
      Image($r('app.media.ic_contacts_addcontact')) // 建议换为 sys.symbol if API 11+
        .height(24)
        .width(24)
        .fillColor($r('sys.color.ohos_id_color_text_primary'))
        .onClick(() => {
          this.otherUserDialogIsShow = true
        })
        .bindSheet($$this.otherUserDialogIsShow, this.otherUserMenu, {
          title: { title: $r('app.string.other_user') },
          backgroundColor: $r('sys.color.ohos_id_color_dialog_bg')
        })
    }
    .margin({ right: 16 })
  }

  @Builder
  otherUserMenu() {
    List() {
      ForEach(this.otherUser, (user: userMenu) => {
        ListItem() {
          userItem({ user, signIdArray: this.signIdArray })
        }
        .onClick(() => {
          if (this.signIdArray.includes(user.id)) {
            this.signIdArray = this.signIdArray.filter(num => num !== user.id)
          } else {
            this.signIdArray.push(user.id)
          }
        })
      })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  @Builder
  LocationCard() {
    Column() {
      // 标题提示
      Text('要求位置')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      // 位置信息与复制按钮
      Row() {
        Text(this.DestinationLocationName)
          .layoutWeight(1) // ⭐️ 关键：自动占据剩余空间
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .copyOption(CopyOptions.LocalDevice)

        if (this.DestinationLocationName !== '获取中...' && this.DestinationLocationName !== '该签到无要求位置') {
          Button('复制')
            .fontSize(12)
            .height(28)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .margin({ left: 8 })
            .onClick(() => this.copyText(this.DestinationLocationName))
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
      .borderRadius(12)
      .border({ width: 1, color: $r('sys.color.ohos_id_color_separator') })

      // 已选坐标展示
      if (this.queryParams?.['address']) {
        Column() {
          Text(`已选位置: ${this.queryParams['address']}`)
            .fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary')).margin({top: 8})
          Text(`经度: ${this.queryParams['longitude']}`).fontSize(12).fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          Text(`纬度: ${this.queryParams['latitude']}`).fontSize(12).fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        }.alignItems(HorizontalAlign.Start).width('100%').margin({top: 8})
      } else {
        Text('请点击下方按钮选择位置')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_warning'))
          .margin({ top: 16, bottom: 4 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      // 地图选点按钮 (FunctionalButton)
      Column() {
        FunctionalButton({
          params: {
            openType: functionalButtonComponentManager.OpenType.CHOOSE_LOCATION,
            label: '打开地图选点',
            styleOption: {
              bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
              size: functionalButtonComponentManager.SizeType.DEFAULT,
              plain: false,
              disabled: false,
              loading: false,
              hoverClass: functionalButtonComponentManager.HoverClassType.HOVER_CLASS,
              hoverStartTime: 0,
              hoverStayTime: 0,
              styleConfig: new functionalButtonComponentManager.ButtonConfig().fontSize(16)
            },
          },
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onChooseLocation((err, data) => {
              if (err) {
                hilog.error(0x0000, "Sign", "Location Error: %{public}s", err.message);
                return;
              }
              const LoginLocation = ChaoxingUtils.gcj02_to_bd09(data.latitude, data.longitude)
              this.queryParams['address'] = data.name as string;
              this.queryParams['longitude'] = LoginLocation.lon as number;
              this.queryParams['latitude'] = LoginLocation.lat as number;
            })
        })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(16)
    .width('100%')
  }

  build() {
    NavDestination() {
      if (this.activityInfo) {
        Column() {
          // 1. 滚动内容区
          Scroll() {
            Column() {
              // 标题
              Text('签到详情')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .width('100%')
                .margin({ top: 20, bottom: 20, left: 16 })

              // 根据类型渲染不同内容
              if (this.activityInfo?.signType === SignType.NORMAL) {
                if (this.ifPhoto) {
                  photoPicker({ signIdArray: this.signIdArray, objectidArray: this.objectidArr })
                    .margin({ left: 16, right: 16 })
                } else {
                  Column() {
                    Text('点击下方按钮直接签到')
                      .fontSize(16)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }.height(100).justifyContent(FlexAlign.Center)
                }
              } else if (this.activityInfo?.signType === SignType.LOCATION) {
                this.LocationCard()
              } else {
                Text('未支持的签到类型')
                  .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                  .margin(32)
              }
            }
          }
          .layoutWeight(1) // 占据剩余高度
          .width('100%')
          .align(Alignment.Top)

          // 2. 底部按钮区 (固定)
          Column() {
            Button('立即签到')
              .width('90%')
              .height(48)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
              .enabled(this.canSign)
              .onClick(() => {
                this.handleSignAction()
              })
          }
          .width('100%')
          .padding({ top: 12, bottom: 24 }) // 底部留白
          .backgroundColor($r('sys.color.ohos_id_color_background')) // 避免内容穿透
        }
        .height('100%')
        .backgroundColor($r('sys.color.ohos_id_color_sub_background')) // 页面底色
      } else {
        Column() {
          Text('参数加载失败').fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        }.justifyContent(FlexAlign.Center).height('100%')
      }
    }
    .hideTitleBar(false)
    .title('签到', {
      backgroundColor: $r('sys.color.ohos_id_color_background'),
      mainTitleCss: { color: $r('sys.color.ohos_id_color_text_primary') }
    })
    .menus(this.NavigationMenu())
    .onReady((ctx: NavDestinationContext) => {
      this.pathInfos = ctx.pathStack;
    })
    .onAppear(() => {
      this.initPageData(); // 统一数据初始化入口
    })
  }
}
