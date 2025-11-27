import { promptAction, router } from '@kit.ArkUI';
import { DatabaseManager, UserData } from '../utils/DataBase';
import { ChaoxingUtils } from '../utils/utils';
import { loginFunction } from '../utils/Login';
import { curves } from '@kit.ArkUI';

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
  @State isLoading: boolean = false
  @State shakeTranslateY: number = 0
  @State shakeScale: number = 1

  aboutToAppear() {
    // Entrance animation for title
    animateTo({ duration: 600, curve: curves.springMotion(0.6, 0.8), delay: 100 }, () => {
      this.titleOpacity = 1
      this.titleTranslateY = 0
    })
    // Entrance animation for form
    animateTo({ duration: 600, curve: curves.springMotion(0.6, 0.8), delay: 300 }, () => {
      this.formOpacity = 1
      this.formTranslateY = 0
    })
  }

  // Trigger shake animation for error feedback
  private triggerShakeAnimation() {
    animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
      this.shakeTranslateY = 10
      this.shakeScale = 0.98
    })
    setTimeout(() => {
      animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
        this.shakeTranslateY = -10
      })
      setTimeout(() => {
        animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
          this.shakeTranslateY = 0
          this.shakeScale = 1
        })
      }, 100)
    }, 100)
  }

  async handleLogin() {
    this.isLoading = true
    try {
      const uname = ChaoxingUtils.encryptByAES(this.username)
      const pwd = ChaoxingUtils.encryptByAES(this.password)
      const result = await (loginFunction.LoginChaoXing(ChaoxingUtils.getLoginBody(uname, pwd)))

      if (result && result !== '服务器错误，请稍后重试') {
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
          // Insert as primary user (true)
          await dbManager.insertUser(userData, true)

          promptAction.showToast({ message: '登录成功', duration: 2000 })
          router.replaceUrl({
            url: 'pages/Index'
          })
        } catch (e) {
          this.username = '';
          this.password = '';
          if (e instanceof Error) {
            if (e.message.includes('主用户已登录')) {
              promptAction.showToast({ message: '主用户已登录,请勿重复登录', duration: 2000 })
            } else {
              promptAction.showToast({
                message: '登录失败: ' + e.message,
                duration: 2000
              })
            }
            this.triggerShakeAnimation()
          }
        }
      } else {
        promptAction.showToast({
          message: result || '登录失败',
          duration: 1500,
          bottom: '20%'
        });
        this.username = '';
        this.password = '';
        this.triggerShakeAnimation()
      }
    } catch (error) {
      promptAction.showToast({ message: '发生错误，请重试' });
      this.triggerShakeAnimation()
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Scroll() {
      Column() {
        Column().height('15%')

        Text('学习通账号\n登录')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .width('90%')
          .margin({ bottom: 40 })
          .opacity(this.titleOpacity)
          .translate({ y: this.titleTranslateY })

        Column({ space: 20 }) {
          TextInput({ placeholder: '手机号', text: this.username })
            .type(InputType.PhoneNumber)
            .cancelButton({ style: CancelButtonStyle.INPUT })
            .enterKeyType(EnterKeyType.Next)
            .onChange((value: string) => {
              this.username = value;
              if (this.username && this.password) {
                this.LoginEnable = true
              }
            })
            .placeholderFont({ size: 16 })
            .height(56)
            .width('100%')
            .backgroundColor($r('sys.color.ohos_id_color_text_field_bg'))
            .borderRadius(16)
            .padding({ left: 20, right: 20 })

          TextInput({ placeholder: '密码', text: this.password })
            .type(InputType.Password)
            .showPasswordIcon(true)
            .enterKeyType(EnterKeyType.Go)
            .onSubmit(() => {
              if (this.LoginEnable && !this.isLoading) {
                this.handleLogin()
              }
            })
            .onChange((value: string) => {
              this.password = value;
              if (this.username && this.password) {
                this.LoginEnable = true
              }
            })
            .placeholderFont({ size: 16 })
            .height(56)
            .width('100%')
            .backgroundColor($r('sys.color.ohos_id_color_text_field_bg'))
            .borderRadius(16)
            .padding({ left: 20, right: 20 })

          Button() {
            Row() {
              if (this.isLoading) {
                LoadingProgress().width(24).height(24).color(Color.White).margin({ right: 10 })
                Text('登录中...').fontColor($r('sys.color.ohos_id_color_text_primary_activated')).fontSize(18)
                  .fontWeight(FontWeight.Medium)
              } else {
                Text('登录').fontColor($r('sys.color.ohos_id_color_text_primary_activated')).fontSize(18)
                  .fontWeight(FontWeight.Medium)
              }
            }
          }
          .type(ButtonType.Capsule)
            .enabled(this.LoginEnable && !this.isLoading)
            .width('100%')
            .height(56)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .shadow({ radius: 10, color: 'rgba(10, 89, 247, 0.2)', offsetY: 5 })
            .onClick(() => {
              this.handleLogin()
            })
            .margin({ top: 20 })
        }
        .width('90%')
          .opacity(this.formOpacity)
          .translate({ y: this.formTranslateY })
          .translate({ x: this.shakeTranslateY }) // Apply shake to form
      }
      .width('100%')
        .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
