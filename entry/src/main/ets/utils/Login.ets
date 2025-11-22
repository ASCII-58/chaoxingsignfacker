import { image } from '@kit.ImageKit';
import http from '@ohos.net.http';
import { ChaoxingUtils } from './utils';
import { JSON, url } from '@kit.ArkTS';
import { ChaoXingApi } from './PublicAPI';
import { DatabaseManager } from './DataBase';
import { common, StartupTask } from '@kit.AbilityKit';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import urlTools from './urlTools'

const TAG = 'LoginService';
const DOMAIN = 0x0001;
export interface UserInfo {
  msg: string,
  uname: string,
  pic: string,
  uid: number,
  fid: string,
  puid:string
}

export class loginFunction {
  /**
   * 登录学习通，获取set-cookie
   * @param {string} LoginString 需要加密的消息
   * @returns {Promise<string>} 求到的cookie,异常为空
   */
  static async LoginChaoXing(LoginString: string): Promise<string> {
    hilog.debug(DOMAIN, TAG, 'Attempting login');
    const httpRequest = http.createHttp();
    const url = ChaoXingApi.URL_LOGIN;
    const PostBody = LoginString;
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        extraData: PostBody,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest'
        },
        connectTimeout: 60000,
        readTimeout: 60000,
      });
      // 处理响应
      if (result.responseCode === 200) {
        const ResultBody = JSON.parse(result.result.toString()) as object;
        hilog.debug(DOMAIN, TAG, `Login response status: ${ResultBody?.['status']}`);
        if (ResultBody?.['status'] === true) {
          const set_cookies: string[] = result.header['set-cookie']
          hilog.info(DOMAIN, TAG, 'Login successful');
          return ChaoxingUtils.processSetCookieHeaders(set_cookies);
        } else {
          hilog.error(DOMAIN, TAG, 'Login failed: Invalid username or password');
          return ""
        }
      } else {
        hilog.error(DOMAIN, TAG, `Login failed: Network error (${result.responseCode})`);
        return ""
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Login exception: ${error.message}`);
      if (error.message === 'Number of redirects hit maximum amount') {
        return "服务器错误，请稍后重试"
      }
      return ""
    } finally {
      // 无论成功或失败，都必须销毁请求对象
      httpRequest.destroy();
    }
  }

  /**
   * 获取用户的用户名和头像
   * @param {string} cookies 用户对应的cookie
   * @returns {Promise<UserInfo>} msg : 请求是否成功, uname: 用户名, pic: 头像url地址, uid: 用户uid, fid: 学校id
   */
  static async getUserInfo(cookies: string): Promise<UserInfo> {
    const httpRequest = http.createHttp();
    const url = ChaoXingApi.URL_GET_USER_INFO
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies
        }
      })
      if (result.responseCode >= 300 || result.responseCode < 200) {
        hilog.error(DOMAIN, TAG, `Get user info failed: Server error (${result.responseCode})`);
        return {
          'msg': 'service error',
          'uname': '',
          'pic': '',
          'uid': 0,
          'fid': '',
          'puid':''
        }
      } else {
        const JsonResult = JSON.parse(result.result as string) as object;
        const Json = (JsonResult as object)?.['msg'] as object
        const uname: string = (Json as object)?.['name'] || ''
        const pic: string = (Json as object)?.['pic'] || ''
        const uid: number = (Json as object)?.['uid'] || 0
        const fid: string = (Json as object)?.['fid'] || 0
        const puid: string = (Json as object)?.['puid'] || 0
        return {
          'msg': (uname && pic) ? 'successful' : 'fetch error',
          'uname': uname,
          'pic': pic,
          'uid': uid,
          'fid': fid,
          'puid':puid
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get user info failed: ${error.message}`);
      return {
        'msg': 'service error',
        'uname': '',
        'pic': '',
        uid: 0,
        fid: '',
        puid:''
      }
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 通过url添加其他用户
   * @param stringURL
   */
  static async LoginByURL(stringURL: string): Promise<string> {
    try {
      let urlParse = urlTools.parseUrlParams(stringURL)
      let phone = urlParse['phone']
      let pwd = urlParse['pwd']
      hilog.debug(DOMAIN, TAG, `Parsing login URL for phone: ${phone?.substring(0, 3)}***`);
      let AESPhone = ChaoxingUtils.encryptByAES(phone)
      let body = ChaoxingUtils.getLoginBody(AESPhone, pwd);
      let cookie = await loginFunction.LoginChaoXing(body)
      let userInfo = await loginFunction.getUserInfo(cookie)
      const dbManager = DatabaseManager.getInstance()
      if (await dbManager.insertUser({
          phone: phone,
          pwd: pwd,
          uid: userInfo.uid,
          cookies: cookie
        }) === 1
      ) {
        hilog.info(DOMAIN, TAG, 'User added successfully via URL');
        return '添加成功'
      } else {
        hilog.error(DOMAIN, TAG, 'Failed to add user: Invalid credentials or already logged in');
        return '链接的手机号或密码有误或已经登录'
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Login by URL failed: ${error.message}`);
      return '请使用正确的url'
    }
  }

  /**
   * 获取图片数据
   * @param {string} url 头像url
   * @returns {Promise<image.PixelMap>} 头像数据
   * */
  static async GetPic(url: string): Promise<image.PixelMap | null> {
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: { 'User-Agent':ChaoXingApi.UA },
        readTimeout: 60000, // 读取超时时间（毫秒）
        connectTimeout: 60000 // 连接超时时间（毫秒）
      })

      if (result.responseCode === 200) {
        const RawData = result.result as ArrayBuffer

        // 创建图像源
        let imageSource = image.createImageSource(RawData);
        // 创建PixelMap
        let pixelMap: image.PixelMap = await imageSource.createPixelMap();
        return pixelMap
      } else {
        hilog.error(DOMAIN, TAG, `Failed to fetch image: ${result.responseCode}`);
        return null
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error fetching image: ${error.message}`);
      return null
    }
    finally {
      httpRequest.destroy()
    }
  }
}
