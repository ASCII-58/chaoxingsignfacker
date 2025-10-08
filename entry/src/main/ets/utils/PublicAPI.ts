// 1. 定义 BuildableUrl 类
class BuildableUrl {
  constructor(public readonly url: string) {
  }

  buildUrl(params?: Record<string, any>): BuildableUrl {
    if (!params) {
      return this;
    }

    const parts = Object.entries(params)
      .filter(([_, value]) => value !== undefined && value !== null)
      .map(([key, value]) => {
        return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`;
      });

    const queryString = parts.join('&');
    if (queryString === '') {
      return this;
    }

    const separator = this.url.includes('?') ? '&' : '?';
    const newUrl = `${this.url}${separator}${queryString}`
    return new BuildableUrl(newUrl);
  }

  toString() {
    return this.url;
  }

  toJSON() {
    return this.url;
  }

  valueOf() {
    return this.url;
  }
}

// 2. 类型扩展（让 TS 不报错）
declare global {
  interface String {
    buildUrl?(params?: Record<string, any>): string;
  }
}

// 3. 定义 API 常量
/**
 * 超星通用接口
 */
export class ChaoXingApi {
  /**
   * 正式签到基础URL
   */
  static readonly URL_SIGN = new BuildableUrl(
    'https://mobilelearn.chaoxing.com/pptSign/stuSignajax?&clientip=&appType=15&ifTiJiao=1&vpProbability=-1');
  /**
   * 预签到基础URL
   */
  static readonly URL_PRE_SIGN = new BuildableUrl(
    'https://mobilelearn.chaoxing.com/newsign/preSign?&general=1&sys=1&ls=1&appType=15&isTeacherViewOpen=0'
  );
  static readonly URL_GET_ACTIVITY_LIST =
    'https://mobilelearn.chaoxing.com/v2/apis/active/student/activelist?fid=0&showNotStartedActive=0'
  static readonly URL_GET_COURSE_LIST = 'https://mooc1-api.chaoxing.com/mycourse/backclazzdata?view=json&rss=1'
  static readonly URL_UPLOAD_PHOTO = new BuildableUrl(
    'https://pan-yz.chaoxing.com/upload?_from=mobilelearn'
  );
  /**
   * 获取图片上传所需的token
   */
  static readonly URL_GET_TOKEN = 'https://pan-yz.chaoxing.com/api/token/uservalid';

  static readonly URL_IF_PHOTO = new BuildableUrl('https://mobilelearn.chaoxing.com/v2/apis/active/getPPTActiveInfo?')
  /**
   * 登录
   */
  static readonly URL_LOGIN = "https://passport2.chaoxing.com/fanyalogin"
  static readonly UA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0\n" +
      "sec-ch-ua: \"Microsoft Edge\";v=\"141\", \"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"141\""
  static readonly URL_GET_USER_INFO = "https://sso.chaoxing.com/apis/login/userLogin4Uname.do"
}

export class InternalPath {
  /**
   * 同context.cacheDir
   */
  static readonly CACHE_PATH='internal://cache/'
}