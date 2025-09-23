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
  static async DoPreSignIn(activePrimaryId: number, classId: number, courseId: number, cookies: string) {
    const httpRequest = http.createHttp()
    const URL = ChaoXingApi.URL_PRE_SIGN
      .buildUrl({
        'activePrimaryId': activePrimaryId,
        'classId': classId,
        'courseId': courseId
      })
      .toString()
    const result = await httpRequest.request(URL, {
      method: http.RequestMethod.GET,
      header: {
        "Cookie": cookies,
        "User-Agent": ChaoXingApi.UA
      }
    })
    const isSign: boolean = (result.result as string).includes('<p class="signtime">')
    return isSign
  }

  static async DoSignIn(cookies: string, queryParams: object) {
    const url = ChaoXingApi.URL_SIGN.buildUrl(queryParams).toString()
    const httpRequest = http.createHttp()
    const result = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        "Cookie": cookies,
        "User-Agent": ChaoXingApi.UA
      }
    })
    return result.result.toString()
  }

  static async UploadPhoto(context: Context, cookies: string, files: Array<request.File>,
    uid: number): Promise<string> {
    const token = Sign.GetToken(cookies)
    return await request.uploadFile(context, {
      url: ChaoXingApi.URL_UPLOAD_PHOTO
        .buildUrl({ '_token': token })
        .toString(),
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
/**
 *
 * @param activePrimaryId
 * @param classId
 * @param courseId
 * @param uid
 * @param cookies
 * @returns -1 = 无权限 | 0 = 已签到 | 1 = 可签到
 */
  static async PreSignIn(activePrimaryId: number, classId: number, courseId: number, uid: number,
    cookies: string): Promise<number> {
    const httpRequest = http.createHttp()
    const result = await httpRequest.request(ChaoXingApi.URL_PRE_SIGN.buildUrl({
      activePrimaryId: activePrimaryId,
      classId: classId,
      courseId: courseId,
      uid: uid
    }).toString(), {
      method: http.RequestMethod.GET,
      header: {
        "Cookie": cookies,
        "User-Agent": ChaoXingApi.UA
      }
    })
    if (result.responseCode === 302 || (result.result as string).includes("校验失败，未查询到活动数据")) {
      return -1
    }
    if ((result.result as string).includes('<p class="signtime">')) {
      return 0
    }
    return 1
  }
}