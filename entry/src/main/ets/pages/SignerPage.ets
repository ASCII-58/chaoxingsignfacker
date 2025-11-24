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
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { GestureSignComponent } from '../Component/GestureSignComponent';
import { PasswordSignComponent } from '../Component/PasswordSignComponent';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import UrlTools from '../utils/urlTools';

const TAG = 'SignerPage';
const DOMAIN = 0x0008;

// 定义用户对象接口
interface userMenu {
  uname: string
  id: number
  SignPermission: number
}

// 定义主用户信息接口
interface HostUserInfo {
  cookies: string;
  uid: number;
  uname: string;
  fid: number;
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
          .border({ width: 1, color: $r('sys.color.comp_divider') }) // 系统分割线颜色
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
        let userData: UserDataAndId | null = null

        if (this.UserId === 0) {
          // ID=0 表示主用户，从 HostUser 表获取
          userData = await dbManager.getUserByPosition(1, true) as UserDataAndId;
        } else {
          // 其他用户从 OtherUser 表获取
          userData = await dbManager.getUserByPosition(this.UserId, false) as UserDataAndId;
        }

        if (userData) {
          const url = (await loginFunction.getUserInfo(userData.cookies)).pic
          this.ImageData = await loginFunction.GetPic(url) as image.PixelMap
          this.isLoaded = true;
        }
      } catch (e) {
        hilog.error(DOMAIN, TAG, `[Icon] Load failed for user ${this.UserId}:`, e);
      }
    })
  }
}

// ---------------------------------------------------------------
// 组件 2: 用户列表项
// 优化：遵循华为"一镜到底"设计原则
// - 增强视觉层次和信息密度
// - 添加流畅的交互动画
// - 改进选中状态的视觉反馈
// - 优化深色模式适配
// ---------------------------------------------------------------
@Reusable
@Component
struct userItem {
  @Prop user: userMenu
  @Link @Watch('onSelectionChange') signIdArray: number[]
  @State isSelected: boolean = false
  @State scaleValue: number = 1
  @State opacityValue: number = 1

  onSelectionChange() {
    this.isSelected = this.signIdArray.includes(this.user.id);
  }

  aboutToAppear() {
    this.isSelected = this.signIdArray.includes(this.user.id);
  }

