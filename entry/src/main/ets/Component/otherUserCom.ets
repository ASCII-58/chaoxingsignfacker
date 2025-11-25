import { DatabaseManager, UserDataAndId } from '../utils/DataBase';
import { image } from '@kit.ImageKit';
import { loginFunction } from '../utils/Login';
import { curves } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DELETE_ANIMATION_DURATION_MS = 300;
const TAG = 'OtherUserItem';
const DOMAIN = 0x0009;

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
  @State itemOpacity: number = 0;
  @State translateY: number = 20;
  @State itemScale: number = 0.95;
  private dbManger: DatabaseManager = DatabaseManager.getInstance()
  private showDeleteDialog() {
    AlertDialog.show({
      title: '确认删除',
      message: `确认删除用户${this.userName}吗？\n`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          // Animate out before deletion
          animateTo({
            duration: DELETE_ANIMATION_DURATION_MS,
            curve: curves.springMotion(0.6, 0.9)
          }, () => {
            this.itemOpacity = 0
            this.translateY = -20
            this.itemScale = 0.8
          })

          // Wait for animation to complete before deleting
          setTimeout(async () => {
            try {
              let result = await this.dbManger.deleteUser(this.userData.id)
              if (result === 1) {
                this.otherUserList.splice(this.index, 1)
              }
            } catch (error) {
              // Log the error and reset animation to indicate failure
              hilog.error(DOMAIN, TAG, `Failed to delete user: ${error.message}`);
              // Reset the animation to restore the item
              animateTo({
                duration: 200,
                curve: curves.springMotion(0.6, 0.9)
              }, () => {
                this.itemOpacity = 1
                this.translateY = 0
                this.itemScale = 1
              })
            }
          }, DELETE_ANIMATION_DURATION_MS)
        }
      }
    })
  }
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
          .fillColor(Color.Red)
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
      })
      .margin({ right: 15 })
      .onClick(async () => {
        this.showDeleteDialog()
      })

    }
    .onAppear(async () => {
      // Staggered entrance animation for list items
      animateTo({
        duration: 400,
        curve: curves.springMotion(0.6, 0.8),
        delay: this.index * 50
      }, () => {
        this.itemOpacity = 1
        this.translateY = 0
        this.itemScale = 1
      })

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
      radius: 10,
      color: '#00000025',
      offsetX: 0,
      offsetY: 4
    })
    // Note: Using explicit opacity, translate, and scale instead of .animation()
    // to have precise control over entrance and exit animations with spring motion curves
    .opacity(this.itemOpacity)
    .translate({ y: this.translateY })
    .scale({ x: this.itemScale, y: this.itemScale })
  }
}
