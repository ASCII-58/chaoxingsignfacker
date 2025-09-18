// export interface
import { ChaoxingUtils } from './utils';
import http from '@ohos.net.http';
import { ChaoXingApi } from './ChaoxingAPI';
import { request } from '@kit.BasicServicesKit';

const buildURL = ChaoxingUtils.buildUrl;

export interface UploadPhotoParam {
  '_token': string
}

export class Sign {
  static readonly URL_PRE_SIGN =
    'https://mobilelearn.chaoxing.com/newsign/preSign?&general=1&sys=1&ls=1&appType=15&isTeacherViewOpen=0'
  static readonly URL_BASIC_SIGN =
    'https://mobilelearn.chaoxing.com/pptSign/stuSignajax?&clientip=&appType=15&ifTiJiao=1&vpProbability=-1&='

  static async DoPreSignIn(activePrimaryId: number, classId: number, courseId: number) {
    const httpRequest = http.createHttp()
    const URL = ChaoXingApi.URL_PRE_SIGN
      .buildUrl({
        'activePrimaryId': activePrimaryId,
        'classId': classId,
        'courseId': courseId
      })
  }

  static async UploadPhoto(context: Context, param: UploadPhotoParam, cookies: string, files: Array<request.File>,
    uid: number): Promise<string> {
    const token = Sign.GetToken(cookies)
    return await request.uploadFile(context, {
      url: ChaoXingApi.URL_UPLOAD_PHOTO
        .buildUrl({ '_token': token }),
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

  static async GetToken(cookies: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const result = await httpRequest.request(ChaoXingApi.URL_GET_TOKEN, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies,
          "User-Agent": ChaoXingApi.UA
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