  build() {
    Row() {
      // 头像容器 - 添加选中动画
      Stack() {
        Icon({ UserId: this.user.id })
        
        // 选中状态指示器
        if (this.isSelected) {
          Circle({ width: 16, height: 16 })
            .fill($r('sys.color.ohos_id_color_connected'))
            .position({ x: 36, y: 36 })
          
          Image($r('sys.media.ohos_ic_public_ok'))
            .width(12)
            .height(12)
            .fillColor($r('sys.color.ohos_id_color_primary_contrary'))
            .position({ x: 38, y: 38 })
        }
      }
      .width(48)
      .height(48)
      .margin({ right: 16 })

      // 用户信息区域
      Column({ space: 4 }) {
        Row() {
          Text(this.user.uname)
            .fontSize(16)
            .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')

        // 状态标签
        Row() {
          Text(this.getStatusText())
            .fontSize(12)
            .fontColor(this.getStatusColor())
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(this.getStatusBgColor())
            .borderRadius(4)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选择指示器 - 使用更现代的设计
      if (this.user.SignPermission !== -1) {
        Stack() {
          Circle({ width: 24, height: 24 })
            .fill(this.isSelected ? $r('sys.color.ohos_id_color_connected') : Color.Transparent)
            .border({
              width: 2,
              color: this.isSelected ? $r('sys.color.ohos_id_color_connected') :
                $r('sys.color.ohos_id_color_fourth')
            })
          
          if (this.isSelected) {
            Image($r('sys.media.ohos_ic_public_ok'))
              .width(14)
              .height(14)
              .fillColor($r('sys.color.ohos_id_color_primary_contrary'))
          }
        }
        .margin({ left: 12 })
      } else {
        // 无权限用户显示禁用图标
        Image($r('sys.media.ohos_ic_public_remove'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.ohos_id_color_warning'))
          .margin({ left: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isSelected ? 
      $r('sys.color.ohos_id_color_emphasize', 0.08) : 
      $r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(16)
    .margin({ bottom: 12 })
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? $r('sys.color.ohos_id_color_connected') : $r('sys.color.comp_divider')
    })
    .shadow({
      radius: this.isSelected ? 12 : 4,
      color: this.isSelected ? $r('sys.color.ohos_id_color_connected', 0.2) : $r('sys.color.ohos_id_color_fourth', 0.1),
      offsetX: 0,
      offsetY: this.isSelected ? 4 : 2
    })
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .opacity(this.opacityValue)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut,
      iterations: 1
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.scaleValue = 0.98
        this.opacityValue = 0.8
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.scaleValue = 1
        this.opacityValue = 1
      }
    })
  }

  private getStatusText(): string {
    switch (this.user.SignPermission) {
      case 1:
        return '可签到';
      case 0:
        return '已签到';
      default:
        return '无权限';
    }
  }

  private getStatusColor(): Resource {
    switch (this.user.SignPermission) {
      case 1:
        return $r('sys.color.ohos_id_color_connected');
      case 0:
        return $r('sys.color.ohos_id_color_text_secondary');
      default:
        return $r('sys.color.ohos_id_color_warning');
    }
  }

  private getStatusBgColor(): Resource {
    switch (this.user.SignPermission) {
      case 1:
        return $r('sys.color.ohos_id_color_connected', 0.1);
      case 0:
        return $r('sys.color.ohos_id_color_fourth', 0.3);
      default:
        return $r('sys.color.ohos_id_color_warning', 0.1);
    }
  }
}

// ---------------------------------------------------------------
// 组件 3: 图片选择器
// 优化：遵循"一镜到底"设计，改进 UI 样式和用户反馈
// ---------------------------------------------------------------
@Reusable
@Component
struct photoPicker {
  @State displayURI: string = ''
  @Link signIdArray: Array<number>
  @State signerInfoArr: CookiesTokenPUID[] = []
  @Link objectidArray: string[]
  @Link otherUserDialogIsShow: boolean // 添加控制用户选择对话框的链接
  @Prop otherUser: Array<userMenu> // 添加其他用户列表
  @State uploadStatus: string = '' // 上传状态反馈
  @State isUploading: boolean = false // 是否正在上传
  @State uploadCompletedCount: number = 0 // 已完成上传的数量（成功或失败）
  @State uploadTotalCount: number = 0 // 总上传数量

  build() {
    Column({ space: 16 }) {
      // 标题
      Row() {
        Image($r('sys.media.ohos_ic_public_photo'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.ohos_id_color_emphasize'))
          .margin({ right: 8 })
        
        Text('拍照签到')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
      }
      .width('100%')

      // 状态指示区域 - 改进可视化
      Column({ space: 12 }) {
        Row() {
          Text('上传进度')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          
          Blank()
          
          Text(`${this.objectidArray.filter(id => id).length}/${this.signIdArray.length}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_emphasize'))
        }
        .width('100%')

        // 进度指示器
        Row({ space: 8 }) {
          ForEach(this.signIdArray, (signId: number, index: number) => {
            Stack() {
              Circle({ width: 32, height: 32 })
                .fill(this.objectidArray[index] ? 
                  $r('sys.color.ohos_id_color_connected', 0.2) : 
                  $r('sys.color.ohos_id_color_fourth', 0.3))
                .border({
                  width: 2,
                  color: this.objectidArray[index] ? 
                    $r('sys.color.ohos_id_color_connected') : 
                    $r('sys.color.ohos_id_color_fourth')
                })
              
              if (this.objectidArray[index]) {
                Image($r('sys.media.ohos_ic_public_ok'))
                  .width(16)
                  .height(16)
                  .fillColor($r('sys.color.ohos_id_color_connected'))
              } else {
                Text(`${index + 1}`)
                  .fontSize(12)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              }
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('sys.color.ohos_id_color_background'))
      .borderRadius(12)

      // 状态文本反馈
      if (this.uploadStatus) {
        Row() {
          if (this.isUploading) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color($r('sys.color.ohos_id_color_emphasize'))
              .margin({ right: 8 })
          }
          
          Text(this.uploadStatus)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 选择图片按钮
      Button({ type: ButtonType.Normal }) {
        Row({ space: 8 }) {
          Image($r('sys.media.ohos_ic_public_photo'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.ohos_id_color_text_primary_activated'))
          
          Text('选择图片 / 拍照')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(this.isUploading ? 
        $r('sys.color.ohos_id_color_fourth') : 
        $r('sys.color.ohos_id_color_emphasize'))
      .borderRadius(24)
      .enabled(!this.isUploading)
      .shadow({
        radius: 12,
        color: this.isUploading ? 
          $r('sys.color.ohos_id_color_fourth', 0.1) : 
          $r('sys.color.ohos_id_color_emphasize', 0.3),
        offsetX: 0,
        offsetY: 4
      })
      .onClick(async () => {
        this.showPhotoConfirmDialog()
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: $r('sys.color.ohos_id_color_fourth', 0.1),
      offsetX: 0,
      offsetY: 2
    })
  }

  // 显示图片选择确认对话框
  private showPhotoConfirmDialog() {
    if (this.signIdArray.length === 0) {
      AlertDialog.show({
        title: '提示',
        message: '请先选择至少一个用户',
        confirm: {
          value: '知道了',
          action: () => {
            this.otherUserDialogIsShow = true
          }
        }
      })
      return
    }

    const selectedUsers = this.otherUser.filter(u => this.signIdArray.includes(u.id));
    const userNames = selectedUsers.map(u => u.uname).join('、');

    AlertDialog.show({
      title: '确认上传图片',
      message: `将为以下用户上传图片：\n${userNames}\n\n是否继续？`,
      primaryButton: {
        value: '修改用户',
        action: () => {
          this.otherUserDialogIsShow = true
        }
      },
      secondaryButton: {
        value: '确认上传',
        action: () => {
          this.handlePhotoSelect()
        }
      }
    })
  }

  // 抽离图片处理逻辑，保持 build 干净
  private async handlePhotoSelect() {
    this.objectidArray = []
    this.uploadCompletedCount = 0
    this.uploadStatus = '正在准备上传...'
    this.isUploading = true
    const dbManager = DatabaseManager.getInstance()

    try {
      this.signerInfoArr = await Promise.all(
        this.signIdArray.map(async userId => {
          let info: CookiesTokenPUID = { cookies: '', Token: '', PUID: '' }

          if (userId === 0) {
            // 主用户
            info.cookies = ((await dbManager.getUserByPosition(1, true)) as UserDataAndId).cookies
          } else {
            // 其他用户
            info.cookies = ((await dbManager.getUserByPosition(userId)) as UserDataAndId).cookies
          }

          info.PUID = (await loginFunction.getUserInfo(info.cookies)).puid
          info.Token = await Sign.GetToken(info.cookies)
          return info
        }))

      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = this.signIdArray.length;
      const photoViewPicker = new picker.PhotoViewPicker();
      const context = this.getUIContext().getHostContext() as Context

      const res = await photoViewPicker.select(photoSelectOptions)
      const uriArr = res.photoUris
      const signerNum = this.signerInfoArr.length
      this.uploadTotalCount = signerNum

      this.uploadStatus = `正在上传图片 (0/${signerNum})`
      promptAction.showToast({ message: '开始上传图片', duration: 1500 })

      for (let index = 0; index < signerNum; index++) {
        const uri = uriArr[index % uriArr.length]
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
          // 不使用await，允许并行上传
          this.uploadPhoto(context, uploadConfig, index)
        } catch (error) {
          hilog.error(DOMAIN, TAG, 'File processing failed', JSON.stringify(error))
          promptAction.showToast({ message: `图片 ${index + 1} 处理失败`, duration: 2000 })
          this.uploadCompletedCount++
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Photo selection failed', JSON.stringify(error))
      this.uploadStatus = '图片选择失败'
      this.isUploading = false
      promptAction.showToast({ message: '图片选择失败', duration: 2000 })
    }
  }

  private async uploadPhoto(context: Context, uploadConfig: request.UploadConfig, signIndex: number) {
    try {
      const task = await request.uploadFile(context, uploadConfig)

      task.on("fail", (event) => {
        hilog.error(DOMAIN, TAG, `Upload failed for index ${signIndex}`, JSON.stringify(event))
        promptAction.showToast({ message: `图片 ${signIndex + 1} 上传失败`, duration: 2000 })

        // 更新完成计数
        this.uploadCompletedCount++
        const uploadedCount = this.objectidArray.filter(id => id).length
        this.uploadStatus = `上传失败 (${uploadedCount}/${this.uploadTotalCount})`

        // 检查是否所有上传都已完成
        if (this.uploadCompletedCount >= this.uploadTotalCount) {
          this.isUploading = false
          if (uploadedCount === 0) {
            this.uploadStatus = '所有图片上传失败'
          }
        }
      })

      task.on('complete', () => {
        // 更新完成计数
        this.uploadCompletedCount++
        const uploadedCount = this.objectidArray.filter(id => id).length
        this.uploadStatus = `已上传 ${uploadedCount}/${this.uploadTotalCount}`

        // 检查是否所有上传都已完成
        if (this.uploadCompletedCount >= this.uploadTotalCount) {
          this.isUploading = false
          if (uploadedCount === this.uploadTotalCount) {
            this.uploadStatus = '所有图片上传完成 ✓'
            promptAction.showToast({ message: '所有图片上传成功', duration: 2000 })
          }
        }
      })

      task.on('headerReceive', (value) => {
        if (value && value['body']) {
          try {
            const bodyObj = JSON.parse(value['body']) as object
            this.objectidArray[signIndex] = bodyObj['objectId'] as string

            // 更新上传状态
            const uploadedCount = this.objectidArray.filter(id => id).length
            this.uploadStatus = `已上传 ${uploadedCount}/${this.uploadTotalCount}`

            console.info(`Photo ${signIndex + 1} uploaded successfully`)
          } catch (e) {
            hilog.error(DOMAIN, TAG, 'Failed to parse upload response', e)
          }
        }
      })
    } catch (e) {
      hilog.error(DOMAIN, TAG, "Upload task creation failed", e)
      promptAction.showToast({ message: `图片 ${signIndex + 1} 上传失败`, duration: 2000 })

      // 更新完成计数
      this.uploadCompletedCount++
      const uploadedCount = this.objectidArray.filter(id => id).length
      this.uploadStatus = `上传失败 (${uploadedCount}/${this.uploadTotalCount})`

      // 检查是否所有上传都已完成
      if (this.uploadCompletedCount >= this.uploadTotalCount) {
        this.isUploading = false
      }
    }
  }
}

@Reusable
@Component
struct QRCodeLocation {
  @Prop ActivityId: string;
  @Link queryParams: object
  @State DestinationLocationName: string = '获取中...' // 初始状态
  @State Position: object = JSON.parse('{"result":1,"mockData":"{\\"strategy\\":0,\\"probability\\":-1}"}') as object

  build() {
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
      .onAttach(async () => {

        const dbManager = DatabaseManager.getInstance()
        // 获取当前用户信息
        const currentUser = await dbManager.getUserByPosition(1, true) as UserDataAndId;

        const cookies = currentUser.cookies;
        try {
          const locName =
            (await Sign.GetLocationSignInfo(cookies, this.ActivityId))['locationText'] as string
          this.DestinationLocationName = locName ? locName : '该签到无要求位置'
        } catch (e) {
          this.DestinationLocationName = '位置信息获取失败'
        }
      })
      .width('100%')
      .padding(12)
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
      .borderRadius(12)
      .border({ width: 1, color: $r('sys.color.comp_divider') })

      // 已选坐标展示
      if (this.Position?.['address']) {
        Column() {
          Text(`已选位置: ${this.Position['address']}`)
            .fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary')).margin({ top: 8 })
          Text(`经度: ${this.Position['longitude']}`)
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          Text(`纬度: ${this.Position['latitude']}`)
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        }.alignItems(HorizontalAlign.Start).width('100%').margin({ top: 8 })
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
              this.Position['address'] = data.name as string;
              this.Position['longitude'] = LoginLocation.lon as number;
              this.Position['latitude'] = LoginLocation.lat as number;
              this.queryParams['location'] = JSON.stringify(this.Position)
            })
        }).enabled(this.DestinationLocationName !== '获取中...' && this.DestinationLocationName !== '该签到无要求位置')
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(16)
    .width('100%')
  }

  // 1. 逻辑方法：复制文本
  private copyText(text: string) {
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制到剪贴板', duration: 1500 })
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
  @State hostUser: HostUserInfo | null = null
  pathInfos: NavPathStack = new NavPathStack();

  // 4. UI Builders
  @Builder
  otherUserMenu() {
    Column() {
      // 顶部统计信息区域 - 一镜到底设计：提供清晰的信息层次
      Row() {
        Column({ space: 4 }) {
          Text('用户选择')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          
          Text(`共 ${this.otherUser.length} 人 · 已选 ${this.signIdArray.length} 人`)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 快速操作按钮
        Row({ space: 8 }) {
          Button('全选')
            .fontSize(14)
            .height(32)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .onClick(() => {
              // 选择所有有权限的用户
              this.signIdArray = this.otherUser
                .filter(u => u.SignPermission !== -1)
                .map(u => u.id)
            })
          
          Button('清空')
            .fontSize(14)
            .height(32)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .onClick(() => {
              this.signIdArray = []
            })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('sys.color.ohos_id_color_background'))

      // 用户列表区域
      List({ space: 0 }) {
        // 添加分组提示
        ListItemGroup() {
          if (this.otherUser.filter(u => u.SignPermission === 1).length > 0) {
            ListItem() {
              Row() {
                Text('可签到用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ left: 4 })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }
          }
          
          ForEach(this.otherUser.filter((u: userMenu) => u.SignPermission === 1), (user: userMenu) => {
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

        ListItemGroup() {
          if (this.otherUser.filter(u => u.SignPermission === 0).length > 0) {
            ListItem() {
              Row() {
                Text('已签到用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ left: 4 })
              }
              .width('100%')
              .padding({ top: 16, bottom: 8 })
            }
          }
          
          ForEach(this.otherUser.filter((u: userMenu) => u.SignPermission === 0), (user: userMenu) => {
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

        ListItemGroup() {
          if (this.otherUser.filter(u => u.SignPermission === -1).length > 0) {
            ListItem() {
              Row() {
                Text('无权限用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ left: 4 })
              }
              .width('100%')
              .padding({ top: 16, bottom: 8 })
            }
          }
          
          ForEach(this.otherUser.filter((u: userMenu) => u.SignPermission === -1), (user: userMenu) => {
            ListItem() {
              userItem({ user, signIdArray: this.signIdArray })
            }
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, bottom: 16 })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .divider({
        strokeWidth: 0
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  @Builder
  UserSelectionCard() {
    Column({ space: 12 }) {
      // 标题和操作按钮区域
      Row() {
        Column({ space: 4 }) {
          Text('已选用户')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          
          if (this.signIdArray.length > 0) {
            Text(`${this.signIdArray.length} 人已选择`)
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button({ type: ButtonType.Normal }) {
          Row({ space: 6 }) {
            Image($r('sys.media.ohos_ic_public_add'))
              .width(16)
              .height(16)
              .fillColor($r('sys.color.ohos_id_color_text_primary_activated'))
            
            Text('选择用户')
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          }
        }
        .height(36)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
        .borderRadius(18)
        .onClick(() => {
          this.otherUserDialogIsShow = true
        })
        .bindSheet($$this.otherUserDialogIsShow, this.otherUserMenu, {
          height: '80%',
          backgroundColor: $r('sys.color.ohos_id_color_dialog_bg'),
          showClose: true,
          dragBar: true,
          blurStyle: BlurStyle.COMPONENT_ULTRA_THICK
        })
      }
      .width('100%')

      // 用户展示区域 - 使用卡片式布局
      if (this.signIdArray.length === 0) {
        // 空状态提示 - 一镜到底：使用引导性设计
        Column({ space: 12 }) {
          Image($r('sys.media.ohos_ic_public_community_messages'))
            .width(48)
            .height(48)
            .fillColor($r('sys.color.ohos_id_color_text_tertiary'))
            .opacity(0.6)
          
          Text('未选择用户')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          
          Text('请点击上方按钮选择要签到的用户')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        // 已选用户列表 - 优化展示
        Column({ space: 8 }) {
          ForEach(this.signIdArray, (userId: number, index: number) => {
            ForEach(this.otherUser.filter(u => u.id === userId), (user: userMenu) => {
              Row() {
                // 序号指示器
                Text(`${index + 1}`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
                  .width(24)
                  .height(24)
                  .textAlign(TextAlign.Center)
                  .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
                  .borderRadius(12)
                  .margin({ right: 12 })

                // 用户头像
                Icon({ UserId: user.id })

                // 用户信息
                Column({ space: 2 }) {
                  Text(user.uname)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  
                  Text(user.SignPermission === 1 ? '可签到' : '已签到')
                    .fontSize(12)
                    .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 移除按钮
                Button({ type: ButtonType.Circle }) {
                  Image($r('sys.media.ohos_ic_public_remove'))
                    .width(16)
                    .height(16)
                    .fillColor($r('sys.color.ohos_id_color_warning'))
                }
                .width(32)
                .height(32)
                .backgroundColor($r('sys.color.ohos_id_color_warning', 0.1))
                .onClick(() => {
                  animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                    this.signIdArray = this.signIdArray.filter(num => num !== user.id)
                  })
                })
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('sys.color.ohos_id_color_background'))
              .borderRadius(12)
              .border({ width: 1, color: $r('sys.color.comp_divider') })
            })
          })
        }
        .width('100%')
      }
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 })
    .shadow({
      radius: 8,
      color: $r('sys.color.ohos_id_color_fourth', 0.1),
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  LocationCard() {
    Column({ space: 16 }) {
      // 标题
      Row() {
        Image($r('sys.media.ohos_ic_public_location'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.ohos_id_color_emphasize'))
          .margin({ right: 8 })
        
        Text('位置签到')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
      }
      .width('100%')

      // 要求位置信息卡片
      Column({ space: 12 }) {
        Row() {
          Text('要求位置')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .layoutWeight(1)
          
          if (this.DestinationLocationName !== '获取中...' && 
              this.DestinationLocationName !== '该签到无要求位置' &&
              this.DestinationLocationName !== '位置信息获取失败') {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 4 }) {
                Image($r('sys.media.ohos_ic_public_copy'))
                  .width(14)
                  .height(14)
                  .fillColor($r('sys.color.ohos_id_color_text_primary'))
                
                Text('复制')
                  .fontSize(12)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
              }
            }
            .height(28)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .borderRadius(14)
            .onClick(() => this.copyText(this.DestinationLocationName))
          }
        }
        .width('100%')

        // 位置信息展示
        Row() {
          if (this.DestinationLocationName === '获取中...') {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r('sys.color.ohos_id_color_emphasize'))
              .margin({ right: 8 })
          } else if (this.DestinationLocationName === '位置信息获取失败') {
            Image($r('sys.media.ohos_ic_public_fail'))
              .width(20)
              .height(20)
              .fillColor($r('sys.color.ohos_id_color_warning'))
              .margin({ right: 8 })
          } else if (this.DestinationLocationName === '该签到无要求位置') {
            Image($r('sys.media.ohos_ic_public_ok'))
              .width(20)
              .height(20)
              .fillColor($r('sys.color.ohos_id_color_connected'))
              .margin({ right: 8 })
          }
          
          Text(this.DestinationLocationName)
            .fontSize(15)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .borderRadius(12)
      }

      // 已选位置信息
      if (this.queryParams?.['address']) {
        Column({ space: 8 }) {
          Row() {
            Image($r('sys.media.ohos_ic_public_location'))
              .width(16)
              .height(16)
              .fillColor($r('sys.color.ohos_id_color_connected'))
              .margin({ right: 6 })
            
            Text('已选位置')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          
          Column({ space: 4 }) {
            Row() {
              Text('地址：')
                .fontSize(13)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
              Text(`${this.queryParams['address']}`)
                .fontSize(13)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            
            Row() {
              Text(`经度：${this.queryParams['longitude']}`)
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
              
              Text(' | ')
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                .margin({ left: 8, right: 8 })
              
              Text(`纬度：${this.queryParams['latitude']}`)
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
            }
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('sys.color.ohos_id_color_connected', 0.1))
        .borderRadius(12)
        .border({ width: 1, color: $r('sys.color.ohos_id_color_connected', 0.3) })
      } else {
        // 未选择位置的提示
        Column({ space: 8 }) {
          Image($r('sys.media.ohos_ic_public_location'))
            .width(32)
            .height(32)
            .fillColor($r('sys.color.ohos_id_color_warning'))
            .opacity(0.6)
          
          Text('尚未选择位置')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_warning'))
          
          Text('请点击下方按钮在地图上选择位置')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        }
        .width('100%')
        .padding(20)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.ohos_id_color_warning', 0.05))
        .borderRadius(12)
        .border({ width: 1, color: $r('sys.color.ohos_id_color_warning', 0.2) })
      }

      // 地图选点按钮
      Column() {
        FunctionalButton({
          params: {
            openType: functionalButtonComponentManager.OpenType.CHOOSE_LOCATION,
            label: '打开地图选点',
            styleOption: {
              bgColor: functionalButtonComponentManager.ColorType.DEFAULT,
              size: functionalButtonComponentManager.SizeType.DEFAULT,
              plain: false,
              disabled: this.DestinationLocationName === '获取中...' || 
                       this.DestinationLocationName === '该签到无要求位置',
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
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 })
    .shadow({
      radius: 8,
      color: $r('sys.color.ohos_id_color_fourth', 0.1),
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  QRCodeCard() {
QRCodeLocation({queryParams: this.queryParams,ActivityId: this.activityInfo?.ActivityId.toString() || '',})
  }

  @Builder
  GestureSignCard() {
    Column() {
      if (this.hostUser) {
        GestureSignComponent({
          activityId: this.activityInfo?.ActivityId || '',
          courseId: this.activityInfo?.CourseId || '',
          classId: this.activityInfo?.ClassId || '',
          cookies: this.hostUser.cookies,
          uid: this.hostUser.uid,
          uname: this.hostUser.uname,
          fid: this.hostUser.fid
        })
      } else {
        Text('加载用户信息中...')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin(20)
      }
    }
    .width('100%')
  }

  @Builder
  PasswordSignCard() {
    Column() {
      if (this.hostUser) {
        PasswordSignComponent({
          activityId: this.activityInfo?.ActivityId || '',
          courseId: this.activityInfo?.CourseId || '',
          classId: this.activityInfo?.ClassId || '',
          cookies: this.hostUser.cookies,
          uid: this.hostUser.uid,
          uname: this.hostUser.uname,
          fid: this.hostUser.fid
        })
      } else {
        Text('加载用户信息中...')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin(20)
      }
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      if (this.activityInfo) {
        Column() {
          // 1. 内容区域 (可滚动) - 一镜到底：流畅的滚动体验
          Scroll() {
            Column() {
              // 标题区域
              Column() {
                Text('签到详情')
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 20, bottom: 12 })

              // 用户选择卡片
              this.UserSelectionCard()

              // 根据类型渲染不同内容
              if (this.activityInfo?.signType === SignType.NORMAL) {
                if (this.ifPhoto) {
                  photoPicker({
                    signIdArray: this.signIdArray,
                    objectidArray: this.objectidArr,
                    otherUserDialogIsShow: this.otherUserDialogIsShow,
                    otherUser: this.otherUser
                  })
                    .margin({ left: 16, right: 16, bottom: 16 })
                } else {
                  Column() {
                    Image($r('sys.media.ohos_ic_public_ok'))
                      .width(40)
                      .height(40)
                      .fillColor($r('sys.color.ohos_id_color_emphasize'))
                      .opacity(0.6)
                      .margin({ bottom: 12 })
                    
                    Text('普通签到')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .margin({ bottom: 4 })
                    
                    Text('点击下方按钮直接签到')
                      .fontSize(14)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }
                  .width('100%')
                  .height(150)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  .borderRadius(16)
                  .margin({ left: 16, right: 16, bottom: 16 })
                }
              } else if (this.activityInfo?.signType === SignType.LOCATION) {
                this.LocationCard()
              } else if (this.activityInfo?.signType === SignType.GESTURE) {
                // 手势签到 - 只允许单用户签到
                this.GestureSignCard()
              } else if (this.activityInfo.signType === SignType.QRCODE) {
                this.QRCodeCard()
              } else {
                Column() {
                  Image($r('sys.media.ohos_ic_public_fail'))
                    .width(40)
                    .height(40)
                    .fillColor($r('sys.color.ohos_id_color_warning'))
                    .opacity(0.6)
                    .margin({ bottom: 12 })
                  
                  Text('未支持的签到类型')
                    .fontSize(16)
                    .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                }
                .width('100%')
                .height(150)
                .justifyContent(FlexAlign.Center)
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius(16)
                .margin({ left: 16, right: 16, bottom: 16 })
              }

              // 底部占位，避免被按钮遮挡
              if (this.activityInfo?.signType !== SignType.GESTURE &&
                this.activityInfo?.signType !== SignType.PASSWORD) {
                Column().height(100)
              }
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .backgroundColor($r('sys.color.ohos_id_color_sub_background'))

          // 2. 底部按钮区 (固定) - 手势签到和密码签到不显示底部按钮
          if (this.activityInfo?.signType !== SignType.GESTURE &&
            this.activityInfo?.signType !== SignType.PASSWORD) {
            Column() {
              Button('立即签到')
                .width('90%')
                .height(48)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(this.canSign ? $r('sys.color.ohos_id_color_emphasize') : 
                  $r('sys.color.ohos_id_color_fourth'))
                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                .borderRadius(24)
                .enabled(this.canSign)
                .shadow({
                  radius: 12,
                  color: this.canSign ? $r('sys.color.ohos_id_color_emphasize', 0.3) : 
                    $r('sys.color.ohos_id_color_fourth', 0.1),
                  offsetX: 0,
                  offsetY: 4
                })
                .onClick(() => {
                  this.showSignConfirmDialog()
                })
            }
            .width('100%')
            .padding({ top: 16, bottom: 24, left: 16, right: 16 })
            .backgroundColor($r('sys.color.ohos_id_color_background'))
            .shadow({
              radius: 16,
              color: $r('sys.color.ohos_id_color_fourth', 0.15),
              offsetX: 0,
              offsetY: -4
            })
          }
        }
        .height('100%')
      } else {
        Column() {
          Image($r('sys.media.ohos_ic_public_fail'))
            .width(64)
            .height(64)
            .fillColor($r('sys.color.ohos_id_color_warning'))
            .opacity(0.6)
            .margin({ bottom: 16 })
          
          Text('参数加载失败')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        }
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      }
    }
    .hideTitleBar(false)
    .title('签到', {
      backgroundColor: $r('sys.color.ohos_id_color_background')
    })
    .onReady((ctx: NavDestinationContext) => {
      this.pathInfos = ctx.pathStack;
    })
    .onAppear(() => {
      this.initPageData(); // 统一数据初始化入口
    })
  }

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

    if (!this.activityInfo || !currentUser) {
      return;
    }

    const cookies = currentUser.cookies;
    this.queryParams['activeId'] = this.activityInfo.ActivityId

    // 初始化主用户信息用于手势和密码签到
    try {
      const loginInfo = await loginFunction.getUserInfo(cookies);
      this.hostUser = {
        cookies: cookies,
        uid: loginInfo.uid,
        uname: loginInfo.uname,
        fid: parseInt(loginInfo.fid)
      };
    } catch (e) {
      hilog.error(DOMAIN, TAG, `Failed to initialize host user: ${e.message}`);
    }

    // 检查是否需要拍照
    this.ifPhoto = await Sign.ifPhoto(cookies, this.activityInfo.ActivityId)

    // 如果是位置签到，获取位置信息
    if (this.activityInfo.signType === SignType.LOCATION) {
      try {
        const locName =
          (await Sign.GetLocationSignInfo(cookies, this.activityInfo.ActivityId))['locationText'] as string
        this.DestinationLocationName = locName ? locName : '该签到无要求位置'
      } catch (e) {
        this.DestinationLocationName = '位置信息获取失败'
      }
    }

    // 加载其他可签到用户
    this.loadOtherUsers(dbManager, this.activityInfo);
  }

  private async loadOtherUsers(dbManager: DatabaseManager, actInfo: ActivityInfo) {
    const newUserList: userMenu[] = []
    const autoSelectIds: number[] = [] // 自动选择未签到的用户

    // 首先加载主用户（HostUser表，position 1）
    try {
      const mainUserInfo = await dbManager.getUserByPosition(1, true)
      if (mainUserInfo) {
        const loginInfo = await loginFunction.getUserInfo(mainUserInfo.cookies)
        const permission = await Sign.PreSignIn(actInfo.ActivityId, actInfo.ClassId, actInfo.CourseId, loginInfo.uid,
          mainUserInfo.cookies)
        newUserList.push({
          uname: loginInfo.uname + ' (主用户)',
          id: 0, // 用 0 表示主用户
          SignPermission: permission
        })
        // 如果主用户可以签到（SignPermission === 1），自动添加到选中列表
        if (permission === 1) {
          autoSelectIds.push(0)
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to load main user', e)
    }

    // 然后加载其他用户（OtherUser表）
    const userCount = await dbManager.getTableCount('OtherUser')
    for (let i: number = 1; i <= userCount; i++) {
      try {
        const userInfo = await dbManager.getUserByPosition(i)
        if (userInfo) {
          const loginInfo = await loginFunction.getUserInfo(userInfo.cookies)
          const permission =
            await Sign.PreSignIn(actInfo.ActivityId, actInfo.ClassId, actInfo.CourseId, loginInfo.uid, userInfo.cookies)
          newUserList.push({
            uname: loginInfo.uname,
            id: i,
            SignPermission: permission
          })
          // 如果用户可以签到（SignPermission === 1），自动添加到选中列表
          if (permission === 1) {
            autoSelectIds.push(i)
          }
        }
      } catch (e) {
        hilog.error(DOMAIN, TAG, `Failed to load user ${i}`, e)
      }
    }
    this.otherUser = newUserList;
    // 默认选中所有未签到的用户
    this.signIdArray = autoSelectIds;
  }

  // 3. 逻辑方法：显示签到确认对话框
  private showSignConfirmDialog() {
    if (this.signIdArray.length === 0) {
      AlertDialog.show({
        title: '提示',
        message: '请先选择至少一个用户',
        confirm: {
          value: '知道了',
          action: () => {
            this.otherUserDialogIsShow = true
          }
        }
      })
      return
    }

    const selectedUsers = this.otherUser.filter(u => this.signIdArray.includes(u.id));
    const userNames = selectedUsers.map(u => u.uname).join('、');

    AlertDialog.show({
      title: '确认签到',
      message: `即将为以下用户签到：\n${userNames}\n\n是否继续？`,
      primaryButton: {
        value: '修改用户',
        action: () => {
          this.otherUserDialogIsShow = true
        }
      },
      secondaryButton: {
        value: '确认签到',
        action: () => {
          this.handleSignAction()
        }
      }
    })
  }

  // 4. 逻辑方法：处理签到动作
  private async handleSignAction() {
    if (this.signIdArray.length !== this.objectidArr.length && this.ifPhoto) {
      promptAction.showToast({ message: '请等待图片上传完成' })
      return
    }

    if (this.signIdArray.length === 0) {
      promptAction.showToast({ message: '请选择至少一个用户' })
      return
    }

    this.canSign = false
    if (this.activityInfo?.signType === SignType.QRCODE) {
      const dbManager = DatabaseManager.getInstance()
      // 获取当前用户信息
      const currentUser = await dbManager.getUserByPosition(1, true) as UserDataAndId;

      if (!this.activityInfo || !currentUser) {
        this.canSign = true;
        return;
      }

      const cookies = currentUser.cookies;
      let loc = await Sign.GetLocationSignInfo(cookies, this.activityInfo.ActivityId)
      this.queryParams['address'] = loc['locationText'] as string;
      this.queryParams['longitude'] = loc['longitude'] as number;
      this.queryParams['latitude'] = loc['latitude'] as number;
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
              try {
                let url = result.originalValue
                let parse = UrlTools.parseUrlParams(url)

                if (!parse || !parse['enc']) {
                  promptAction.showToast({ message: '二维码格式错误' });
                  this.canSign = true;
                  return;
                }

                this.queryParams['enc'] = parse['enc']

                hilog.info(DOMAIN, TAG,
                  `Scan successful, enc: ${this.queryParams['enc']}`);

                // 扫码成功后，执行签到
                const hashTable = new Map<string, string[]>();

                // 遍历所有选中的用户进行签到
                for (let i = 0; i < this.signIdArray.length; i++) {
                  try {
                    const userId = this.signIdArray[i]
                    let userInfo: UserDataAndId
                    let isMainUser = false

                    if (userId === 0) {
                      // id 为 0 表示主用户
                      userInfo = await dbManager.getUserByPosition(1, true) as UserDataAndId
                      isMainUser = true
                    } else {
                      // 其他用户
                      userInfo = await dbManager.getUserByPosition(userId) as UserDataAndId
                      isMainUser = false
                    }

                    await this.performSingleSign(userInfo, this.objectidArr[i], hashTable, isMainUser)
                  } catch (e) {
                    hilog.error(DOMAIN, TAG, `User ${this.signIdArray[i]} sign error`, e)
                  }
                }

                this.showSignResult(hashTable);
              } catch (error) {
                const errorMsg = error instanceof Error ? error.message : String(error);
                hilog.error(DOMAIN, TAG, `Failed to process scan result: ${errorMsg}`);
                promptAction.showToast({ message: '处理扫码结果失败' });
              } finally {
                this.canSign = true;
              }
            })
            .catch((error: BusinessError) => {
              hilog.error(DOMAIN, TAG,
                `Failed to get ScanResult. Code:${error.code}, message: ${error.message}`);
              promptAction.showToast({ message: '扫码失败或已取消' });
              this.canSign = true;
            });
          // 扫码签到需要等待扫码结果，直接返回
          return;
        } else {
          promptAction.showToast({ message: '不支持扫码功能' });
          this.canSign = true;
          return;
        }
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, TAG,
          `Failed to start the scanning service: ${errorMsg}`);
        promptAction.showToast({ message: '启动扫码失败' });
        this.canSign = true;
        return;
      }
    }

    // 非扫码签到的正常流程
    const hashTable = new Map<string, string[]>();
    const dbManager = DatabaseManager.getInstance()

    // 遍历所有选中的用户进行签到
    for (let i = 0; i < this.signIdArray.length; i++) {
      try {
        const userId = this.signIdArray[i]
        let userInfo: UserDataAndId
        let isMainUser = false

        if (userId === 0) {
          // id 为 0 表示主用户
          userInfo = await dbManager.getUserByPosition(1, true) as UserDataAndId
          isMainUser = true
        } else {
          // 其他用户
          userInfo = await dbManager.getUserByPosition(userId) as UserDataAndId
          isMainUser = false
        }

        await this.performSingleSign(userInfo, this.objectidArr[i], hashTable, isMainUser)
      } catch (e) {
        hilog.error(DOMAIN, TAG, `User ${this.signIdArray[i]} sign error`, e)
      }
    }

    this.showSignResult(hashTable);
    this.canSign = true
  }

  private async performSingleSign(userInfo: UserDataAndId, photoObjId: string | undefined, map: Map<string, string[]>,
    isMainUser: boolean) {
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

    if (message === '') {
      message = '未进行任何签到操作';
    }

    AlertDialog.show({
      title: '签到结果',
      message: message,
      confirm: {
        value: '确定',
        action: () => {
        }
      }
    })
  }
}
