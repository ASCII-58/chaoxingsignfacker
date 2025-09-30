import { ActivityInfo } from './ActivityListPage';
import { Sign } from '../utils/sign';
import { JSON } from '@kit.ArkTS';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseManager } from '../utils/DataBase';
import promptAction from '@ohos.promptAction';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';
import picker from '@ohos.file.picker';
import { request } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { ChaoxingUtils } from '../utils/utils';

interface userMenu {
  uname: string
  id: number
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
          const url = await dbManager.getUserInfoById(false, this.UserId, 'pic') as string
          console.log('fuck' + url)
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
    console.log('fuck')
    if (this.signIdArray.includes(this.user.id) &&
      this.color !== $r('sys.color.hds_snackbar_button_background_color')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      }, () => {
        this.color = $r('sys.color.hds_snackbar_button_background_color')
      })
      console.log('fuck11111111111111')
    }
    if (!this.signIdArray.includes(this.user.id) &&
      this.color !== $r('sys.color.button_background_color_transparent')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      }, () => {
        this.color = $r('sys.color.button_background_color_transparent')
      })
      console.log('fuck00000000000000000')
    }
  }

  build() {
    Row() {
      Row() {
        Icon({ UserId: this.user.id })
        Text(this.user.uname).margin({ left: 30, right: 60 })
      }
      .height(60)
      .width('90%')
      .borderRadius(40)
      .backgroundColor(this.color)
    }.justifyContent(FlexAlign.Center)
    .onAppear(() => {
      console.log('fuck')
      if (this.signIdArray.includes(this.user.id) &&
        this.color !== $r('sys.color.hds_snackbar_button_background_color')) {
        animateTo({
          duration: 300,
          curve: 'smooth'
        }, () => {
          this.color = $r('sys.color.hds_snackbar_button_background_color')
        })
        console.log('fuck11111111111111')
      }
      if (!this.signIdArray.includes(this.user.id) &&
        this.color !== $r('sys.color.button_background_color_transparent')) {
        animateTo({
          duration: 300,
          curve: 'smooth'
        }, () => {
          this.color = $r('sys.color.button_background_color_transparent')
        })
        console.log('fuck00000000000000000')
      }
    })
  }
}

@Builder
export function initSignInfo(name: string, activityInfo: ActivityInfo) {
  SignPage({ activityInfo: activityInfo })
}

