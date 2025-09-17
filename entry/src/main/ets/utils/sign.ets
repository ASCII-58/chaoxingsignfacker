// export interface
import { ChaoxingUtils } from './utils';
import http from '@ohos.net.http';
import { request } from '@kit.BasicServicesKit';

const buildURL = ChaoxingUtils.buildUrl;

export interface UploadPhotoParam {
  '_token': string
}

export class Sign {
  static readonly URL_BASIC_SIGN =
    'https://mobilelearn.chaoxing.com/pptSign/stuSignajax?&clientip=&appType=15&ifTiJiao=1&vpProbability=-1&='
  static readonly URL_UPLOAD_PHOTO = 'https://pan-yz.chaoxing.com/upload?_from=mobilelearn'
  static readonly URL_GET_TOKEN = 'https://pan-yz.chaoxing.com/api/token/uservalid'

  public async UploadPhoto(context: Context, param: UploadPhotoParam, cookies: string, files: Array<request.File>,
    uid: number): Promise<string> {
    buildURL(Sign.URL_UPLOAD_PHOTO, param)
    return await request.uploadFile(context, {
      url: `https://pan-yz.chaoxing.com/upload?_from=mobilelearn&_token=${this.GetToken(cookies)}`,
      method: http.RequestMethod.POST,
      header: {
        // 和接口文档的要求的格式对象
        contentType: 'multipart/form-data',
      },
      files,
      data: [{ name: 'puid', value: uid.toString() }] // 额外提交的数据，不能省略
    })
      .then((res => {
        // 这里可以获取到响应的内容
        res.on('headerReceive', (value) => {
          return (JSON.parse(value?.['body'] as string) as object)?.['objectId'] as string
        })
      })) as string


  }

  private async GetToken(cookies: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const result = await httpRequest.request(Sign.URL_GET_TOKEN, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies,
          "User-Agent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0'
        }
      })
      const token: string = (result.result as object)?.['_token']
      return token
    } catch (e) {
      console.error(e.toString())
      throw new Error(e)
    } finally {
      httpRequest.destroy()
    }
  }
}