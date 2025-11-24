import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';

@Reusable
@Component
export struct OtherUserItem {
  @State DelButtonScale: number = 1;
  @Prop userData: UserDataAndId;
  @Prop index: number;
  @Link otherUserList: UserDataAndId[]
  @State userImage: image.PixelMap | null = null;
  @State userName: string = ''
  @State isLoaded: boolean = false;
  private dbManger: DatabaseManager = DatabaseManager.getInstance()

  build() {
    Row() {
      Image(this.userImage)
        .width(50)
        .height(50)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(10)
        .margin(5)
        .alt($r('app.media.foreground'))
      Column() {
        Text(this.userName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.userData.phone)
          .fontSize(10)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }.margin({ left: 10 })
      .width(140)
      .alignItems(HorizontalAlign.Start)

      Blank()
      Button() {
        Image($r('app.media.ic_public_delete'))
          .height(30)
          .width(30)
          .fillColor($r('app.color.icon'))
          .margin(10)
      }
      .borderRadius(999)
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .shadow({
        radius: 8,
        color: '#00000020',
        offsetX: 0,
        offsetY: 3
      })
      .scale({ x: this.DelButtonScale, y: this.DelButtonScale })
      .animation({ duration: 200, curve: Curve.EaseInOut })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.DelButtonScale = 0.92
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.DelButtonScale = 1
        }
      }).margin({ right:15 })
      .onClick(async () => {
        let result = await this.dbManger.deleteUser(this.userData.id)
        if (result === 1) {
          this.otherUserList.splice(this.index, 1)
        }
      })

    }
    .onAppear(async () => {
      if (!this.isLoaded) {
        let userInfo = await loginFunction.getUserInfo(this.userData.cookies)
        this.userName = userInfo.uname
        this.userImage = await loginFunction.GetPic(userInfo.pic)
        this.isLoaded = true
      }
    })
    .height(60)
    .width('100%')
    .borderRadius(15)
    .backgroundColor($r('app.color.class_button'))
    .shadow({
      radius: 8,
      color: '#00000020',
      offsetX: 0,
      offsetY: 3
    })
    .animation({ duration: 200, curve: Curve.EaseInOut })
  }
}
