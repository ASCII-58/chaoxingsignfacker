// export interface
import { ChaoxingUtils } from './utils';
import http from '@ohos.net.http';
import { ChaoXingApi } from './ChaoxingAPI';
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
  static async ifPhoto(cookies: string ,activeId: number): Promise<boolean> {
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

  static async UploadPhoto(
    context: Context,
    cookies: string,
    files: Array<request.File>,
    uid: number
  ): Promise<string> {
    try {
      // 1. 校验入参
      if (!context) {
        const errorMsg = 'context is null or undefined';
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }
      if (!cookies) {
        const errorMsg = 'cookies is empty';
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }
      if (!files || files.length === 0) {
        const errorMsg = 'files is empty or undefined';
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }
      if (uid <= 0) {
        const errorMsg = `invalid uid: ${uid}`;
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }

      // 2. 获取 token
      let token: string;
      try {
        token = await Sign.GetToken(cookies);
        if (!token) {
          const errorMsg = 'failed to get token (token is empty)';
          hilog.error(DOMAIN, TAG, errorMsg);
          throw new Error(errorMsg);
        }
        hilog.info(DOMAIN, TAG, `successfully got token for uid: ${uid}`);
      } catch (err) {
        const errorMsg = `failed to get token: ${err instanceof Error ? err.message : String(err)}`;
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg); // 向上抛出，让调用方感知
      }

      // 3. 构建上传 URL
      let uploadUrl: string;
      try {
        uploadUrl = ChaoXingApi.URL_UPLOAD_PHOTO.buildUrl({ '_token': token }).toString();
        hilog.info(DOMAIN, TAG, `upload url built: ${uploadUrl}`);
      } catch (err) {
        const errorMsg = `failed to build upload url: ${err instanceof Error ? err.message : String(err)}`;
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }

      // 4. 执行上传
      try {
        const uploadTask = await request.uploadFile(context, {
          url: uploadUrl,
          method: http.RequestMethod.POST,
          header: {
            'content-type': 'multipart/form-data', // 修正为小写规范
          },
          files,
          data: [{ name: 'puid', value: uid.toString() }]
        });

        // 监听上传响应
        return new Promise((resolve, reject) => {
          uploadTask.on('headerReceive', (headers) => {
            try {
              // 解析响应体（注意：headerReceive 可能不包含 body，根据实际接口调整）
              const body = headers?.['body'] as string;
              if (!body) {
                const errorMsg = 'upload response body is empty';
                hilog.error(DOMAIN, TAG, errorMsg);
                reject(new Error(errorMsg));
                return;
              }

              const response = JSON.parse(body) as GeneratedTypeLiteralInterface_1;
              if (!response.objectId) {
                const errorMsg = `upload success but no objectId: ${body}`;
                hilog.error(DOMAIN, TAG, errorMsg);
                reject(new Error(errorMsg));
                return;
              }

              hilog.info(DOMAIN, TAG, `photo uploaded successfully, objectId: ${response.objectId}, uid: ${uid}`);
              resolve(response.objectId);
            } catch (err) {
              const errorMsg = `failed to parse upload response: ${err instanceof Error ? err.message : String(err)}, response: ${headers?.['body']}`;
              hilog.error(DOMAIN, TAG, errorMsg);
              reject(new Error(errorMsg));
            }
          });

          // 监听上传失败
          uploadTask.on('fail', (err) => {
            const errorMsg = `upload task failed: ${err instanceof Error ? err.message : String(err)}, uid: ${uid}`;
            hilog.error(DOMAIN, TAG, errorMsg);
            reject(new Error(errorMsg));
          });
        });
      } catch (err) {
        const errorMsg = `uploadFile init failed: ${err instanceof Error ? err.message : String(err)}, uid: ${uid}`;
        hilog.error(DOMAIN, TAG, errorMsg);
        throw new Error(errorMsg);
      }
    } catch (err) {
      // 捕获所有未处理的错误，统一记录并抛出
      const errorMsg = `UploadPhoto failed: ${err instanceof Error ? err.message : String(err)}`;
      hilog.error(DOMAIN, TAG, errorMsg);
      throw new Error(errorMsg); // 确保调用方能捕获到错误
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
      const token: string = (JSON.parse(result.result.toString()) as object)?.['_token']
      console.log('fuck'+token)
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