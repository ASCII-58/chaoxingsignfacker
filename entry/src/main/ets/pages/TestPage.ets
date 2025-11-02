import picker from '@ohos.file.picker';

import fs from '@ohos.file.fs';

import request from '@ohos.request';
import http from '@ohos.net.http';

// 定义类型
interface UploadResponse {
  body: string
}

export interface Response {
  /**
   * 业务状态码，10000成功, 其他失败
   */
  code: number;

  /**
   * 响应数据
   */
  data: Data;

  /**
   * 响应消息
   */
  message: string;
}

/**
 * 响应数据
 */
export interface Data {
  /**
   * 上传成功的图片-在线地址
   */
  url: string;
}

@Builder
export function init(name: string) {
  Page03_uploadImg()
}

// 实例化 选项对象
const photoSelectOptions = new picker.PhotoSelectOptions();
// 过滤选择媒体文件类型为IMAGE
photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
// 选择媒体文件的最大数目
photoSelectOptions.maxSelectNumber = 10;

@Component
export struct Page03_uploadImg {
  pathInfos: NavPathStack = new NavPathStack();
  @State num: number = 0

  build() {
    NavDestination() {

      Column() {
        Image('http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/ajax/17128585871360.5802423440443907.jpg')
          .height(30)
          .width(30)
        Text(this.num.toString())
        Button('选择并上传图片')
          .onClick(() => {
            // 创建 图片选择对象
            const photoViewPicker = new picker.PhotoViewPicker();
            // 调用 select 方法，传入选项对象
            photoViewPicker.select(photoSelectOptions)
              .then(res => {
                const uri = res.photoUris
                // 因为只选了一张
                // AlertDialog.show({ message: '图片路径为:' + uri })

                // 三、拷贝文件到缓存目录
                // 将文件保存到缓存目录(只能上传在缓存目录中的文件)
                for (let index = 0; index < 10; index++) {
                  const context = getContext(this)
                  const fileType = 'jpg'
                  // 生成一个新的文件名
                  const fileName = Date.now() + '.' + fileType
                  // 通过缓存路径+文件名 拼接出完整的路径
                  const copyFilePath = context.cacheDir + '/' + fileName

                  // 将文件 拷贝到 临时目录
                  const file = fs.openSync(uri[index], fs.OpenMode.READ_ONLY)
                  fs.copyFileSync(file.fd, copyFilePath)
                  // 四、上传图片
                  // 上传文件
                  let files: Array<request.File> = [
                    // internal://cache/ 固定的，后面跟上 咱们上一步拷贝文件名即可
                    // name 和接口文档的要求对上
                    {
                      filename: Date.now() + '.' + fileType,
                      type: fileType,
                      name: 'file',
                      uri: `internal://cache/${fileName}`
                    }
                  ]
                  const a: string[] = ['341133751', '820fde763f8165c8b5d9b01b23c6af21']
                  request.uploadFile(context, {
                    url: `https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=${a[1]}`, // url 地址
                    method: http.RequestMethod.POST, // 请求方法
                    header: {
                      // 和接口文档的要求的格式对象
                      contentType: 'multipart/form-data',
                    },
                    files, // 文件信息
                    data: [{ name: 'puid', value: a[0] }] // 额外提交的数据，不能省略
                  })
                    .then((res => {
                      // 这里可以获取到响应的内容
                      res.on('headerReceive', (value) => {
                        // body 是 JSON
                        AlertDialog.show({
                          message: JSON.stringify(value)
                        })
                        console.log('上传结果:', JSON.stringify(value), index)
                        this.num++
                      })
                    }))
                }
              })
          })
      }
    }
    .title('上传图片')
    .height('100%')
    .width('100%')
    .onReady((ctx: NavDestinationContext) => {
      // NavDestinationContext获取当前所在的导航控制器
      this.pathInfos = ctx.pathStack;
    })
  }
}
