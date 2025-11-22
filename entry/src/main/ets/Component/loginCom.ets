import { promptAction } from '@kit.ArkUI';
import { DatabaseManager, UserData, UserDataAndId } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import { ChaoxingUtils } from '../utils/utils';

@Reusable
@Component
export struct loginByCommon {
  @Link otherUserList: UserDataAndId[];
  @State username: string = '';
  @State password: string = '';
  @State LoginEnable: boolean = false
  @Link isShow: boolean

  build() {
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
        .onClick(async () => {
          this.LoginEnable = false
          const uname = ChaoxingUtils.encryptByAES(this.username)
          const pwd = ChaoxingUtils.encryptByAES(this.password)
          const result = await (loginFunction.LoginChaoXing(ChaoxingUtils.getLoginBody(uname, pwd)))
          if (result) {
            const cookies = result
            const info = await loginFunction.getUserInfo(cookies)
            try {
              const dbManager = DatabaseManager.getInstance()
              const userData: UserData = {
                phone: this.username,
                pwd: pwd,
                cookies: cookies,
                uid: info.uid
              };
              console.log('fuck' + JSON.stringify(userData))
              let operationResult = await dbManager.insertUser(userData)
              if (operationResult === 1) {
                promptAction.showToast({ message: '登录成功', duration: 2000 })
                this.otherUserList = await dbManager.getAllUsers()
                this.isShow = !this.isShow
              } else if (operationResult === 0) {
                promptAction.showToast({ message: '数据库异常，可能需要重启应用', duration: 10000 })
                let applicationContext = this.getUIContext().getHostContext()?.getApplicationContext();
                applicationContext?.killAllProcesses(false);
              } else {
                promptAction.showToast({ message: '用户已登录', duration: 2000 })
              }
              this.username = ''
              this.password = ''
            } catch (e) {
              this.username = '';
              this.password = '';
              if (e instanceof Error) {
                promptAction.showToast({
                  message: '添加失败，请重试' +
                    (e.message.includes("手机号已存在，请使用其他手机号") ? ', 该账号已添加' : ''),
                  duration: 2000
                })
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
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Reusable
@Component
export struct loginByURL {
  @Link otherUserList: UserDataAndId[];
  @State LoginURL: string = '';
  @State LoginEnable: boolean = false
  @Link isShow: boolean

  build() {
    Column() {
      Text('URL')
        .fontSize(26)
        .height(40)
        .width('90%')
        .textAlign(TextAlign.Start)
      TextInput({ placeholder: '', text: this.LoginURL })
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.LoginURL = value;
          if (this.LoginURL) {
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
      Button('登录')
        .enabled(this.LoginEnable)
        .width('60%')
        .height(50)
        .onClick(async () => {
          const LoginMSG = await loginFunction.LoginByURL(this.LoginURL)
          promptAction.showToast({ message: LoginMSG })
          if (LoginMSG === '添加成功') {
            let dbManager=DatabaseManager.getInstance();
            this.otherUserList = await dbManager.getAllUsers()
            this.isShow = !this.isShow
          } else {
            this.LoginURL = '';
            this.LoginEnable = false
          }
        })
        .margin({ bottom: 20 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}