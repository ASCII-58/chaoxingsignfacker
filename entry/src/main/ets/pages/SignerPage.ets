import { ActivityInfo } from './ActivityListPage';
import { Sign } from '../utils/sign'
import { JSON } from '@kit.ArkTS';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseManager } from '../utils/DataBase';
import promptAction from '@ohos.promptAction';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';

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
        .margin({left:5})
        .onAppear(async () => {
          const dbManager = DatabaseManager.getInstance()
          const url = await dbManager.getUserInfoById(true,this.UserId,'pic') as string
          console.log('fuck'+url)
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
  @Link @Watch('transformC') signIdArray: number[]

  transformC(){
    console.log('fuck')
    if (this.signIdArray.includes(this.user.id)&&this.color!==$r('sys.color.hds_snackbar_button_background_color')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      },()=>{
        this.color = $r('sys.color.hds_snackbar_button_background_color')
      })
      console.log('fuck11111111111111')
    }
    if (!this.signIdArray.includes(this.user.id)&&this.color!==$r('sys.color.button_background_color_transparent')) {
      animateTo({
        duration: 300,
        curve: 'smooth'
      },()=>{
        this.color = $r('sys.color.button_background_color_transparent')
      })
      console.log('fuck00000000000000000')
    }
  }

  build() {
    Row() {
      Row(){
        Icon({ UserId: this.user.id})
        Text(this.user.uname).margin({left:30,right:60})
      }
      .height(60)
      .width('90%')
      .borderRadius(40)
      .backgroundColor(this.color)
    }.justifyContent(FlexAlign.Center)
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
  @State otherUser: Array<userMenu> = [{ uname: '1275673', id: 1 }]
  @State signIdArray: Array<number> = []
  @State otherUserIsShow: boolean = false
  pathInfos: NavPathStack = new NavPathStack();

  @Builder
  NavigationMenu() {
    Column(){
      Image($r('app.media.ic_contacts_addcontact'))
        .height(30)
        .width(30)
        .onClick(() => {
          this.otherUserIsShow = false
          this.otherUserIsShow = true
        })
        .bindSheet(this.otherUserIsShow, this.otherUserMenu,{title:{title:$r('app.string.other_user')}})
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
          userItem({user:user,signIdArray:this.signIdArray})
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
          if (this.activityInfo?.signType === '0') {
          } else if (this.activityInfo?.signType === '2') {
          } else if (this.activityInfo?.signType === '4') {
            Text(this.queryParams?.['address'] ? this.queryParams?.['address'] : '请先点击下方按钮选择位置')
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
                })
            })
          }
          Button('签到')
            .onClick(async () => {
              const dbManager = DatabaseManager.getInstance()
              const uid = dbManager.getUserInfoById(true, 1, 'uid')
              const name = dbManager.getUserInfoById(true, 1, 'name')
              const fid = dbManager.getUserInfoById(true, 1, 'fid')
              this.queryParams['uid'] = uid
              this.queryParams['name'] = name
              this.queryParams['fid'] = fid
              const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
              const result = await Sign.DoSignIn(cookies, this.queryParams)
              promptAction.showToast({ message: result })

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
    })
  }
}