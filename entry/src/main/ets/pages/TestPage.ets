import { common } from '@kit.AbilityKit';
import { fileIo as fs, ListFileOptions } from '@kit.CoreFileKit';
import { uri, util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import picker from '@ohos.file.picker';
import {Sign} from '../utils/sign'
import { uiEffect } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { request } from '@kit.BasicServicesKit';
import { ChaoXingApi, InternalPath } from '../utils/PublicAPI';
import { data } from '@kit.TelephonyKit';

@Builder
export function init(name: string) {
  test()
}


async function copyImageToSandbox(context: common.Context): Promise<string> {
  const photoPicker = new picker.PhotoViewPicker();
  const selectResult = await photoPicker.select({ maxSelectNumber: 1 });

  if (selectResult.photoUris.length === 0) {
    throw new Error('未选择图片');
  }

  const sourceUri = selectResult.photoUris[0];
  const fileName = sourceUri.split('/').pop() as string;
  const destPath = `${context.cacheDir}/${Date.now()}_${fileName}`;

  try {
    await fs.copy(sourceUri, destPath);
    console.log('复制成功')
  } catch (error) {
    console.log('复制失败:'+error)
  }
  console.log('fuck91+'+destPath)
  return destPath;
}


@Component
export struct test {
  @State pixelMap: PixelMap | undefined = undefined;
  @State cacheDir: string = ''
  @State text: string = ''
  @State uri:ArrayBuffer|null=null
  @State photoNum:number=1
  @State token:string=''
  context = getContext(this)
  @State displayPhoto:string|null=null
  async aboutToAppear() {

  }

  build() {
    NavDestination() {
      if (this.cacheDir) {
        Column() {
          Text('token: '+this.token)
          Text('缓存目录')
          Text(this.cacheDir)
          Text(this.text)
            .onClick(() => {
              try {
                let file = fs.openSync(this.cacheDir + '/test.txt', fs.OpenMode.READ_ONLY);
                let stat = fs.statSync(this.cacheDir + '/test.txt'); // 获取文件信息

                // 创建缓冲区
                let buffer = new ArrayBuffer(stat.size);
                let readLen = fs.readSync(file.fd, buffer);

                // 转换为字符串
                let decoder = new util.TextDecoder('utf-8');
                let content = decoder.decode(new Uint8Array(buffer));
                this.text = content
                console.info("文件内容：" + content);

                fs.closeSync(file);
              } catch (err) {
                console.error(`读取失败：${err.code}, ${err.message}`);
              }
            })
            .backgroundColor('#777777')
            .height(50)
            .width(300)
          Row(){
            Button('-1')
              .onClick(()=>{
                if (this.photoNum<2) {
                  return
                }this.photoNum--
              })
            Text(this.photoNum.toString())
            Button('+1')
              .onClick(()=>{
              this.photoNum++
            })
          }
          Image(this.displayPhoto)
          Button()
            .onClick(async () => {
              const photoSelectOptions = new picker.PhotoSelectOptions();
              // 过滤选择媒体文件类型为IMAGE
              photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
              // 选择媒体文件的最大数目
              photoSelectOptions.maxSelectNumber = this.photoNum;


              // 二、创建 图片选择对象并选择图片
              const photoViewPicker = new picker.PhotoViewPicker();
              // 调用 select 方法，传入选项对象
              photoViewPicker.select(photoSelectOptions).then(async res => {
                const uri = res.photoUris[0]
                // 因为只选了一张
                AlertDialog.show({ message: '图片路径为:' + uri })
                const context = getContext(this)
                const fileType = 'jpg'
                // 生成一个新的文件名
                const fileName = Date.now() + '.' + fileType
                // 通过缓存路径+文件名 拼接出完整的路径
                const copyFilePath = context.cacheDir + '/' + fileName
                // 将文件 拷贝到 临时目录
                const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
                try {
                  fs.copyFileSync(file.fd, copyFilePath)
                  console.log('复制成功' + copyFilePath)
                } catch (error) {
                  console.log('复制失败' + error)
                }
                const uploadFile: request.File = {
                  uri: InternalPath.CACHE_PATH + fileName,
                  filename: fileName,
                  name: 'file',
                  type: 'image/jpeg'
                }
                const uploadData: request.RequestData = {
                  name: 'puid',
                  value: '295148447'
                }
                let uploadTask: request.UploadTask;
                request.uploadFile(getContext(), {
                  url: 'https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=820fde763f8165c8b5d9b01b23c6af21',
                  header: {
                    cookies: 'JSESSIONID=106C744317547144FC0553B9348FC634; fid=503; _uid=341133751; _d=1758455481685; UID=341133751; vc3=J%2FSIPCvk2V0nAkUxIwio3NvaavNkSouYmTBvN5BFOEglAbmpkXEYDQEy1GxlnocvRv7R8FE1gtx%2F5hivqP%2Fww8ggOAtj7Wga3V8OEIJSjyNrj8I2BtTrijViF%2Bwyd4kfJ7L8orYSf6hlql%2BJJCiv4Zh097GkdMqcclBJ8K1NRPM%3D6438220edbf29a50a71236e20ff81e44; uf=569b376a64ccf0319dbf35210ecb914504d7b071f9e711733dd52efe2465cf6ca92fff0af79bdbd2a95cdc9f68c601265d984d23a7662dfb9b0594e13f4b452fa995cca83579031aa94b593de5d847e4502095057cc7d89360a524d218f637f5803567459b883d8cab3068276bc03ed8557aa5d373ab8c0c35f843e9f6d4931c53cc5d8af3f1757ffe5ac43f21e532d2b9db9b2097fb8763dfd4860a93fcbeead1950c3ed9a2107951b68cdbfc8c1797577a9aa095a87b2c; cx_p_token=ea6c6602bfee880860381a3d5dfd198b; p_auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIzNDExMzM3NTEiLCJsb2dpblRpbWUiOjE3NTg0NTU0ODE2ODcsImV4cCI6MTc1OTA2MDI4MX0.8a4-eEsyIQ71j_ibRbVGk7iJ_BPF0y9ao4NpcPxynaQ; xxtenc=843493dda183a47f7dec765527ad3983; DSSTASH_LOG=C_38-UN_328-US_341133751-T_1758455481687; route=26e346b982eea47de2f6652532e77800'
                  },
                  method: 'POST',
                  files: [uploadFile],
                  data: [uploadData]
                }, (err, data) => {
                  if (err) {
                    console.error(`Failed to request the upload. Code: ${err.code}, message: ${err.message}`);
                    return;
                  }
                  uploadTask = data;
                  uploadTask.on('headerReceive', (data1) => {
                    console.info(`NIMALEGEBI${JSON.stringify(data1?.['body'])}`);
                  })
                })
              })
            })
          Image(this.pixelMap)
            .height(100)
            .width(100)
        }
      }
    }.height('100%')
    .width('100%')
    .title('测试')
    .onAppear(() => {

      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.cacheDir = context.cacheDir; // 示例路径：/data/storage/el2/base/cache/
      try {
        // 使用 OpenMode 组合：读写 + 创建
        let file = fs.openSync(this.cacheDir + '/test.txt', fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

        // 写入内容
        let writeLen = fs.writeSync(file.fd, "Hello HarmonyOS Cache");
        console.info("写入字节数:" + writeLen);

        // 关闭文件
        fs.closeSync(file);
      } catch (err) {
        console.error(`操作失败：${err.code}, ${err.message}`);
      }
    })
  }
}