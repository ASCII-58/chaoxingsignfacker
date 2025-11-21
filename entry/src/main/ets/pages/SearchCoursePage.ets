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

import { curves } from '@kit.ArkUI';
import { SearchPageExtraInfo } from '../utils/commonutils/ExtraInfo';

@Builder
export function init() {
  SearchLongTakeTransitionPageTwo()
}

// [Start bind_id]
@Component
export default struct SearchLongTakeTransitionPageTwo {
  @Prop param: SearchPageExtraInfo;
  private pageInfos: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column() {
        Row({ space: 8 }) {
          Image($r('app.media.img'))
            .width(40)
            .height(40)
            .onClick(() => {
              this.onArrowClicked();
            })
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 200, delay: 150, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }),
              TransitionEffect.OPACITY
                .animation({ duration: 200, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) })
            ))

          Search({ placeholder: 'DevEco Studio' })
            .height(40)
            .placeholderColor($r('sys.color.mask_secondary'))
            .width('85%')
            .backgroundColor('#0D000000')
            .height(40)
            // bind geometry id
            .geometryTransition('SEARCH_ONE_SHOT_DEMO_TRANSITION_ID')
            .transition(TransitionEffect.opacity(0.99))
            .defaultFocus(true)
            .focusOnTouch(true)
        }
        .width('100%')
        .height(50)
        .alignItems(VerticalAlign.Center)
        .padding(16)
      }
      .size({
        width: '100%',
        height: '100%'
      })
      .margin({ top: 16 })
    }
    .transition(TransitionEffect.OPACITY)
    .hideTitleBar(true)
    .backgroundColor('#F1F3F5')
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
    // this.getUIContext().animateTo({
    //   curve: curves.interpolatingSpring(0, 1, 342, 38)
    // }, () => {
    // })
  }
}
// [End bind_id]