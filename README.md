# 超星签到助手 (Chaoxing Sign-in Helper)

一个基于 HarmonyOS 的超星学习通自动签到应用，帮助用户便捷地管理和完成签到任务。

## 功能特性

### 核心功能
- ✅ **多账号管理** - 支持添加和管理多个超星账号
- ✅ **自动签到** - 支持多种签到类型（普通签到、拍照签到、位置签到、扫码签到、手势签到、签到码签到）
- ✅ **课程管理** - 查看和管理已加入的课程列表
- ✅ **活动列表** - 实时查看签到活动状态
- ✅ **二维码分享** - 快速分享账号信息（加密传输）
- ✅ **签退功能** - 支持签到后的签退操作

### 签到类型支持
- 普通签到（类型 0）
- 扫码签到（类型 2）
- 手势签到（类型 3）- 支持9点手势绘制
- 位置签到（类型 4）
- 签到码签到（类型 5）- 支持数字密码输入
- 拍照签到 - 支持从图库选择照片

## 技术栈

- **开发语言**: ArkTS (TypeScript)
- **UI框架**: ArkUI
- **平台**: HarmonyOS 5.0.5+
- **数据库**: RelationalStore (SQLite)
- **加密**: AES-256-CBC
- **网络请求**: @ohos.net.http

## 项目结构

```
chaoxingsignfacker/
├── entry/
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/
│   │   │   │   ├── pages/          # 页面组件
│   │   │   │   │   ├── Index.ets           # 主页
│   │   │   │   │   ├── LoginPage.ets       # 登录页
│   │   │   │   │   ├── SignerPage.ets      # 签到页（集成所有签到类型）
│   │   │   │   │   ├── ActivityListPage.ets # 活动列表
│   │   │   │   │   └── SearchCoursePage.ets # 课程搜索
│   │   │   │   ├── utils/          # 工具类
│   │   │   │   │   ├── Login.ets           # 登录服务
│   │   │   │   │   ├── sign.ets            # 签到服务
│   │   │   │   │   ├── DataBase.ets        # 数据库管理
│   │   │   │   │   ├── utils.ts            # 工具函数
│   │   │   │   │   ├── PublicAPI.ts        # API定义
│   │   │   │   │   └── classFun.ets        # 课程功能
│   │   │   │   └── Component/      # 可复用组件
│   │   │   │   │   ├── loginCom.ets        # 登录组件
│   │   │   │   │   ├── GestureSignComponent.ets  # 手势签到组件
│   │   │   │   │   └── PasswordSignComponent.ets # 签到码组件
│   │   │   └── resources/          # 资源文件
│   │   └── ohosTest/              # 测试文件
│   ├── build-profile.json5        # 构建配置
│   └── hvigorfile.ts              # 构建脚本
├── oh-package.json5               # 依赖配置
└── build-profile.json5            # 项目构建配置
```

## 开始使用

### 环境要求

- DevEco Studio 5.1.1+
- HarmonyOS SDK API 12 (5.0.5+)
- Node.js 16+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/ASCII-58/chaoxingsignfacker.git
   cd chaoxingsignfacker
   ```

2. **打开项目**
   - 使用 DevEco Studio 打开项目
   - 等待依赖自动下载

3. **配置签名**
   - 在 DevEco Studio 中配置应用签名
   - 或使用自动签名功能

4. **构建运行**
   - 连接 HarmonyOS 设备或启动模拟器
   - 点击运行按钮

## 使用说明

### 首次登录

1. 启动应用后进入登录页面
2. 输入超星学习通账号和密码
3. 点击登录按钮完成主账号登录

### 添加其他账号

**方法一：二维码扫描**
1. 在主页点击"添加账号"
2. 使用其他设备的应用生成二维码
3. 扫描二维码完成添加

**方法二：URL导入**
1. 获取包含账号信息的URL
2. 在应用中输入URL
3. 自动解析并添加账号

### 签到操作

1. 在主页选择课程
2. 查看当前签到活动
3. 选择需要签到的活动
4. 根据签到类型完成相应操作：
   - **普通签到**：直接点击签到按钮
   - **位置签到**：打开地图选择位置后签到
   - **拍照签到**：从图库选择照片上传后签到
   - **扫码签到**：扫描教师提供的二维码
   - **手势签到**：在3×3网格上绘制手势图案
   - **签到码签到**：输入教师提供的数字签到码
5. 签到成功后，部分活动支持签退操作

## 安全性说明

### 数据加密
- 密码使用 AES-256-CBC 加密存储
- 默认加密密钥：`u2oh6Vu^HWe4_AES`
- Cookie 信息加密保存在本地数据库

### 数据存储
- 使用 HarmonyOS RelationalStore 本地存储
- 数据库安全等级：S1（私有数据）
- 支持多用户数据隔离

### 网络通信
- 使用 HTTPS 协议通信
- Cookie 自动管理和更新
- 请求超时保护（60秒）

## 开发指南

### 添加新功能

1. 在 `utils` 目录下创建服务类
2. 使用 hilog 进行日志记录
3. 确保所有网络请求在 finally 中调用 `httpRequest.destroy()`
4. 遵循现有的错误处理模式

### 日志规范

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'YourService';
const DOMAIN = 0x000X;  // 使用唯一的域ID

// 使用方法
hilog.debug(DOMAIN, TAG, 'Debug message');
hilog.info(DOMAIN, TAG, 'Info message');
hilog.error(DOMAIN, TAG, `Error: ${error.message}`);
```

### 代码规范

- 使用 TypeScript 严格模式
- 遵循 ArkTS 编码规范
- 魔术数字提取为常量
- 函数添加 JSDoc 注释
- 错误处理使用 try-catch-finally

## 依赖项

```json5
{
  "dependencies": {
    "@hadss/debug-db": "^1.0.0-rc.9",
    "@ohos/crypto-js": "^2.0.5",
    "@ohos/imageknife": "^3.2.7"
  }
}
```

## 常见问题

### Q: 登录失败怎么办？
A: 
1. 检查网络连接
2. 确认账号密码正确
3. 查看日志输出获取详细错误信息

### Q: 签到失败怎么办？
A: 
1. 确认签到活动还在有效期内
2. 检查是否已经签到过
3. 查看具体的签到类型要求（位置、照片等）

### Q: 如何调试？
A: 
1. 使用 DevEco Studio 的调试功能
2. 查看 hilog 日志输出
3. 使用 @hadss/debug-db 查看数据库内容

## 更新日志

### v1.0.0 (优化版本)
- ✅ 移除不当的日志输出
- ✅ 使用标准 hilog API 进行日志记录
- ✅ 提取魔术数字为常量
- ✅ 改进错误处理机制
- ✅ 修复内存泄漏问题
- ✅ 增强输入参数验证
- ✅ 添加项目文档

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件

## 免责声明

本项目仅供学习交流使用，请勿用于非法用途。使用本软件所产生的一切后果由使用者自行承担。

## 联系方式

- 作者：ASCII-58
- GitHub：[https://github.com/ASCII-58/chaoxingsignfacker](https://github.com/ASCII-58/chaoxingsignfacker)

## 致谢

感谢所有为本项目做出贡献的开发者！
