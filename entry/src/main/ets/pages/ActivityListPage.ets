import { ActivityItem, ClassInfo, CourseAndActivity } from '../utils/classFun';
import { ChaoxingUtils } from '../utils/utils';
import { promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../utils/DataBase';
import { JSON } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ActivityListPage';
const DOMAIN = 0x0005;

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
          this.isLoaded = true
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
                this.pathInfos.pushPath({ name: 'SignerPage', param: activityInfo })
              })
            }
          }, (Activity: ActivityItem) => Activity.id)
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
          hilog.debug(DOMAIN, TAG, `Course ID: ${this.courseId}`);
          this.teacherfactor = this.classInfo?.teacherfactor as string;
          hilog.debug(DOMAIN, TAG, `Teacher: ${this.teacherfactor}`);
          this.classId = this.classInfo.classId; // 班级id
          this.name = this.classInfo?.name as string
          hilog.debug(DOMAIN, TAG, `Class name: ${this.name}`);
          const dbManager = DatabaseManager.getInstance()
          const cookies = (await dbManager.getUserByPosition(1, true))?.cookies
          if (cookies) {
            hilog.debug(DOMAIN, TAG, 'Loading activity list');
            this.ActivityList = await CourseAndActivity.getActivityList(cookies, this.classId, this.courseId);
            hilog.debug(DOMAIN, TAG, `Activity list loaded: ${this.ActivityList ? 'success' : 'failed'}`);
            if (this.ActivityList) {
              this.ActivityList.forEach(element => {
                hilog.debug(DOMAIN, TAG, `Activity: ${JSON.stringify(element)}`);
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
        hilog.error(DOMAIN, TAG, `Error in onAppear: ${e.message}`);
      }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}