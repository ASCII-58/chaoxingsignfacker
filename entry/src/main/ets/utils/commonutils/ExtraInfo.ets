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

export class ExtraInfo {}

export class NormalPageExtraInfo extends ExtraInfo {
  public geometryId: string;

  constructor(geometryId: string) {
    super();
    this.geometryId = geometryId;
  }
}

export class ListDetailPageExtraInfo extends NormalPageExtraInfo {
  public title: string | Resource;
  public content: Resource;

  constructor(geometryId: string, title: string | Resource, content: Resource) {
    super(geometryId)
    this.title = title;
    this.content = content;
  }
}

export class SearchPageExtraInfo extends NormalPageExtraInfo {
  public onBackClicked: () => void;

  constructor(geometryId: string, onBackClicked: () => void) {
    super(geometryId);
    this.onBackClicked = onBackClicked;
  }
}