/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { curves, promptAction } from '@kit.ArkUI';
import { SearchPageExtraInfo } from '../utils/commonutils/ExtraInfo';
import { CourseAndActivity, ClassInfo } from '../utils/classFun';
import { DatabaseManager } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import { image } from '@kit.ImageKit';

@Builder
export function init() {
  SearchLongTakeTransitionPageTwo()
}

// 课程项组件
@Reusable
@Component
struct CourseItem {
  @Prop course: ClassInfo
  @State courseImage: image.PixelMap | null = null
  @State isPressed: boolean = false
  onCourseClick?: (course: ClassInfo) => void

  build() {
    Row() {
      // 课程图片
      if (this.courseImage) {
        Image(this.courseImage)
          .width(60)
          .height(60)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column()
          .width(60)
          .height(60)
          .borderRadius(8)
          .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
      }

      // 课程信息
      Column() {
        Text(this.course.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.course.teacherfactor) {
          Text(`教师: ${this.course.teacherfactor}`)
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius(12)
    .shadow({
      radius: this.isPressed ? 12 : 8,
      color: '#00000018',
      offsetX: 0,
      offsetY: this.isPressed ? 4 : 2
    })
    .scale({ x: this.isPressed ? 0.98 : 1, y: this.isPressed ? 0.98 : 1 })
    .animation({
      duration: 200,
      curve: Curve.FastOutSlowIn
    })
    .onClick(() => {
      if (this.onCourseClick) {
        this.onCourseClick(this.course)
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onAppear(async () => {
      if (this.course.imageurl) {
        try {
          this.courseImage = await loginFunction.GetPic(this.course.imageurl) as image.PixelMap
        } catch (e) {
          console.error('Failed to load course image', e)
        }
      }
    })
  }
}

// [Start bind_id]
@Component
export default struct SearchLongTakeTransitionPageTwo {
  @Prop param: SearchPageExtraInfo;
  private pageInfos: NavPathStack = new NavPathStack();
  @State searchText: string = ''
  @State allCourses: ClassInfo[] = []
  @State filteredCourses: ClassInfo[] = []
  @State isLoading: boolean = false

  async aboutToAppear() {
    await this.loadCourses()
  }

  async loadCourses() {
    this.isLoading = true
    try {
      const dbManager = DatabaseManager.getInstance()
      const userData = await dbManager.getUserByPosition(1, true)
      
      if (userData) {
        const result = await CourseAndActivity.getClassList(userData.cookies)
        if (result.msg) {
          this.allCourses = result.classList
          this.filteredCourses = result.classList
        } else {
          promptAction.showToast({ message: '获取课程列表失败', duration: 2000 })
        }
      }
    } catch (e) {
      console.error('Failed to load courses', e)
      promptAction.showToast({ message: '加载课程失败', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }

  handleSearch(value: string) {
    this.searchText = value
    if (!value) {
      this.filteredCourses = this.allCourses
    } else {
      const searchLower = value.toLowerCase()
      this.filteredCourses = this.allCourses.filter(course => 
        course.name.toLowerCase().includes(searchLower) || 
        (course.teacherfactor && course.teacherfactor.toLowerCase().includes(searchLower))
      )
    }
  }

  handleCourseClick(course: ClassInfo): void {
    // 返回上一页并传递选中的课程信息
    promptAction.showToast({ 
      message: `已选择: ${course.name}`, 
      duration: 1500 
    })
    // 这里可以添加导航到课程详情或签到页面的逻辑
    // this.pageInfos.pushPath({ name: 'ActivityListPage', param: course })
  }

  build() {
    NavDestination() {
      Column() {
        // 搜索栏
        Row({ space: 8 }) {
          Image($r('app.media.img'))
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .padding(8)
            .shadow({
              radius: 4,
              color: '#00000010',
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => {
              this.onArrowClicked();
            })
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 200, delay: 150, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }),
              TransitionEffect.OPACITY
                .animation({ duration: 200, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) })
            ))

          Search({ placeholder: '搜索课程名称或教师', value: $$this.searchText })
            .height(40)
            .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
            .width('85%')
            .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
            .geometryTransition('SEARCH_ONE_SHOT_DEMO_TRANSITION_ID')
            .transition(TransitionEffect.opacity(0.99))
            .defaultFocus(true)
            .focusOnTouch(true)
            .onSubmit((value: string) => {
              this.handleSearch(value)
            })
            .onChange((value: string) => {
              this.handleSearch(value)
            })
        }
        .width('100%')
        .height(50)
        .alignItems(VerticalAlign.Center)
        .padding(16)

        // 搜索结果
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('sys.color.ohos_id_color_emphasize'))
            Text('加载中...')
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
        } else if (this.filteredCourses.length === 0) {
          Column() {
            Text(this.searchText ? '未找到匹配的课程' : '暂无课程')
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .transition(TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
            .animation({ duration: 300, curve: Curve.FastOutSlowIn }))
        } else {
          Column() {
            Text(`找到 ${this.filteredCourses.length} 个课程`)
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 8 })
              .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))

            List({ space: 8 }) {
              ForEach(this.filteredCourses, (course: ClassInfo, index: number) => {
                ListItem() {
                  CourseItem({ 
                    course: course,
                    onCourseClick: (c: ClassInfo) => this.handleCourseClick(c)
                  })
                }
                .transition(TransitionEffect.asymmetric(
                  TransitionEffect.OPACITY
                    .combine(TransitionEffect.translate({ x: 50 }))
                    .animation({ duration: 300, delay: index * 30, curve: Curve.FastOutSlowIn }),
                  TransitionEffect.OPACITY
                    .animation({ duration: 200 })
                ))
              })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .size({
        width: '100%',
        height: '100%'
      })
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    }
    .transition(TransitionEffect.OPACITY)
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack;
    })
    .onBackPressed(() => {
      this.getUIContext().animateTo({
        curve: curves.interpolatingSpring(0, 1, 342, 38),
      }, () => {
        this.pageInfos.pop(false);
      })
      return true;
    })
  }

  private onArrowClicked(): void {
    this.pageInfos.pop(false);
  }
}
// [End bind_id]