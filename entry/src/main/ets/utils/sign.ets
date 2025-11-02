
import { ChaoxingUtils } from './utils';
import http from '@ohos.net.http';
import { ChaoXingApi } from './PublicAPI';
import { request } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';

const buildURL = ChaoxingUtils.buildUrl;

// 定义日志标签（便于筛选）
const TAG = 'UploadPhotoService';
const DOMAIN = 0x0000; // 日志域（自定义即可）
export interface UploadPhotoParam {
  '_token': string
}

interface GeneratedTypeLiteralInterface_1 {
  objectId?: string;
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
    console.log('DoSignInURL: ',url,'\nCookies: ',cookies)
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
  static async ifPhoto(cookies: string ,activeId: string): Promise<boolean> {
    const httpRequest = http.createHttp()
    const url = ChaoXingApi.URL_IF_PHOTO.buildUrl({'activeId':activeId}).toString()
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies,
          "User-Agent": ChaoXingApi.UA
        }
      })
      const JsonResult = JSON.parse(result.result.toString()) as object
      return JsonResult?.['data']?.['ifphoto'] as boolean
    } finally {
      httpRequest.destroy()
    }
  }

  static async GetToken(cookies: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const result = await httpRequest.request(ChaoXingApi.URL_GET_TOKEN, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies
        }
      })
      const tokenobj: string = result.result.toString()
      console.log('ffffff'+tokenobj)
      const token:string = (JSON.parse(tokenobj) as object)?.['_token'] as string
      hilog.info(DOMAIN, TAG, `token obtained: ${token ? 'success' : 'failed'}`);
      return token
    } catch (e) {
      const errorMsg = `GetToken failed: ${e instanceof Error ? e.message : String(e)}`;
      hilog.error(DOMAIN, TAG, errorMsg);
      return errorMsg
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
  static async PreSignIn(activePrimaryId: string, classId: string, courseId: string, uid: number,
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
    console.log('fuck999'+ChaoXingApi.URL_PRE_SIGN.buildUrl({
      activePrimaryId: activePrimaryId,
      classId: classId,
      courseId: courseId,
      uid: uid
    }).toString())
    if (result.responseCode === 302 || (result.result as string).includes("校验失败，未查询到活动数据")) {
      return -1
    }
    if ((result.result as string).includes('<p class="signtime">')) {
      return 0
    }
    return 1
  }
}