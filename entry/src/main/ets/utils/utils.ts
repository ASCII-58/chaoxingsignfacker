/**
 * 超星平台加解密工具
 * 基于超星登录系统的加密方式实现
 */

// 使用 import 语法引入 CryptoJS
import CryptoJS from '@ohos/crypto-js'
// import * as CryptoJSModule from '../../../../node_modules/crypto-js';
// // 使用另一个变量名避免与全局类型冲突
// const CryptoJS = CryptoJSModule;
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
   * 生成图片名，长度为12, 无后缀
   * @returns {string}
   */

  static generatePhotoName(): string {
    return 'xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * 坐标转换工具模块
   * 提供GCJ-02（国测局坐标系）到BD-09（百度坐标系）的转换功能
   *
   * 背景说明：
   * - GCJ-02坐标系是由中国国家测绘局制定的坐标系统，所有在中国使用的地图产品都必须使用这个坐标系
   * - BD-09坐标系是百度地图使用的坐标系，在GCJ-02的基础上进行了进一步的偏移
   * - 这些坐标系的偏移是为了解决地图数据的精度控制问题，属于中国特色的地理信息处理技术
   */

  // 定义坐标转换中使用的常量
  // 这个常量是π(3.14159265358979324)乘以3000/180，用于经纬度的弧度转换
  static readonly x_pi: number = 3.14159265358979324 * 3000.0 / 180.0;

  /**
   * 将GCJ-02坐标系（火星坐标系）转换为BD-09坐标系（百度坐标系）
   *
   * 算法原理：
   * 该算法通过极坐标变换的方式，在GCJ-02坐标的基础上添加特定的偏移量，
   * 将坐标转换为百度地图使用的BD-09坐标系。
   *
   * @param gg_lat GCJ-02坐标系的纬度值，单位为度
   * @param gg_lon GCJ-02坐标系的经度值，单位为度
   * @returns 转换后的BD-09坐标系坐标，包含纬度(lat)和经度(lon)的对象
   *
   * @example
  * // 转换北京天安门附近的坐标示例
   * const result = gcj02_to_bd09(39.9042, 116.4074);
   * console.log(result); // 输出类似: { lat: 39.9107, lon: 116.4155 }
   */
  static gcj02_to_bd09(gg_lat: number, gg_lon: number): { lat: number, lon: number } {
    // 将经度和纬度分别赋值给临时变量x和y
    // 注意这里使用的是传统的数学坐标表示法，x表示经度，y表示纬度
    const x = gg_lon;
    const y = gg_lat;

    // 计算z值：在原有距离基础上加上一个微小的修正量
    // 这个修正式使用正弦函数，根据纬度产生不同的偏移量
    const z = Math.sqrt(x * x + y * y) + 0.00002 * Math.sin(y * ChaoxingUtils.x_pi);

    // 计算theta值：在原有角度基础上加上一个微小的修正量
    // 这个修正式使用余弦函数，根据经度产生不同的偏移量
    // atan2(y, x)计算的是点(x,y)与原点连线与x轴正方向的夹角
    const theta = Math.atan2(y, x) + 0.000003 * Math.cos(x * ChaoxingUtils.x_pi);

    // 计算转换后的BD-09坐标系经度
    // 使用极坐标转直角坐标的公式，最后加上固定偏移量0.0065
    const bd_lon = z * Math.cos(theta) + 0.0065;

    // 计算转换后的BD-09坐标系纬度
    // 使用极坐标转直角坐标的公式，最后加上固定偏移量0.006
    const bd_lat = z * Math.sin(theta) + 0.006;

    // 返回包含转换后经纬度的对象
    // 按照地图坐标的习惯，先返回纬度，再返回经度
    return { lat: bd_lat, lon: bd_lon };
  }

  static hasHole(arr: any[]): boolean {
    for (let i = 0; i < arr.length; i++) {
      if (!(i in arr)) {
        return true; // 存在空槽
      }
    }
    return false;
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
  /**
   * 获取签到活动剩余时间（毫秒）
   */
  static getRemainingTime(endTime: number): number {
    const currentTime = Date.now();
    return Math.max(0, endTime - currentTime);
  }
  /**
   * 检查签到活动是否正在进行中
   */
  static isSignActivityActive(startTime: number, endTime: number): boolean {
    const currentTime = Date.now();
    return currentTime >= startTime && currentTime <= endTime;
  }

  /**
   * 检查签到活动是否已开始
   */
  static isSignActivityStarted(startTime: number): boolean {
    const currentTime = Date.now();
    return currentTime >= startTime;
  }

  /**
   * 检查签到活动是否已结束
   */
  static isSignActivityEnded(endTime: number): boolean {
    const currentTime = Date.now();
    return currentTime > endTime;
  }
}
