import { ActivityInfo } from './ActivityListPage';
import { Sign } from '../utils/sign';
import { JSON } from '@kit.ArkTS';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';
import fs from '@ohos.file.fs';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { ChaoxingUtils } from '../utils/utils';
import { picker } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { ChaoXingApi } from '../utils/PublicAPI';

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
        Text(this.user.uname).margin({ left: 30 }).width('20%')
        Blank()
        Text(this.user.SignPermission === 1 ? '' : this.user.SignPermission === 0 ? '你已经签过到了' : '你没有签到权限')
          .width('20%').margin({ right: 30 })
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

@Reusable
@Component
struct photoPicker {
  @State displayURI: string = ''
  @Link signIdArray: Array<number>
  @Link objectidArray: string[]
  @State backBlur: boolean = false
  @State isLoading: boolean = false

  build() {
    Column() {
      Button('选择图片')
        .onClick(async () => { // 设置加载状态（操作开始前）
          this.isLoading = true;

          try {
            // 一、配置图片选择选项
            const photoSelectOptions = new picker.PhotoSelectOptions();
            photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
            photoSelectOptions.maxSelectNumber = this.signIdArray.length + 1;

            console.log(`fucknima [PhotoSelect] 配置完成：最大选择数量 = ${photoSelectOptions.maxSelectNumber}`);

            // 生成文件名数组
            const photoNameArray: string[] = [];
            const len = this.signIdArray.length + 1;
            for (let i = 0; i < len; i++) {
              const name = ChaoxingUtils.generatePhotoName();
              photoNameArray.push(name);
              console.log(`fucknima [PhotoSelect] 生成文件名 ${i}: ${name}.jpg`);
            }

            // 二、创建选择器并执行选择
            const photoViewPicker = new picker.PhotoViewPicker();
            const res = await photoViewPicker.select(photoSelectOptions);

            // 检查选择结果
            if (!res || !Array.isArray(res.photoUris) || res.photoUris.length === 0) {
              console.warn('fucknima [PhotoSelect] 用户未选择任何图片或返回结果无效');
              this.isLoading = false;
              return;
            }

            console.log(`fucknima [PhotoSelect] 用户选择了 ${res.photoUris.length} 张图片`);

            // 保存首张图片用于显示
            this.displayURI = res.photoUris[0];

            const context = getContext(this);
            const dbManager = DatabaseManager.getInstance();

            // 三、逐个处理每张需要上传的图片（共 len 张）
            for (let i = 0; i < len; i++) {
              try {
                const sourceUri = res.photoUris[i % res.photoUris.length];
                const fileName = photoNameArray[i] + '.jpg';
                const copyFilePath = context.cacheDir + '/' + fileName;

                console.log(`fucknima [FileCopy] 正在处理第 ${i +
                  1} 张图片，源路径: ${sourceUri}, 目标路径: ${copyFilePath}`);

                // 打开源文件
                const file = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
                fs.copyFileSync(file.fd, copyFilePath);
                fs.closeSync(file.fd);
                const uploadFilePath = `internal://cache/${fileName}`
                console.log('fucknima' + uploadFilePath)
                // 构造上传文件对象
                const uploadFile: request.File[] = [{
                  uri: uploadFilePath,
                  filename: fileName,
                  name: 'file',
                  type: 'image/jpeg'
                }
                ];
                console.log('fucknima, 构建的上传参数为:' + JSON.stringify(uploadFile))

                // 获取用户信息
                let userInfo: UserDataAndId;
                try {
                  userInfo = await dbManager.getUserByPosition(i === 0 ? 1 : i, i === 0) as UserDataAndId;
                  if (!userInfo) {
                    throw new Error('用户信息缺失');
                  }
                } catch (userErr) {
                  console.error(`fucknima [Upload] 获取第 ${i} 个用户信息失败:`, userErr);
                  continue;
                }

                const token = await Sign.GetToken(userInfo.cookies);
                console.log('fucknimatoken:' + token);
                const puid = (await loginFunction.getUserInfo(userInfo.cookies)).puid
                const uploadData: request.RequestData[] = [{
                  name: 'puid',
                  value: puid
                }];

                console.log(`fucknima [Upload] 准备上传第 ${i + 1} 张图片，用户 UID: ${userInfo.uid}`);

                // 执行上传（Promise 封装）
                await new Promise<void>((resolve, reject) => {
                  request.uploadFile(
                    getContext(),
                    {
                      url: `https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=${token}`,
                      files: uploadFile,
                      data: uploadData,
                      method: http.RequestMethod.POST,
                      header: {
                        'Accept': '*/*'
                      }
                    },
                    (err, data) => {
                      if (err) {
                        console.error(`fucknima [Upload] 上传请求失败 (索引 ${i}): Code=${err.code}, Message=${err.message},error=${JSON.stringify(err)}`);
                        reject(err);
                        return;
                      }

                      const uploadTask = data;
                      uploadTask.on('headerReceive', (headerData) => {
                        try {
                          console.log('qqt000' + JSON.stringify(headerData));
                          const bodyStr = headerData?.['body'] as string | undefined;
                          if (bodyStr) {
                            const responseBody = JSON.parse(bodyStr) as object;
                            const objectId: string = responseBody?.['objectId'];
                            if (objectId) {
                              this.objectidArray[i] = objectId;
                              console.log(`fucknima [Upload] 第 ${i + 1} 张图片上传成功，objectId: ${objectId}`);
                            } else {
                              console.warn(`fucknima [Upload] 第 ${i + 1} 张图片响应中无 objectId`);
                            }
                          } else {
                            console.warn(`fucknima [Upload] 第 ${i + 1} 张图片响应体为空`);
                          }
                        } catch (parseErr) {
                          console.error(`fucknima [Upload] 解析响应体失败 (索引 ${i}):`, parseErr);
                        }
                        resolve();
                      });

                      uploadTask.on('fail', (failData) => {
                        console.error(`fucknima [Upload] 上传失败 (索引 ${i}):`, JSON.stringify(failData));
                        reject(new Error(`Upload failed: ${JSON.stringify(failData)}`));
                      });

                      uploadTask.on('complete', () => {
                        resolve();
                      });
                    }
                  );
                });

              } catch (innerErr) {
                console.error(`fucknima 信息: ${JSON.stringify(innerErr)}`);
                console.error(`fucknima [UploadLoop] 处理第 ${i + 1} 张图片时发生未预期错误:`,
                  JSON.stringify(innerErr));
              }
            }

            console.log('fucknima [PhotoUpload] 所有图片处理完成');
          } catch (outerErr) {
            console.error('fucknima [PhotoSelect/Upload] 整体流程发生严重错误:', outerErr);
          } finally {
            this.isLoading = false;
          }
        })
    }
    .width('100%')
    .padding({ top: 20 })
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
  @State objectidArr: string[] = []
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
                photoPicker({ signIdArray: this.signIdArray, objectidArray: this.objectidArr })
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
                      const LoginLocation = ChaoxingUtils.gcj02_to_bd09(data.latitude, data.longitude)
                      this.queryParams['address'] = data.name as string;
                      this.queryParams['longitude'] = LoginLocation.lon as number;
                      this.queryParams['latitude'] = LoginLocation.lat as number;
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
          // .onClick(async () => {
          //   const hashTable = new Map<string, string[]>();
          //   const dbManager = DatabaseManager.getInstance()
          //   const uid = await dbManager.getUserInfoById(true, 1, 'uid')
          //   const name = await dbManager.getUserInfoById(true, 1, 'name')
          //   const fid = await dbManager.getUserInfoById(true, 1, 'fid')
          //   this.queryParams['uid'] = uid
          //   this.queryParams['name'] = name
          //   this.queryParams['fid'] = fid
          //   if (this.ifPhoto) {
          //     this.queryParams['objectid'] = this.objectidArr[0]
          //   }
          //   const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
          //   console.log('fuck' + cookies)
          //   const result = await Sign.DoSignIn(cookies, this.queryParams)
          //
          //   for (let i = 0; i < this.signIdArray.length; i++) {
          //     const dbManager = DatabaseManager.getInstance()
          //     const uid = await dbManager.getUserInfoById(false, this.signIdArray[i], 'uid')
          //     const name = await dbManager.getUserInfoById(false, this.signIdArray[i], 'name') as string
          //     const fid = await dbManager.getUserInfoById(false, this.signIdArray[i], 'fid')
          //     this.queryParams['uid'] = uid
          //     this.queryParams['name'] = name
          //     this.queryParams['fid'] = fid
          //     if (this.ifPhoto) {
          //       this.queryParams['objectid'] = this.objectidArr[i+1]
          //     }
          //     const cookies = await dbManager.getUserInfoById(false, this.signIdArray[i], 'cookies') as string
          //     let result = await Sign.DoSignIn(cookies, this.queryParams)
          //     if (result.includes('<html') || result.includes('500 Internal Server Error')) {
          //       result = '签到不合法：服务器返回错误 (500)'
          //     }
          //     if (hashTable.has(result)) {
          //       hashTable.get(result)!.push(name);
          //     } else {
          //       hashTable.set(result, [name]);
          //     }
          //   }
          //   const messages: Record<string, string> = {
          //     "success": `用户${name}签到成功`,
          //     "validate": '签到需要验证码',
          //     '您已签到过了': `用户${name}已签到过了`
          //   };
          //
          //   let message = '';
          //   let duration = 3000;
          //
          //   // 判断是否是服务器返回的 HTML 错误页（特别是 500 错误）
          //   if (typeof result === 'string' &&
          //     (result.includes('<html') || result.includes('500 Internal Server Error'))) {
          //     message = '签到不合法：服务器返回错误 (500)';
          //   } else {
          //     // 正常逻辑处理 result
          //     message = messages[result] || `签到失败: 签到返回的结果为\n${result}`;
          //     duration = messages[result] ? 3000 : 6000;
          //   }
          //
          //   // 如果有其他用户的签到统计数据，追加显示
          //   if (hashTable.size > 0) {
          //     let statsMessage = '\n\n其他用户的签到统计数据:\n';
          //     hashTable.forEach((names, result) => {
          //       statsMessage += `${result}\n${names.join(', ')} (共 ${names.length} 人)\n`;
          //     });
          //
          //     message += statsMessage;
          //     duration = 10000; // 有统计信息则延长显示时间
          //   }
          //
          //   // 统一弹窗提示
          //   promptAction.showToast({ message, duration, alignment: Alignment.Center });
          //
          // })
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
        const userInfo = await dbManager.getUserByPosition(i)
        if (userInfo) {
          const cookies = userInfo.cookies
          const userName = (await loginFunction.getUserInfo(cookies)).uname
          const info = await loginFunction.getUserInfo(cookies)
          const uid = info.uid
          if (this.activityInfo) {
            const SignPermission =
              await Sign.PreSignIn(this.activityInfo.ActivityId, this.activityInfo.ClassId, this.activityInfo.CourseId,
                uid, cookies as string)
            this.otherUser.push({ 'uname': userName as string, 'id': i, SignPermission: SignPermission })
          }
        }
      }
      const cookies = (await dbManager.getUserByPosition(1, true))?.cookies as string
      if (this.activityInfo) {
        this.ifPhoto = await Sign.ifPhoto(cookies, this.activityInfo.ActivityId)
      }
      console.log(this.ifPhoto.toString())
    })
  }
}