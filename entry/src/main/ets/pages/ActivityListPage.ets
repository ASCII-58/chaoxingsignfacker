import { ActivityItem, ClassInfo, CourseAndActivity } from '../utils/classFun';
import { ChaoxingUtils } from '../utils/utils';
import { promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../utils/DataBase';
import { JSON } from '@kit.ArkTS';
/**
 * @param signType '0' 普通/拍照签到 | '2' 扫码签到 | '4' 位置签到
 */
export interface ActivityInfo {
  ActivityId: number;
  CourseId: number;
  ClassId: number;

  signType: string
}

@Reusable
@Component
struct signIcon {
  @Prop signType: string;
  @State icon: ResourceStr = $r('app.media.foreground')

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
        })
        .backgroundColor('#aaaaaa')
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
  @State courseId: number = 0; // 课程id
  @State teacherfactor: string = '';
  @State classId: number = 0; // 班级id
  @State name: string = '';
  @State ActivityList: ActivityItem[] | null = null

  build() {
    NavDestination() {
      if (this.ActivityList) {
        List({ space: 12, initialIndex: 0 }) {
          ForEach(this.ActivityList, (Activity: ActivityItem) => {
            if (!(Activity.type != 2 && Activity.type != 74)) {
              ListItem() {
                Row() {
                  signIcon({ signType: Activity.otherId.toString() })
                  if (1) {
                    Column() {
                      Text(Activity.nameOne).fontSize(20)
                      if (typeof Activity.endTime === 'string') {
                        Text(ChaoxingUtils.isSignActivityStarted(Activity.startTime) ? '无截止日期' :
                          `${ChaoxingUtils.getRemainingTime(Activity.startTime) / 60000 << 0}分钟开始签到`)
                      } else {
                        Text(ChaoxingUtils.isSignActivityActive(Activity.startTime, Activity.endTime) ?
                          (`${ChaoxingUtils.getRemainingTime(Activity.endTime) / 60000 << 0}分钟后结束`) :
                          (ChaoxingUtils.isSignActivityEnded(Activity.endTime) ? '已结束' :
                            `${ChaoxingUtils.getRemainingTime(Activity.startTime) / 60000 << 0}分钟后开始签到`))
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
              .onClick(() => {
                if (typeof Activity.endTime === 'number') {
                  if (!ChaoxingUtils.isSignActivityActive(Activity.startTime, Activity.endTime)||!ChaoxingUtils.isSignActivityStarted(Activity.startTime)) {
                    promptAction.showToast({ message: '不在可签到时间内, 无法签到' })
                    return
                  }
                }
                const activityInfo: ActivityInfo = {
                  ActivityId: Activity.id,
                  CourseId: this.courseId,
                  ClassId: this.classId,
                  signType: Activity.otherId.toString()
                }
                this.pathInfos.pushPath({ name: 'SignerPage', param: activityInfo })
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
        this.courseId = this.classInfo?.id as number; // 课程id
        console.log('fuck', this.courseId)
        this.teacherfactor = this.classInfo?.teacherfactor as string;
        console.log('fuck', this.teacherfactor)
        this.classId = this.classInfo?.classId as number; // 班级id
        this.name = this.classInfo?.name as string
        console.log('fuck', this.name)
        const dbManager = DatabaseManager.getInstance()
        const cookies = await dbManager.getUserInfoById(true, 1, 'cookies') as string
        console.log('fuck', cookies)
        console.error('fuck', 'true', 'false')
        this.ActivityList = await CourseAndActivity.getActivityList(cookies, this.classId, this.courseId);
        console.error('fuck' + this.ActivityList ? 'true' : 'false')
        this.ActivityList?.forEach(element => {
          console.log('fuck' + JSON.stringify(element))
        });
      } catch (e) {
        console.error('fuck' + e)
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}