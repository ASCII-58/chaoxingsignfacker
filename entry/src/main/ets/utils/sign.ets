import { ChaoxingUtils } from './utils';
import http from '@ohos.net.http';
import { ChaoXingApi } from './PublicAPI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import CryptoJS from '@ohos/crypto-js';
import { systemDateTime } from '@kit.BasicServicesKit';

const buildURL = ChaoxingUtils.buildUrl;

// 定义日志标签（便于筛选）
const TAG = 'UploadPhotoService';
const DOMAIN = 0x0000; // 日志域（自定义即可）
export interface UploadPhotoParam {
  '_token': string
}

export interface CaptchaConf {
  t?: number;
  error?: number;
}

export interface CaptchaPhotosParam {
  courseId: string;
  classId: string;
  activePrimaryId: string;
  uid: string;
}

export interface CaptchaPhotosResult {
  'token': string;
  'imageVerificationVo': twoImg
}

export interface twoImg {
  'shadeImage': string;
  'cutoutImage': string;
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
        "Cookie": cookies
      }
    })
    const isSign: boolean = (result.result as string).includes('<p class="signtime">')
    return isSign
  }

  static async DoSignIn(cookies: string, queryParams: object, NeedDeviceCode: boolean = false) {
    const url = ChaoXingApi.URL_SIGN.buildUrl(queryParams).buildUrl({
      deviceCode: NeedDeviceCode ? ChaoxingUtils.generateUUIDv4() : ''
    }).toString()
    console.log('DoSignInURL: ', url, '\nCookies: ', cookies)
    const httpRequest = http.createHttp()
    const result = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        "Cookie": cookies
      }
    })
    return result.result.toString()
  }

  static async GetLocationSignInfo(cookies: string, activeId: string): Promise<string> {
    const httpRequest = http.createHttp()
    const url = ChaoXingApi.URL_GET_LOCATION_SIGN_INFO.buildUrl({ 'activeId': activeId }).toString()
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {"Cookie":cookies}
      })
      const body = JSON.parse(result.result as string) as object
      return body?.['data']?.['locationText'] as string
    }catch (e){
      console.log(e)
      return ''
    }finally {
      httpRequest.destroy()
    }
  }

  static async ifPhoto(cookies: string, activeId: string): Promise<boolean> {
    const httpRequest = http.createHttp()
    const url = ChaoXingApi.URL_IF_PHOTO.buildUrl({ 'activeId': activeId }).toString()
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies
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
      console.log('ffffff' + tokenobj)
      const token: string = (JSON.parse(tokenobj) as object)?.['_token'] as string
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
        "Cookie": cookies
      }
    })
    console.log('fuck999' + ChaoXingApi.URL_PRE_SIGN.buildUrl({
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

  static async getCaptchaConf(): Promise<number> {
    const httpRequest = http.createHttp()
    const result = await httpRequest.request(ChaoXingApi.URL_GET_CAPTCHA_CONF.buildUrl({
      'captchaId': ChaoXingApi.CAPTCHA_ID
    }).toString(), {
      method: http.RequestMethod.GET,
      header: undefined
    })
    const config =
      JSON.parse(result.result.toString().replace("cx_captcha_function(", "").replace(")", "")) as CaptchaConf
    return config.t as number
  }

  static async getCaptchaPhotos(Param: CaptchaPhotosParam, cookies: string): Promise<CaptchaPhotosResult> {
    const t = await Sign.getCaptchaConf()
    const type = 'slide'
    const captchaKey = CryptoJS.MD5(t.toString() + ChaoxingUtils.generateUUIDv4()).toString()
    const iv =
      CryptoJS.MD5(ChaoXingApi.CAPTCHA_ID + type + systemDateTime.getTime() + ChaoxingUtils.generateUUIDv4()).toString()
    const token = CryptoJS.MD5(t.toString() + ChaoXingApi.CAPTCHA_ID + type + captchaKey) + `:${t + 300000}`

    const referer = ChaoXingApi.URL_PRE_SIGN.buildUrl(Param).toString()
    let url = ChaoXingApi.URL_GET_CAPTCHA_PHOTOS.buildUrl({
      "callback": "cx_captcha_function",
      "captchaId": ChaoXingApi.CAPTCHA_ID,
      "type": type,
      "version": "1.1.20",
      "captchaKey": captchaKey,
      "token": token,
      "iv": iv,
      "_": systemDateTime.getTime().toString(),
      "referer": referer
    }).toString()
    const httpRequest = http.createHttp()
    const result = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        "referer": referer,
        cookie: cookies
      }
    })
    const jsonRes =
      JSON.parse(result.result.toString().replace("cx_captcha_function(", "").replace(")", "")) as CaptchaPhotosResult
    return jsonRes
  }
}