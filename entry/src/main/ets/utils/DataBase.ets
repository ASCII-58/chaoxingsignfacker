import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface UserData {
  phone: string;
  pwd: string;
  name: string;
  pic: string;
  cookies: string;
  fid: number;
  uid: number;
}

interface BasicUserInfo {
  id: number;
  phone: string;
  name: string;
  password: string;
}

interface AllInfo {
  host: BasicUserInfo,
  other: BasicUserInfo[]
}

class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {
  }

  public static getInstance(): DatabaseManager {
    if (DatabaseManager.instance === null) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  public isInitialized(): boolean {
    return this.rdbStore !== null;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.rdbStore !== null) {
      return;
    }

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'data.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.createTables();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to get RdbStore. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  /**
   * 通过id获取用户所有数据
   * @param tableName 表头
   * @param id 用户ID
   * @returns {Promise<UserData>} 包含用户所有信息的对象
   */
  public async getHostUserInfoByID(id: number=1): Promise<UserData> {
    if (typeof id !== 'number' || id <= 0) {
      throw new Error(`无效的ID: ${id}. 必须是正整数`);
    }
      let tableName=""

    // 2. 检查数据库连接
    if (!this.rdbStore) {
      throw new Error('数据库未初始化。请先调用init()方法。');
    }

    try {
      // 3. 构建SQL查询语句（使用参数化查询防止SQL注入）
      const sql = `
        SELECT phone, pwd, name, pic, cookies, uid, fid
        FROM HostName
        WHERE id = ${[id]}
      `;

      // 4. 执行查询
      const resultSet = await this.rdbStore.querySql(sql);

      try {
        console.error('fuck,'+resultSet.rowCount)
        // 5. 处理查询结果
        if (resultSet.rowCount != 0) {
          try {
            resultSet.goToFirstRow();
          } catch (error) {
            console.error('fuckkkkkkkkkkkkkkkkkkkkkkkk,'+error)
          }
          // 获取各列索引
          const phoneIndex = resultSet.getColumnIndex('phone');
          const pwdIndex = resultSet.getColumnIndex('pwd');
          const nameIndex = resultSet.getColumnIndex('name');
          const picIndex = resultSet.getColumnIndex('pic');
          const cookiesIndex = resultSet.getColumnIndex('cookies');
          const uidIndex = resultSet.getColumnIndex('uid');
          const fidIndex = resultSet.getColumnIndex('fid');

          // 构建返回对象
          const userData: UserData = {
            phone: resultSet.getString(phoneIndex),
            pwd: resultSet.getString(pwdIndex),
            name: resultSet.getString(nameIndex),
            pic: resultSet.getString(picIndex),
            cookies: resultSet.getString(cookiesIndex),
            uid: resultSet.getLong(uidIndex),
            fid: resultSet.getLong(fidIndex)
          };

          return userData;
        }
        console.error(`在表${tableName}中未找到ID为${id}的用户`)
        // 6. 未找到记录时抛出错误
        throw new Error(`在表${tableName}中未找到ID为${id}的用户`);

      } finally {
        // 7. 确保结果集被关闭
        resultSet.close();
      }
    } catch (err) {
      // 8. 规范化错误并重新抛出
      throw this.normalizeError(err, `获取${tableName}表中UID为${id}的用户数据失败`);
    }
  }

  /**
   * 通过手机号或id获取单个用户的单项数据
   * @param tableName
   * @param phone
   * @param search
   * @returns
   */
  public async getUserInfoByPhone(
    key: 'id' | 'phone',
    tableName: 'HostUser' | 'OtherUser',
    phone: number | string,
    search: "phone" | "pwd" | "name" | "pic" | "cookies" | "uid" | "fid" | 'id'): Promise<string | null | number> {
    // 1. 参数验证
    if (tableName !== 'HostUser' && tableName !== 'OtherUser') {
      throw new Error(`无效的表名: ${tableName}. 允许的表: HostUser, OtherUser`);
    }

    // 2. 检查数据库连接
    if (!this.rdbStore) {
      throw new Error('数据库未初始化。请先调用init()方法。');
    }

    try {
      const sql = `SELECT ${search} FROM ${tableName} WHERE ${key} = ?`;
      const params = [phone];

      // 4. 执行查询
      const resultSet = await this.rdbStore.querySql(sql, params);

      try {
        // 5. 处理查询结果
        if (resultSet.rowCount > 0) {
          resultSet.goToFirstRow();
          const Index = resultSet.getColumnIndex(search);
          const result = resultSet.getString(Index);
          return result
        }
        return null; // 未找到记录
      } finally {
        // 6. 确保结果集被关闭
        resultSet.close();
      }
    } catch (err) {
      // 7. 规范化错误并重新抛出（符合arkts-limited-throw规则）
      throw this.normalizeError(err, `获取${tableName}表中标识符为${phone}的用户的${search}失败`);
    }
  }

  /**
   * 检查HostUser表是否为空
   *
   * @returns {Promise<boolean>} 如果表为空则返回true，否则返回false
   * @throws {Error} 如果数据库未初始化
   * @throws {BusinessError} 如果查询过程中发生错误
   */
  public async isHostUserTableEmpty(): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call init() first.');
    }

    try {
      // 使用高效查询：只需检查是否存在至少一行数据
      const sql = 'SELECT 1 FROM HostUser LIMIT 1';
      const resultSet = await this.rdbStore.querySql(sql);

      try {
        // rowCount为0表示没有数据
        return resultSet.rowCount === 0;
      } finally {
        // 确保无论查询结果如何都关闭结果集
        resultSet.close();
      }
    } catch (error) {
      const err = new Error(`Database init failed: ${error.message}`);
      hilog.error(0x0000, 'DB_INIT', err.message);
      throw err;
    }
  }

  /**
   * 插入用户数据：如果HostUser表为空则插入HostUser，否则报错
   *
   * @param userData 用户数据对象
   * @returns {Promise<boolean>} 是否插入成功
   * @throws {Error} 如果数据库未初始化、手机号已存在或插入失败
   */
  public async insertUser(userData: UserData): Promise<boolean> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized. Call init() first.');
      }
      // 开始事务确保操作原子性
      this.rdbStore.beginTransaction();

      try {
        // 1. 检查手机号是否已存在（跨两个表检查）
        const phoneExists = await this.checkPhoneExists(userData.phone);
        if (phoneExists) {
          throw new Error('手机号登录，请使用其他手机号');
        }

        // 2. 检查HostUser表是否为空
        const isHostUserEmpty = await this.isHostUserTableEmpty();
        if (!isHostUserEmpty) {
          throw new Error('主用户已登录')
        }

        // 3. 使用参数化查询执行插入
        const insertSql = `
        INSERT INTO HostUser (phone, pwd, name, pic, cookies, uid, fid)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;

        await this.rdbStore.executeSql(insertSql, [
          userData.phone,
          userData.pwd,
          userData.name,
          userData.pic,
          userData.cookies,
          userData.uid,
          userData.fid
        ]);

        // 4. 获取最后插入的行ID
        const resultSet = await this.rdbStore.querySql('SELECT last_insert_rowid() AS id');
        try {

          // 5. 提交事务
          this.rdbStore.commit();
          return true;

        }catch {
          return false
        } finally {
          resultSet.close();
        }
      } catch (error) {
        // 6. 发生错误时回滚事务
        this.rdbStore.rollBack();

        // 重新抛出标准化的错误
        const errorMessage = error instanceof Error
          ? error.message
          : 'Unknown database error';

        throw new Error(`数据库操作失败: ${errorMessage}`);
      }
    } catch (err) {
      // 7. 外层错误处理（确保事务回滚）
      try {
        if (this.rdbStore) {
          this.rdbStore.rollBack();
        }
      } catch (rollbackError) {
        console.error('Failed to rollback transaction', rollbackError);
      }

      const error = err as BusinessError;
      console.error(`Failed to insert user. Code: ${error.code}, Message: ${error.message}`);
      return false
      throw new Error(`用户插入失败: ${error.message}`);
    }
  }

  /**
   * 获取指定表的记录数量
   *
   * @param tableName 要查询的表名（必须是允许的表）
   * @returns {Promise<number>} 表中的记录数量
   * @throws {Error} 如果数据库未初始化或表名无效
   */
  public async getTableCount(tableName: 'HostUser' | 'OtherUser'): Promise<number> {
    // 验证表名合法性，防止SQL注入
    const allowedTables = ['HostUser', 'OtherUser'];
    if (!allowedTables.includes(tableName)) {
      throw new Error(`无效的表名: ${tableName}. 允许的表: ${allowedTables.join(', ')}`);
    }

    if (!this.rdbStore) {
      throw new Error('数据库未初始化。请先调用init()方法。');
    }

    try {
      // 使用COUNT(*)获取表记录数
      const sql = `SELECT COUNT(*) AS count FROM ${tableName}`;
      const resultSet = await this.rdbStore.querySql(sql);

      try {
        if (resultSet.rowCount > 0) {
          resultSet.goToFirstRow();
          const columnIndex = resultSet.getColumnIndex('count');
          return resultSet.getLong(columnIndex);
        }
        return 0;
      } finally {
        // 确保结果集被正确关闭
        resultSet.close();
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取表 ${tableName} 记录数失败. 错误码: ${error.code}, 消息: ${error.message}`);
      throw new Error(`无法获取表记录数: ${error.message}`);
    }
  }

  getRdbStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call init() first.');
    }
    return this.rdbStore;
  }

  /**
   * 清空HostUser表中的所有数据
   *
   * @returns {Promise<number>} 删除的记录数量
   * @throws {Error} 如果数据库未初始化或操作失败
   */
  public async clearHostUserTable(): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化。请先调用init()方法。');
    }

    try {
      // 开始事务确保操作原子性
      this.rdbStore.beginTransaction();

      try {
        // 1. 先获取当前记录数（用于返回结果）
        const countResult = await this.rdbStore.querySql('SELECT COUNT(*) AS count FROM HostUser');
        let rowCount = 0;

        try {
          if (countResult.rowCount > 0) {
            countResult.goToFirstRow();
            rowCount = countResult.getLong(countResult.getColumnIndex('count'));
          }
        } finally {
          countResult.close();
        }

        // 2. 执行删除操作
        await this.rdbStore.executeSql('DELETE FROM HostUser');

        // 3. 重置自增ID（SQLite中需要额外操作）
        await this.rdbStore.executeSql('DELETE FROM sqlite_sequence WHERE name = "HostUser"');

        // 4. 提交事务
        this.rdbStore.commit();

        console.log(`成功清空HostUser表，删除${rowCount}条记录`);
        return rowCount;
      } catch (error) {
        // 5. 发生错误时回滚事务
        this.rdbStore.rollBack();
        throw this.normalizeError(error, '清空HostUser表失败');
      }
    } catch (err) {
      throw this.normalizeError(err, '清空HostUser表操作异常');
    }
  }

  async close(): Promise<void> {
    if (this.rdbStore) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
      } catch (err) {
        const error = err as BusinessError;
        console.error(`Failed to close database. Code: ${error.code}, Message: ${error.message}`);
      }
    }
    DatabaseManager.instance = null;
  }

  //创建表
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS HostUser (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT NOT NULL,
          pwd TEXT NOT NULL,
          name TEXT NOT NULL,
          pic TEXT NOT NULL,
          cookies TEXT NOT NULL,
          uid INTEGER,
          fid INTEGER
        );
      `);

      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS OtherUser (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT NOT NULL,
          pwd TEXT NOT NULL,
          name TEXT NOT NULL,
          pic TEXT NOT NULL,
          cookies TEXT NOT NULL,
          uid INTEGER,
          fid INTEGER
        );
      `);

      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS SignInfo (
          signid INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT NOT NULL,
          signinfo TEXT,
          timestamp INTEGER NOT NULL
        );
      `);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to create tables. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  private normalizeError(err: Error, message: string): Error {
    return new Error(`${message} [原因]: ${err.message}`);
  }

  /**
   * 检查手机号是否已存在（跨两个表检查）
   *
   * @param phone 要检查的手机号
   * @returns {Promise<boolean>} 如果手机号已存在则返回true
   */
  private async checkPhoneExists(phone: string): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call init() first.');
    }

    try {
      // 使用UNION检查两个表
      const sql = `
      SELECT 1 FROM HostUser WHERE phone = ?
      UNION
      SELECT 1 FROM OtherUser WHERE phone = ?
      LIMIT 1
    `;

      const resultSet = await this.rdbStore.querySql(sql, [phone, phone]);

      try {
        return resultSet.rowCount > 0;
      } finally {
        // 确保结果集被关闭
        resultSet.close();
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to check phone existence. Code: ${error.code}, Message: ${error.message}`);
      throw new Error(`插入错误,${error}`)
    }
  }
}

export {
  DatabaseManager, UserData, BasicUserInfo, AllInfo,
}