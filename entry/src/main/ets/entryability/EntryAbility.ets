import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseManager } from '../utils/DataBase';
import { loginFunction } from '../utils/Login';
import { ChaoxingUtils } from '../utils/utils';
import { BusinessError } from '@kit.BasicServicesKit';
import BuildProfile from 'BuildProfile';

const DOMAIN = 0x0000;
const TAG = 'DB_INIT';

export default class EntryAbility extends UIAbility {
  // 数据库初始化状态
  private isDatabaseInitialized: boolean = false;
  private databaseInitError: string | null = null;
  private isInitializingDatabase: boolean = false;
  private readonly DB_INIT_TIMEOUT = 10000;

  // 5秒超时

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 启动数据库初始化（不阻塞UIAbility创建）
    this.initializeDatabase();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    if (BuildProfile.DEBUG) {
      import('@hadss/debug-db').then(async (ns: ESObject) => {
        await ns.DebugDB.initialize(this.context, { port: 8080, defaultStart: true });
      });
    }

    try {
      // 确保数据库初始化完成（带超时）
      await this.waitForDatabaseInit();

      const dbManager = DatabaseManager.getInstance()
      const isHostLogin: boolean = !(await dbManager.isHostUserTableEmpty())

      if (isHostLogin) {
        const user = await dbManager.getUserByPosition(1,true)
        const username = user?.phone
        const pwd = user?.pwd
        const loginBody = ChaoxingUtils.getLoginBody(ChaoxingUtils.encryptByAES(username), pwd)
        const cookies = await loginFunction.LoginChaoXing(loginBody)
        if (cookies) {
          dbManager.updateUser(1, { 'cookies': cookies }, true)
          let userCount: number = await dbManager.getTableCount('OtherUser')
          for (let index = 1; index <= userCount; index++) {
            const userInfo = await dbManager.getUserByPosition(index)
            if (userInfo !== null) {
              const username = userInfo.phone
              const pwd = userInfo.pwd
              const loginBody = ChaoxingUtils.getLoginBody(ChaoxingUtils.encryptByAES(username), pwd)
              const cookies = await loginFunction.LoginChaoXing(loginBody)
              if (cookies) {
                dbManager.updateUser(userInfo.id, { cookies: cookies }, false)
              } else {
                dbManager.deleteUser(userInfo.id, false)
              }
            }
          }
          windowStage.loadContent('pages/Index', (err) => {
            if (err) {
              const error = err as BusinessError;
              hilog.error(DOMAIN, 'testTag', 'Failed to load main page: Code=%{public}d, Message=%{public}s', error.code, error.message);
              return;
            }
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the main content.');
          });
        } else {
          windowStage.loadContent('pages/LoginPage', (err) => {
            if (err) {
              const error = err as BusinessError;
              hilog.error(DOMAIN, 'testTag', 'Failed to load main page: Code=%{public}d, Message=%{public}s', error.code, error.message);
              return;
            }
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the main content.');
          })
          AlertDialog.show({ message: '登录过期，请重新登录' })
        }

      } else {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/LoginPage', (err) => {
          if (err) {
            const error = err as BusinessError;
            hilog.error(DOMAIN, 'testTag', 'Failed to load main page: Code=%{public}d, Message=%{public}s', error.code, error.message);
            return;
          }
          hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the main content.');
        });
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Window stage creation error: Code=%{public}d, Message=%{public}s',
        err.code, err.message);

    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');

    // 关闭数据库连接
    try {
      const dbManager = DatabaseManager.getInstance();
      if (dbManager.isInitialized()) {
        dbManager.close();
        hilog.info(DOMAIN, TAG, '%{public}s', 'Database connection closed');
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to close database: Code=%{public}d, Message=%{public}s',
        err.code, err.message);
    }
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  /**
   * 初始化数据库（在onCreate中调用）
   */
  private async initializeDatabase(): Promise<void> {
    if (this.isInitializingDatabase || this.isDatabaseInitialized) {
      return;
    }

    this.isInitializingDatabase = true;
    hilog.info(DOMAIN, TAG, '%{public}s', 'Starting database initialization...');

    try {
      // 初始化数据库
      await DatabaseManager.getInstance().init(this.context);

      // 检查HostUser表状态
      const isEmpty = await DatabaseManager.getInstance().isHostUserTableEmpty();
      hilog.info(DOMAIN, TAG, 'HostUser table is %{public}s', isEmpty ? 'empty' : 'not empty');

      this.isDatabaseInitialized = true;
      this.databaseInitError = null;
      hilog.info(DOMAIN, TAG, '%{public}s', 'Database initialized successfully');
    } catch (error) {
      this.databaseInitError = error instanceof Error ? error.message : 'Unknown database initialization error';
      hilog.error(DOMAIN, TAG, 'Database initialization failed: %{public}s', this.databaseInitError);
    } finally {
      this.isInitializingDatabase = false;
    }
  }

  /**
   * 等待数据库初始化完成（带超时）
   */
  private async waitForDatabaseInit(): Promise<void> {
    return new Promise((resolve, reject) => {
      const startTime = Date.now();
      const checkInterval = 100; // 检查间隔

      const checkStatus = () => {
        if (this.isDatabaseInitialized) {
          clearInterval(timer);
          resolve();
        } else if (this.databaseInitError) {
          clearInterval(timer);
          reject(new Error(this.databaseInitError));
        } else if (Date.now() - startTime >= this.DB_INIT_TIMEOUT) {
          clearInterval(timer);
          reject(new Error('Database initialization timeout'));
        }
      };

      const timer = setInterval(checkStatus, checkInterval);
      checkStatus(); // 立即检查一次
    });
  }
}