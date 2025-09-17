import { http } from '@kit.NetworkKit';

export class CourseAndActivity {
  static readonly URL_GET_COURSE_LIST = 'mooc1-api.chaoxing.com/mycourse/backclazzdata?view=json&rss=1'
  static readonly URL_GET_ACTIVITY_LIST =
    'https://mobilelearn.chaoxing.com/v2/apis/active/student/activelist?fid=0&showNotStartedActive=0'

  /**
   * 获取课程列表，需要cookies
   * @param cookies
   * @returns
   */
  static async getClassList(cookies: string): Promise<classInfoType[]> {
    const BASIC_URL: string = 'mooc1-api.chaoxing.com/mycourse/backclazzdata?view=json&rss=1'
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request(BASIC_URL, {
        method: http.RequestMethod.GET,
        header: {
          "Cookie": cookies,
          "User-Agent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0'
        }
      })
      const CourseListResponse = JSON.parse(result.result.toString()) as object
      if (CourseListResponse?.['msg'] === "获取成功") {
        const courseList = CourseListResponse?.['channelList'] as CourseChannel[]
        const result: classInfoType[] = [];

        courseList.forEach(item => {
          // 检查 content 和 course.data 是否存在
          if (item.content && item.content.course && item.content.course) {
            item.content.course.forEach(course => {
              result.push({
                imageurl: course.imageurl,
                id: course.id, // 课程id
                teacherfactor: course.teacherfactor,
                classId: item.content.id, // 班级id
                name: course.name
              });
            });
          }
        });

        return result;
      }
    } catch {
    } finally {
      httpRequest.destroy()
    }
    return [
      {
        imageurl: '',
        id: 0,
        teacherfactor: '',
        classId: 0,
        name: ''
      }
    ]
  }
}

export interface classInfoType {
  imageurl: string;
  id: number; // 课程id
  teacherfactor: string;
  classId: number; // 班级id
  name: string;
}


// 课程频道项目接口
export interface CourseChannel {
  /** 课程文件夹ID */
  cfid: number;

  /** 排序序号 */
  norder: number;

  /** 分类名称 */
  cataName: string;

  /** 分类ID */
  cataid: string;

  /** 项目ID */
  id: number;

  /** 课程提供者ID */
  cpi: number;

  /** 班级唯一标识符 */
  key: number | string;

  /** 课程内容详情 */
  content: CourseContent;

  /** 置顶标记 */
  topsign: number;
}

// 班级/课程内容接口
export interface CourseContent {
  /** 学生数量 */
  studentcount: number;

  /** 聊天群组ID */
  chatid: string;

  /** 是否归档 */
  isFiled: number;

  /** 第三方认证状态 */
  isthirdaq: number;

  /** 是否已开始 */
  isstart: boolean;

  /** 退课状态：1=已退课, -1=正常, 0=其他 */
  isretire: number;

  /** 班级名称 */
  name: string;

  /** 课程数据 */
  course: CourseInfo[];

  /** 角色类型：1=教师, 3=学生 */
  roletype: number;

  /** 班级ID */
  id: number;

  /** 班级状态 */
  state: number;

  /** 课程提供者ID */
  cpi: number;

  /** 论坛/讨论区ID */
  bbsid: string;

  /** 是否为广场课程 */
  isSquare: number;
}

// 课程基本信息接口
export interface CourseInfo {
  /** 课程ID */
  id: number;

  /** 课程名称 */
  name: string;

  /** 授课教师 */
  teacherfactor: string;

  /** 创建时间戳 */
  createtime: number;

  /** 课程图片URL */
  imageurl: string;

  /** 所属学校ID */
  belongSchoolId: string;

  /** 课程状态 */
  coursestate: number;

  /** 是否为课程广场 */
  isCourseSquare: number;

  /** 课程广场URL */
  courseSquareUrl: string;

  /** 默认显示目录 */
  defaultShowCatalog: number;

  /** 章节ID */
  sectionId: number;

  /** 智能课程状态 */
  smartCourseState: number;

  /** 应用数据 */
  appData: number;

  /** 应用信息（可选） */
  appInfo?: string;

  /** 学校名称（可选） */
  schools?: string;
}