@Component
export struct SignPage {
  @State activityInfo: null | ActivityInfo = null
  @State queryParams: object = JSON.parse('{}') as object
  @State otherUser: Array<userMenu> = []
  @State signIdArray: Array<number> = []
  @State IsSignForHost: boolean = true
  @State ifPhoto: boolean = false
  @State otherUserDialogIsShow: boolean = false
  @State uriArr: string[] = []
  @State objectidArr: string[] = []
  @State backBlur: boolean = false
  @State canSign: boolean = false
  pathInfos: NavPathStack = new NavPathStack();

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
          userItem({ user: user, signIdArray: this.signIdArray })
        }.onClick(() => {
          console.log('fuck' + this.signIdArray.toString())
          if (this.signIdArray.includes(user.id)) {
            console.log('fuck1')
            this.signIdArray = this.signIdArray.filter(num => num !== user.id)
          } else {
            console.log('fuck0')
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
            if (this.activityInfo?.signType === '0') {
              if (this.ifPhoto) {
                Image(this.uriArr[0])
                  .objectFit(ImageFit.Contain)
                  .borderRadius($r('sys.float.corner_radius_level5'))
                Button('选择图片')
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .backgroundBlurStyle(this.backBlur ? BlurStyle.BACKGROUND_THICK : BlurStyle.NONE,
                    {
                      colorMode: ThemeColorMode.SYSTEM,
                      adaptiveColor: AdaptiveColor.DEFAULT,
                      scale: 1.0
                    })
                  .fontColor(this.backBlur ? $r('sys.color.font_on_primary') : $r('sys.color.font_emphasize'))
                  .height(40)
                  .fontWeight(FontWeight.Medium)
                  .fontSize($r('sys.float.Body_L'))
                  .margin({ bottom: 36 })
                  .onClick(() =>{
                    let context = getContext(this) as common.UIAbilityContext;
                    if (!context) {
                      hilog.error(0x0000, 'PhotoUpload', '获取上下文失败：context is null');
                      return;
                    }

                    let filesDir: string;
                    try {
                      filesDir = context.cacheDir;
                      if (!filesDir) {
                        throw new Error('cacheDir is empty');
                      }
                    } catch (err) {
                      hilog.error(0x0000, 'PhotoUpload', `获取缓存目录失败：${err instanceof Error ? err.message : String(err)}`);
                      return;
                    }

                    const photoSelectOptions = new picker.PhotoSelectOptions();
                    photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
                    photoSelectOptions.maxSelectNumber = this.signIdArray.length + 1;

                    const photoViewPicker = new picker.PhotoViewPicker();
                    photoViewPicker.select(photoSelectOptions)
                      .then(async (res) => { // 注意这里添加 async，因为 forEach 内部有 await
                        this.uriArr = res.photoUris;
                        hilog.info(0x0000, 'PhotoUpload', `成功选择 ${this.uriArr.length} 张图片`);

                        if (this.uriArr.length === 0) {
                          hilog.warn(0x0000, 'PhotoUpload', '未选择任何图片');
                          return;
                        }

                        this.backBlur = true;
                        const uploadFile: request.File[] = [];

                        // 使用 for...of 替代 forEach，避免异步操作无法正确捕获错误和控制流程
                        for (let index = 0; index < this.uriArr.length; index++) {
                          const photoURI = this.uriArr[index];
                          try {
                            // 打开文件
                            let file: fs.File;
                            try {
                              file = fs.openSync(photoURI, fs.OpenMode.READ_ONLY); // 读取图片用 READ_ONLY 更合理
                            } catch (err) {
                              throw new Error(`打开文件失败（URI: ${photoURI}）：${err instanceof Error ? err.message : String(err)}`);
                            }

                            // 生成 UUID 并复制文件
                            const uuid = ChaoxingUtils.generateUUIDv4();
                            const targetPath = `${filesDir}/${uuid}.jpg`; // 修复路径拼接错误（缺少 /）
                            try {
                              fs.copyFileSync(file.fd, targetPath);
                              hilog.info(0x0000, 'PhotoUpload', `文件复制成功：${targetPath}`);
                            } catch (err) {
                              throw new Error(`复制文件失败（目标路径: ${targetPath}）：${err instanceof Error ? err.message : String(err)}`);
                            } finally {
                              // 确保文件描述符关闭，避免资源泄漏
                              fs.closeSync(file.fd);
                            }

                            // 构建上传文件对象
                            const photoFile: request.File = {
                              filename: `${uuid}.jpg`,
                              name: `${uuid}.jpg`,
                              uri: 'internal://cache/'+uuid+'.jpg',
                              type: 'image/jpeg' // 更标准的 MIME 类型
                            };
                            uploadFile.push(photoFile);

                            // 数据库查询
                            const dbManager = DatabaseManager.getInstance();
                            if (!dbManager) {
                              throw new Error('DatabaseManager 实例获取失败');
                            }

                            const isFirst = !index; // 简化判断逻辑
                            const userId = isFirst ? 1 : this.signIdArray[index - 1]; // 注意：原逻辑中 index 对应关系可能需要确认
                            let cookies: string, uid: number;

                            try {
                              cookies = await dbManager.getUserInfoById(isFirst, userId, 'cookies') as string;
                              uid = await dbManager.getUserInfoById(isFirst, userId, 'uid') as number;
                            } catch (err) {
                              throw new Error(`查询用户信息失败（用户ID: ${userId}）：${err instanceof Error ? err.message : String(err)}`);
                            }
                            try {
                              const objectid = await Sign.UploadPhoto(getContext(this), cookies, [photoFile], uid);
                              if (!objectid) {
                                throw new Error('上传返回的 objectid 为空');
                              }
                              this.objectidArr.push(objectid);
                              hilog.info(0x0000, 'PhotoUpload', `图片上传成功（用户ID: ${userId}，objectid: ${objectid}）`);
                            } catch (err) {
                              console.error(`图片上传失败（用户ID: ${userId}）：${err instanceof Error ? err.message : String(err)}`);
                            }

                          } catch (err) {
                            // 捕获单张图片处理的错误，继续处理下一张
                            hilog.error(0x0000, 'PhotoUpload', `处理第 ${index + 1} 张图片失败：${err instanceof Error ? err.message : String(err)}`);
                          }
                        }

                        // 检查上传文件数量是否符合预期
                        if (uploadFile.length === this.signIdArray.length + 1) {
                          this.canSign = true;
                          hilog.info(0x0000, 'PhotoUpload', '所有图片处理完成，可开始签到');
                        } else {
                          hilog.warn(0x0000, 'PhotoUpload', `上传文件数量不匹配：预期 ${this.signIdArray.length + 1}，实际 ${uploadFile.length}`);
                        }

                      })
                      .catch((err:Error )=> {
                        hilog.error(0x0000, 'PhotoUpload', `图片选择失败：${err instanceof Error ? err.message : String(err)}`);
                      });
                  })
              }
            } else if (this.activityInfo?.signType === '2') {
            } else if (this.activityInfo?.signType === '4') {
              Column() {
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
                        hilog.error(0x0000, "testTag", "error: %{public}d %{public}s", err.code, err.message);
                        console.error('fuck+' + JSON.stringify(err))
                        return;
                      }
                      // 成功日志处理。
                      hilog.info(0x0000, "testTag", "succeeded in choosing location");
                      this.queryParams['address'] = data.name as string;
                      this.queryParams['longitude'] = data.longitude as number;
                      this.queryParams['latitude'] = data.latitude as number;
                      this.queryParams['activeId'] = this.activityInfo?.ActivityId
                      this.canSign = true

                    })
                })
              }
            }
          }.height('50%')
          .width('60%')
          .align(Alignment.Center)

          Button('签到')
            .enabled(this.canSign)
            .accessibilityDescription('当前按钮不可用')
            .onClick(async () => {
              const hashTable = new Map<string, string[]>();
              const dbManager = DatabaseManager.getInstance()
              const uid = await dbManager.getUserInfoById(true, 1, 'uid')
              const name = await dbManager.getUserInfoById(true, 1, 'name')
              const fid = await dbManager.getUserInfoById(true, 1, 'fid')
              this.queryParams['uid'] = uid
              this.queryParams['name'] = name
              this.queryParams['fid'] = fid
              if (this.ifPhoto) {
                this.queryParams['objectid'] = this.objectidArr[0]
              }
              const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
              console.log('fuck'+cookies)
              const result = await Sign.DoSignIn(cookies, this.queryParams)

              for (let i = 0; i < this.signIdArray.length; i++) {
                const dbManager = DatabaseManager.getInstance()
                const uid = await dbManager.getUserInfoById(false, this.signIdArray[i], 'uid')
                const name = await dbManager.getUserInfoById(false, this.signIdArray[i], 'name') as string
                const fid = await dbManager.getUserInfoById(false, this.signIdArray[i], 'fid')
                this.queryParams['uid'] = uid
                this.queryParams['name'] = name
                this.queryParams['fid'] = fid
                if (this.ifPhoto) {
                  this.queryParams['objectid'] = this.objectidArr[i+1]
                }
                const cookies = await dbManager.getUserInfoById(false, this.signIdArray[i], 'cookies') as string
                let result = await Sign.DoSignIn(cookies, this.queryParams)
                if (result.includes('<html') || result.includes('500 Internal Server Error')) {
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
              let duration = 3000;

              // 判断是否是服务器返回的 HTML 错误页（特别是 500 错误）
              if (typeof result === 'string' &&
                (result.includes('<html') || result.includes('500 Internal Server Error'))) {
                message = '签到不合法：服务器返回错误 (500)';
              } else {
                // 正常逻辑处理 result
                message = messages[result] || `签到失败: 签到返回的结果为\n${result}`;
                duration = messages[result] ? 3000 : 6000;
              }

              // 如果有其他用户的签到统计数据，追加显示
              if (hashTable.size > 0) {
                let statsMessage = '\n\n其他用户的签到统计数据:\n';
                hashTable.forEach((names, result) => {
                  statsMessage += `${result}\n${names.join(', ')} (共 ${names.length} 人)\n`;
                });

                message += statsMessage;
                duration = 10000; // 有统计信息则延长显示时间
              }

              // 统一弹窗提示
              promptAction.showToast({ message, duration });

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
      const dbManager = DatabaseManager.getInstance()
      const userCount = await dbManager.getTableCount('OtherUser')
      for (let i: number = 1; i <= userCount; i++) {
        const userName = await dbManager.getUserInfoById(false, i, 'name')
        this.otherUser.push({ 'uname': userName as string, 'id': i })
      }
      const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
      this.ifPhoto = await Sign.ifPhoto(cookies, this.activityInfo?.ActivityId as number)
    })
  }
}