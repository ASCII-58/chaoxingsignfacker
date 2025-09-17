/**
 * 超星平台加解密工具
 * 基于超星登录系统的加密方式实现
 */

// 使用 import 语法引入 CryptoJS
import * as CryptoJSModule from '../../../../node_modules/crypto-js';
// 使用另一个变量名避免与全局类型冲突
const CryptoJS = CryptoJSModule;
/**
 * 拼接 URL 参数
 * @param {string} url - 基础 URL
 * @param {Object} params - 要拼接的参数对象
 * @returns {string} 拼接后的 URL
 */

export class ChaoxingUtils {
  static buildUrl(url: string, params?: object): string {
    if (params === undefined) {
      return url
    }
    const parts = Object.entries(params).map(([key, value]) => {
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
    });

    const queryString = parts.join('&');

    // 判断是否已有参数
    const separator = url.includes('?') ? '&' : '?';
    return `${url}${separator}${queryString}`;
  }

  /**
   * 生成UUIDv4
   * @returns {string}
   */

  static generateUUIDv4(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }


  /**
   * 超星默认使用的AES密钥
   */
  static readonly DEFAULT_KEY = 'u2oh6Vu^HWe4_AES';

  /**
   * AES-CBC模式加密 - 确保与超星实现一致的方式
   * @param {string} message 需要加密的消息
   * @returns {string} 加密后的Base64字符串
   */

  static encryptByAES(message: string): string {
    // 超星的具体实现方式 - 从login.js和util.js中提取
    const key: string = ChaoxingUtils.DEFAULT_KEY
    const CBCOptions = {
      iv: CryptoJS.enc.Utf8.parse(key),
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7,
    };
    const aeskey = CryptoJS.enc.Utf8.parse(key);
    // 超星实现中字符串直接使用UTF8编码，无需特别处理
    const secretData = CryptoJS.enc.Utf8.parse(message);
    const encrypted = CryptoJS.AES.encrypt(secretData, aeskey, CBCOptions);
    return CryptoJS.enc.Base64.stringify(encrypted.ciphertext);
  }

  /**
   * 生成超星登录字符串
   * @param {string} username 加密后的用户名
   * @param {string} password 加密后的密码
   * @returns {string} 格式化的登录字符串
   */

  static getLoginBody(username: string, password: string): string {

    // URL编码加密后的用户名和密码
    const encodedUsername = encodeURIComponent(username);
    const encodedPassword = encodeURIComponent(password);

    // 构造完整的登录字符串
    return `fid=-1&uname=${encodedUsername}&password=${encodedPassword}&refer=https%253A%252F%252Fmooc2-ans.chaoxing.com%252Fmooc2-ans%252Fvisit%252Finteraction&t=true&forbidotherlogin=0&validate=&doubleFactorLogin=0&independentId=0&independentNameId=0`;
  }

  /**
   * 将 Set-Cookie 响应头列表处理成可用于请求的 Cookie 字符串
   * @param setCookieHeaders - 服务器返回的 Set-Cookie 头部字符串数组
   * @returns 处理后的 Cookie 字符串，格式为 "name1=value1; name2=value2"
   */
  static processSetCookieHeaders(setCookieHeaders: string[]): string {
    if (!Array.isArray(setCookieHeaders) || setCookieHeaders.length === 0) {
      return '';
    }

    return setCookieHeaders
      .map(cookie => cookie.split(';')[0].trim()) // 提取每个 Set-Cookie 的 name=value
      .join('; ');
  }
}