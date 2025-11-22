import { promptAction, router } from '@kit.ArkUI';
import { DatabaseManager, UserData } from '../utils/DataBase';
import { ChaoxingUtils } from '../utils/utils';
import { loginFunction } from '../utils/Login';
import { JSON } from '@kit.ArkTS';

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State LoginEnable: boolean = false
  @State titleOpacity: number = 0
  @State titleTranslateY: number = -50
  @State formOpacity: number = 0
  @State formTranslateY: number = 30
  @State buttonScale: number = 1

  aboutToAppear() {
    // Entrance animation for title
    animateTo({ duration: 600, curve: Curve.EaseOut, delay: 100 }, () => {
      this.titleOpacity = 1
      this.titleTranslateY = 0
    })
    // Entrance animation for form
    animateTo({ duration: 600, curve: Curve.EaseOut, delay: 300 }, () => {
      this.formOpacity = 1
      this.formTranslateY = 0
    })
  }

  build() {
    Column() {
      Text('学习通账号\n登录')
        .margin({ top: 10, bottom: 10 })
        .fontSize(40)
        .textAlign(TextAlign.Center)
        .opacity(this.titleOpacity)
        .translate({ y: this.titleTranslateY })
      Column() {
        Text('用户名')
          .fontSize(26)
          .height(40)
          .width('90%')
          .textAlign(TextAlign.Start)
        TextInput({ placeholder: '', text: this.username })
          .type(InputType.PhoneNumber)
          .onChange((value: string) => {
            this.username = value;
            if (this.username && this.password) {
              this.LoginEnable = true
            }
          })
          .placeholderFont({ size: 16 })
          .height(50)
          .width('90%')
          .backgroundColor(Color.Transparent)// 透明背景
          .border({
            // 设置边框
            width: {
              // 分别设置四个方向的边框宽度
              top: 0,
              right: 0,
              bottom: 2, // 只有底部有边框
              left: 0
            },
            color: {
              // 设置边框颜色
              top: Color.Transparent,
              right: Color.Transparent,
              bottom: Color.Blue, // 底部边框颜色
              left: Color.Transparent
            },
            style: BorderStyle.Solid // 边框样式
          ,
            radius: 0
          })
          .margin({ bottom: 20 })
        Text('密码')
          .fontSize(26)
          .height(40)
          .width('90%')
          .textAlign(TextAlign.Start)
        TextInput({ placeholder: '', text: this.password })
          .type(InputType.Password)// 设置为密码类型
          .onChange((value: string) => {
            this.password = value;
            if (this.username && this.password) {
              this.LoginEnable = true
            }
          })
          .placeholderFont({ size: 16 })
          .height(50)
          .width('90%')
          .backgroundColor(Color.Transparent)// 透明背景
          .border({
            // 设置边框
            width: {
              // 分别设置四个方向的边框宽度
              top: 0,
              right: 0,
              bottom: 2, // 只有底部有边框
              left: 0
            },
            color: {
              // 设置边框颜色
              top: Color.Transparent,
              right: Color.Transparent,
              bottom: Color.Blue, // 底部边框颜色
              left: Color.Transparent
            },
            style: BorderStyle.Solid // 边框样式
          ,
            radius: 0
          })
          .margin({ bottom: 40 })
        Button('登录')
          .enabled(this.LoginEnable)
          .width('60%')
          .height(50)
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .animation({ duration: 200, curve: Curve.EaseInOut })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.buttonScale = 0.95
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.buttonScale = 1
            }
          })
          .onClick(async () => {
          this.LoginEnable = false
          const uname = ChaoxingUtils.encryptByAES(this.username)
          const pwd = ChaoxingUtils.encryptByAES(this.password)
          const result = await (loginFunction.LoginChaoXing(ChaoxingUtils.getLoginBody(uname, pwd)))
          if (result) {
            if (result === '傻逼服务器崩了') {
              promptAction.showToast({
                message: result, // 要显示的文本消息
                duration: 1500, // 显示时长，单位是毫秒(ms)。默认值为1500ms。
                bottom: '20%' // 弹窗距离屏幕底部的距离，可以是vp或百分比。可选参数。
              });
              this.username = '';
              this.password = '';
              return
            }
            try {
              const cookies = result
              const info = await loginFunction.getUserInfo(cookies)
              const dbManager = DatabaseManager.getInstance()
              const userData: UserData = {
                phone: this.username,
                pwd: pwd,
                cookies: cookies,
                uid: info.uid
              };
              console.log('fuck' + JSON.stringify(userData))
              await dbManager.insertUser(userData, true)
              this.username = ''
              this.password = ''
              promptAction.showToast({ message: '登录成功', duration: 2000 })
              router.replaceUrl({
                url: 'pages/Index' // 跳转目标页面路径
              })
            } catch (e) {
              this.username = '';
              this.password = '';
              if (e instanceof Error) {
                if (e.message.includes('主用户已登录')) {
                  promptAction.showToast({ message: '主用户已登录,请勿重复登录', duration: 2000 })
                } else {
                  promptAction.showToast({
                    message: '添加失败，请重试' +
                      (e.message.includes("手机号已存在，请使用其他手机号") ? ', 该账号已添加' : ''),
                    duration: 2000
                  })
                }
                return
              }
            }
          } else {
            promptAction.showToast({
              message: result, // 要显示的文本消息
              duration: 1500, // 显示时长，单位是毫秒(ms)。默认值为1500ms。
              bottom: '20%' // 弹窗距离屏幕底部的距离，可以是vp或百分比。可选参数。
            });
            this.username = '';
            this.password = '';
          }
        })
        .margin({ bottom: 20 })
      }
      .opacity(this.formOpacity)
      .translate({ y: this.formTranslateY })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}