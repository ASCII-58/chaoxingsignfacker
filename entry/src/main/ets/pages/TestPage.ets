import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取应用文件路径
let context = getContext(this) as common.UIAbilityContext;
let cacheDir = context.cacheDir;
// 上传任务配置项
let uploadConfig: request.UploadConfig = {
  url: 'http://192.168.3.48:8740/file/upload',
  header: { key1: 'Content-Type', key2: 'multipart/form-data' },
  method: 'POST',
  files: [
    {
      filename: 'test.jpg',
      name: 'test',
      uri: 'internal://cache/test.jpg',
      type: 'jpg'
    }
  ],
  data: [
    { name: 'fileId', value: 'FP000008' }
  ]
}

@Builder
export function init(name: string) {
  test()
}

@Component
export struct test {
  @State message: string = ''
  @State imgSrc: string = ''

  async selectImage() {
    try {
      let PhotoSelectOptions = new picker.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.maxSelectNumber = 1;
      let photoPicker = new picker.PhotoViewPicker();
      photoPicker.select(PhotoSelectOptions).then((PhotoSelectResult) => {
        console.info('xx PhotoViewPicker.select successfully, PhotoSelectResult uri: ' +
        JSON.stringify(PhotoSelectResult));
        // 从图库选择图片后，返回图片uri
        let uri = PhotoSelectResult.photoUris[0];
        console.info('xx uri:' + uri)
        this.imgSrc = uri
        // 读取上面返回uri
        let file = fs.openSync(uri, fs.OpenMode.CREATE);
        // 复制文件到缓存目录下
        fs.copyFileSync(file.fd, cacheDir + '/test.jpg')
        // 上传文件到服务器上
        this.uploadImage()
      }).catch((err: string) => {
        console.error('xx PhotoViewPicker.select failed with err: ' + err);
      });
    } catch (err) {
      console.error('xx PhotoViewPicker failed with err: ' + err);
    }
  }

  uploadImage() {
    // 将本地应用文件上传至网络服务器
    try {
      request.uploadFile(context, uploadConfig)
        .then((uploadTask) => {
          uploadTask.on('complete', (taskStates) => {
            for (let i = 0; i < taskStates.length; i++) {
              console.info(`fuckxx upload complete taskState: ${JSON.stringify(taskStates[i])}`);
              this.message = JSON.stringify(taskStates[i])
            }
          });
        })
        .catch((err: BusinessError) => {
          console.error(`fuckxx Invoke uploadFile failed, code is ${err.code}, message is ${err.message}`);
          this.message = err.message
        })
    } catch (err) {
      const error = err as BusinessError;
      console.error(`fuckxx Invoke uploadFile failed, code is ${error.code}, message is ${error.message}`);
      this.message = error.message
    }
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Button('打开图库')
          .width('80%').height('40')
          .onClick(() => {
            this.selectImage()
          })
        Image(this.imgSrc)
          .width('50%').height('50%')
        Text(this.message)
          .fontSize(20).width('100%')
      }
      .width('100%').height('100%')
      .padding(10)
    }.height('100%')
    .width('100%')
    .title('测试')
  }
}