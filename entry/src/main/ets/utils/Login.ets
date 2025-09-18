import { image } from '@kit.ImageKit';
import http from '@ohos.net.http';
import { ChaoxingUtils } from './utils';
import { JSON } from '@kit.ArkTS';

export interface UserInfo {
  msg: string,
  uname: string,
  pic: string,
  uid: number,
  fid: number
}

export class loginFunction {
  /**
   * 登录学习通，获取set-cookie
   * @param {string} LoginString 需要加密的消息
   * @returns {Promise<returnData>} msg : 请求是否成功, cookies: 请求到的cookie
   */
  static async LoginChaoXing(LoginString: string): Promise<string> {
    console.log('fuck' + LoginString)
    const httpRequest = http.createHttp();
    const url = "https://passport2.chaoxing.com/fanyalogin";
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
        console.log(ResultBody?.['status'] + 'fuck')
        if (ResultBody?.['status'] === true) {
          const set_cookies: string[] = result.header['set-cookie']
          console.log('shit登录成功')
          return ChaoxingUtils.processSetCookieHeaders(set_cookies);
        } else {
          console.error('fuck' + JSON.stringify(result.result))
          console.error('fuck用户名或密码错误')
          return ""
        }
      } else {
        console.error('fuck网络错误')
        return ""
      }
    } catch (error) {
      console.error(error)
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
    const url = "https://sso.chaoxing.com/apis/login/userLogin4Uname.do"
    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies
        }
      })
      if (result.responseCode >= 300 && result.responseCode < 200) {
        console.error('fuck,服务器错误')
        return {
          'msg': 'service error',
          'uname': '',
          'pic': '',
          uid: 0,
          fid: 0
        }
      } else {
        const JsonResult = JSON.parse(result.result as string) as object;
        const Json = (JsonResult as object)?.['msg'] as object
        const uname: string = (Json as object)?.['name'] || ''
        const pic: string = (Json as object)?.['pic'] || ''
        const uid: number = (Json as object)?.['uid'] || 0
        const fid: number = (Json as object)?.['fid'] || 0
        return {
          'msg': (uname && pic) ? 'successful' : 'fetch error',
          'uname': uname,
          'pic': pic,
          'uid': uid,
          'fid': fid
        }
      }
    } catch (error) {
      console.error('fuck,网络错误:', error);
      return {
        'msg': 'service error',
        'uname': '',
        'pic': '',
        uid: 0,
        fid: 0
      }
    } finally {
      httpRequest.destroy()
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
        header: {
          "User-Agent": "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0"
        },
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
        console.error('fuck获取失败')
        return null
      }
    } catch (error) {
      console.error('fuck' + error)
      return null
    }
  }
}