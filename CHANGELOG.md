# 更新日志 (Changelog)

所有值得注意的项目更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
- 完整的项目 README 文档
- 更新日志文件

### 优化
- **首页列表性能优化** ✅
  - 移除了所有入场动画（淡入、平移、缩放），显著减少页面加载时间
  - 为所有 ForEach 循环添加唯一键函数，提高列表渲染效率
  - 在 ClassIcon 和 OtherUserItem 组件中添加加载状态检查，避免重复加载
  - 为图片组件添加 alt 属性，改善用户体验
  - 移除了搜索栏和标题栏的入场动画
  - 优化活动列表页面的列表渲染性能
  - 移除了未使用的状态变量，减少内存开销
- 移除所有不当的日志输出（包含脏话的 console.log）
- 统一使用 HarmonyOS hilog API 进行日志记录
- 为所有服务和页面文件添加日志域（DOMAIN）和标签（TAG）
- 提取魔术数字为有意义的常量
  - HTTP_TIMEOUT_MS: 60000ms
  - HTTP_SUCCESS_CODE: 200
  - SIGN_TIME_MARKER: '<p class="signtime">'
  - CAPTCHA_CALLBACK: 'cx_captcha_function'
  - TOKEN_EXPIRY_MS: 300000ms
- 改进错误处理机制
  - 所有网络请求都在 finally 块中调用 destroy()
  - 添加详细的错误日志
  - 改进错误提示文案（用户友好）
- 增强输入参数验证
  - LoginByURL 方法添加空值检查
  - 添加参数存在性验证
  - 添加更详细的验证失败提示
- 代码质量改进
  - 修复所有 httpRequest 内存泄漏
  - 统一错误处理模式
  - 改进代码可读性

### 修复
- 修复 httpRequest 未正确释放的内存泄漏问题
- 修复 getUserInfo 方法中 fid 和 puid 类型转换错误
- 修复 DoPreSignIn 等方法缺少 finally 块的问题

### 变更
- 错误提示语从"傻逼服务器崩了"改为"服务器错误，请稍后重试"
- 所有不当语言从日志中移除

## [1.0.0] - 初始版本

### 新增
- 多账号管理功能
- 自动签到功能
  - 普通签到
  - 位置签到
  - 拍照签到
  - 扫码签到
- 课程列表管理
- 活动列表查看
- 二维码分享功能
- 数据库存储
- AES 加密

### 技术特性
- 基于 HarmonyOS 5.0.5+
- 使用 ArkTS 开发
- RelationalStore 数据持久化
- HTTP 网络请求
- 图像处理支持

---

## 版本说明

### 版本号格式：主版本号.次版本号.修订号

- **主版本号**：进行不兼容的 API 更改时
- **次版本号**：以向后兼容的方式添加功能时
- **修订号**：进行向后兼容的错误修复时

### 变更类型

- **新增（Added）**：新功能
- **变更（Changed）**：现有功能的变更
- **弃用（Deprecated）**：即将删除的功能
- **移除（Removed）**：已删除的功能
- **修复（Fixed）**：错误修复
- **安全（Security）**：安全性修复
- **优化（Optimized）**：性能或代码质量优化
