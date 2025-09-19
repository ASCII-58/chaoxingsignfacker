import { ActivityInfo } from './ActivityListPage';

@Builder
export function initSignInfo(name: string, activityInfo: ActivityInfo) {
  SignPage({ activityInfo: activityInfo })
}

@Component
export struct SignPage {
  activityInfo: null | ActivityInfo = null
  pathInfos: NavPathStack = new NavPathStack();
  @State activityId: number = 0
  @State courseId: number = 0
  @State classId: number = 0
  @State signType: string = ''

  build() {
    NavDestination() {
      Column() {
      }
    }
    .height('100%')
    .width('100%')
    .title('签到')
    .onReady((ctx: NavDestinationContext) => {
      // NavDestinationContext获取当前所在的导航控制器
      this.pathInfos = ctx.pathStack;
    })
  }
}