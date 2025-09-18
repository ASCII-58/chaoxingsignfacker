// 1. 定义 BuildableUrl 类
class BuildableUrl {
  constructor(public readonly url: string) {
  }

  buildUrl(params?: Record<string, any>): string {
    if (!params) {
      return this.url;
    }

    const parts = Object.entries(params)
      .filter(([_, value]) => value !== undefined && value !== null)
      .map(([key, value]) => {
        return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`;
      });

    const queryString = parts.join('&');
    if (queryString === '') {
      return this.url;
    }

    const separator = this.url.includes('?') ? '&' : '?';
    return `${this.url}${separator}${queryString}`;
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
export class ChaoXingApi {
  /**
   * 正式签到基础URL
   */
  static readonly URL_SIGN =
    'https://mobilelearn.chaoxing.com/pptSign/stuSignajax?&clientip=&appType=15&ifTiJiao=1&vpProbability=-1&=';
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
  /**
   * 登录
  */
  static readonly URL_LOGIN = "https://passport2.chaoxing.com/fanyalogin"
  static readonly UA =
    "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0"
  static readonly URL_GET_USER_INFO = "https://sso.chaoxing.com/apis/login/userLogin4Uname.do"
}

// 4. 使用示例
console.log('--- 使用 buildUrl ---');
const signedUrl = ChaoXingApi.URL_PRE_SIGN.buildUrl({ activeId: 'abc123', uid: '98765' });
console.log(signedUrl);

const uploadUrl = ChaoXingApi.URL_UPLOAD_PHOTO.buildUrl({ name: 'test.pdf', size: 2048 });
console.log(uploadUrl);

console.log('\n--- 当作字符串使用 ---');
console.log(`Base URL: ${ChaoXingApi.URL_UPLOAD_PHOTO}`);
console.log(JSON.stringify({ url: ChaoXingApi.URL_GET_TOKEN }));
