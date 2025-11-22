import { ActivityItem, ClassInfo, CourseAndActivity } from '../utils/classFun';
import { ChaoxingUtils } from '../utils/utils';
import { promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../utils/DataBase';
import { JSON } from '@kit.ArkTS';

/**
 * @param signType '0' 普通/拍照签到 | '2' 扫码签到 | '4' 位置签到
 */
export interface ActivityInfo {
  ActivityId: string;
  CourseId: string;
  ClassId: string;
  signType: SignType
}

export enum SignType {
  NORMAL = '0',
  QRCODE = '2',
  LOCATION = '4'
}
@Reusable
@Component
struct signIcon {
  @Prop signType: string;
  @State icon: ResourceStr = $r('app.media.foreground')
  @State isLoaded: boolean = false

  // 位置签到、二维码签到、普通签到、签到
  build() {
    Row() { // 0"=普通签到, "2"=二维码签到, "4"=位置签到
      Image(this.icon)
        .width(50)
        .height(50)
        .borderColor($r('app.color.class_icon_border'))
        .borderWidth(3)
        .borderRadius(10)
        .margin(10)
        .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
        .opacity(this.isLoaded ? 1 : 0)
        .scale({ x: this.isLoaded ? 1 : 0.8, y: this.isLoaded ? 1 : 0.8 })
        .animation({
          duration: 300,
          curve: Curve.FastOutSlowIn
        })
        .onAppear(() => {
          if (this.signType === '4') {
            this.icon = $r('app.media.map_badge_local')
          }
          if (this.signType === '2') {
            this.icon = $r('app.media.qrcode')
          }
          if (this.signType === '0') {
            this.icon = $r('app.media.hand_tap')
          }
          animateTo({
            duration: 300,
            curve: Curve.FastOutSlowIn
          }, () => {
            this.isLoaded = true
          })
        })
    }
  }
}

@Builder
export function initClassInfo(name: string, classInfo: ClassInfo) {
  if (name) {
    ActivityListPage({
      classInfo: classInfo
    })
  }
}


@Component
export struct ActivityListPage {
  classInfo: ClassInfo | null = null;
  pathInfos: NavPathStack = new NavPathStack();
  @State courseId: string = ''; // 课程id
  @State teacherfactor: string = '';
  @State classId: string = ''; // 班级id
  @State name: string = '';
  @State ActivityList: ActivityItem[] | null = null

  build() {
    NavDestination() {
      if (this.ActivityList) {
        List({ space: 12, initialIndex: 0 }) {
          ForEach(this.ActivityList, (Activity: ActivityItem, index: number) => {
            if (!(Activity.type != 2 && Activity.type != 74)) {
              ListItem() {
                Row() {
                  signIcon({ signType: Activity.otherId.toString() })
                  if (1) {
                    Column() {
                      Text(Activity.nameOne).fontSize(20).fontWeight(FontWeight.Medium)
                      if (typeof Activity.endTime === 'string') {
                        Text(ChaoxingUtils.isSignActivityStarted(Activity.startTime) ? '无截止日期' :
                          `${ChaoxingUtils.getRemainingTime(Activity.startTime) / 60000 << 0}分钟开始签到`)
                          .fontSize(12)
                          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      } else {
                        Text(ChaoxingUtils.isSignActivityActive(Activity.startTime, Activity.endTime) ?
                          (`${ChaoxingUtils.getRemainingTime(Activity.endTime) / 60000 << 0}分钟后结束`) :
                          (ChaoxingUtils.isSignActivityEnded(Activity.endTime) ? '已结束' :
                            `${ChaoxingUtils.getRemainingTime(Activity.startTime) / 60000 << 0}分钟后开始签到`))
                          .fontSize(12)
                          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      }
                    }.width(100)
                  }
                }.width('100%')
              }
              .width('100%')
              .backgroundColor(typeof Activity.endTime === 'string' ?
                (ChaoxingUtils.isSignActivityStarted(Activity.startTime) ? $r('app.color.class_button') :
                  $r('app.color.class_button_disabled')) :
                (ChaoxingUtils.isSignActivityActive(Activity.startTime, Activity.endTime) ?
                  $r('app.color.class_button') :
                  $r('app.color.class_button_disabled')))
              .height(70)
              .borderRadius(20)
              .shadow({
                radius: 8,
                color: '#00000015',
                offsetX: 0,
                offsetY: 2
              })
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.OPACITY
                  .combine(TransitionEffect.translate({ y: 30 }))
                  .animation({ duration: 300, delay: index * 50, curve: Curve.FastOutSlowIn }),
                TransitionEffect.OPACITY
                  .animation({ duration: 200 })
              ))
              .onClick(() => {
                if (typeof Activity.endTime === 'number') {
                  if (!ChaoxingUtils.isSignActivityActive(Activity.startTime, Activity.endTime) ||
                    !ChaoxingUtils.isSignActivityStarted(Activity.startTime)) {
                    promptAction.showToast({ message: '不在可签到时间内, 无法签到' })
                    return
                  }
                }
                const activityInfo: ActivityInfo = {
                  ActivityId: Activity.id,
                  CourseId: this.courseId,
                  ClassId: this.classId,
                  signType: Activity.otherId.toString() as SignType
                }
                animateTo({
                  duration: 250,
                  curve: Curve.FastOutSlowIn
                }, () => {
                  this.pathInfos.pushPath({ name: 'SignerPage', param: activityInfo })
                })
              })
            }
          })
        }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .height('100%')
      }
    }
    .height('100%')
    .width('100%')
    .title(`${this.name}`)
    .onReady((ctx: NavDestinationContext) => {
      // NavDestinationContext获取当前所在的导航控制器
      this.pathInfos = ctx.pathStack;
    })
    .onAppear(async () => {
      try {
        if (this.classInfo) {
          this.courseId = this.classInfo.id; // 课程id
          console.log('fuck', this.courseId)
          this.teacherfactor = this.classInfo?.teacherfactor as string;
          console.log('fuck', this.teacherfactor)
          this.classId = this.classInfo.classId; // 班级id
          this.name = this.classInfo?.name as string
          console.log('fuck', this.name)
          const dbManager = DatabaseManager.getInstance()
          const cookies = (await dbManager.getUserByPosition(1, true))?.cookies
          if (cookies) {
            console.log('fuck', cookies)
            console.error('fuck', 'true', 'false')
            this.ActivityList = await CourseAndActivity.getActivityList(cookies, this.classId, this.courseId);
            console.error('fuck' + this.ActivityList ? 'true' : 'false')
            if (this.ActivityList) {
              this.ActivityList.forEach(element => {
                console.log('fuck' + JSON.stringify(element))
              });
            } else {
              throw new Error('签到列表获取为空')
            }
          } else {
            throw new Error('用户登录信息错误')
          }
        } else {
          throw new Error('未获取到课程信息')
        }
      } catch (e) {
        console.error('fuck' + e)
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}