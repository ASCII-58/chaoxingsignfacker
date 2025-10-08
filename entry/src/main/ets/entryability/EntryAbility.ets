import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AnimatedDrawableDescriptor, window } from '@kit.ArkUI';
import { DatabaseManager } from '../utils/DataBase';
import BuildProfile from 'BuildProfile';
import { loginFunction } from '../utils/Login';
import { ChaoxingUtils } from '../utils/utils';

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

    try {
      // 确保数据库初始化完成（带超时）
      await this.waitForDatabaseInit();

      if (this.databaseInitError) {
        hilog.error(DOMAIN, TAG, 'Database initialization failed: %{public}s', this.databaseInitError);
        // 加载错误页面
        windowStage.loadContent('pages/DatabaseError', (err) => {
          if (err) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load error page: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }

      const dbManager = DatabaseManager.getInstance()
      const isHostLogin: boolean = !(await dbManager.isHostUserTableEmpty())

      if (isHostLogin) {
        const username = await dbManager.getUserInfoById(true,1,'phone') as string
        const pwd= await dbManager.getUserInfoById(true,1,'pwd') as string
        const loginBody=ChaoxingUtils.getLoginBody(ChaoxingUtils.encryptByAES(username),pwd)
        const loginResult = await loginFunction.LoginChaoXing(loginBody)
        if (loginResult) {
          windowStage.loadContent('pages/Index', (err) => {
            if (err) {
              hilog.error(DOMAIN, 'testTag', 'Failed to load main page: %{public}s', JSON.stringify(err));
              return;
            }
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the main content.');
          });
        }
        AlertDialog.show({ message: '登录过期，请重新登录' })

      } else {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/LoginPage', );
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Window stage creation error: %{public}s',
        error instanceof Error ? error.message : JSON.stringify(error));

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
      hilog.error(DOMAIN, TAG, 'Failed to close database: %{public}s',
        error instanceof Error ? error.message : JSON.stringify(error));
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