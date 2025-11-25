import { generateBarcode, scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CryptoJS } from '@ohos/crypto-js';
import { fileUri, fileIo as fs } from '@kit.CoreFileKit';

export default class ShareUtils {
  public ShareURL: string;
  public exists: boolean = false;
  private fileName: string;
  private ShareBuffer: ArrayBuffer | null = null
  private context: Context
  private readonly QRCODE_OPTIONS: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: 200,
    width: 200
  }
  private readonly packOpts: image.PackingOption = { format: 'image/jpeg', quality: 30 }

  constructor(context: Context, ShareURL: string) {
    this.context = context;
    this.ShareURL = ShareURL;
    this.fileName = CryptoJS.MD5(ShareURL).toString().substring(0, 10) + '.jpg'
  }

  get FileUri(): string {
    if (this.exists) {
      return 'no this file'
    }
    let path = this.context.cacheDir + '/' + this.fileName;
    let fileUriObject = new fileUri.FileUri(path);
    let directoryUri = fileUriObject.getFullDirectoryUri();
    console.info(`success to getFullDirectoryUri: ${JSON.stringify(directoryUri)}`);
    return directoryUri
  }

  public async getQRCode() {
    try {
      generateBarcode.createBarcode(this.ShareURL, this.QRCODE_OPTIONS).then((result: image.PixelMap) => {
        const ShareIMAGE = result
        const imagePackerApi: image.ImagePacker = image.createImagePacker()

        imagePackerApi.packToData(ShareIMAGE, this.packOpts).catch(() => {
          // TODO: Implement error handling.
          hilog.error(0x0001, '[Scan Sample]', `Failed to packToData.`);
        }).then((result: ArrayBuffer | void) => {
          if (result) {
            this.ShareBuffer = result
          }
        })
        // 码图生成接口，成功返回PixelMap格式图片
        hilog.info(0x0001, '[Scan Sample]', `Succeeded in getting PixelMap by promise with options`);
      }).catch((error: BusinessError) => {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to get PixelMap by promise with options. Code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      hilog.error(0x0001, '[Scan Sample]', `Failed to generateBarcode. Code: ${error.code}, message: ${error.message}`);
    }
  }

  /**
   * 写入文件
   * @param Focus 是否强制覆盖（true=覆盖现有非空文件；false=非空则不写）
   * @returns 0 成功；1 文件已存在（非空，未写入）；-1 失败
   */
  public async write(Focus: boolean): Promise<number> {
    const filePath = `${this.context.cacheDir}/${this.fileName}`;
    let fh: fs.File | undefined;

    console.info(`开始写入文件, 路径: ${filePath}, 强制覆盖: ${Focus}`);

    try {
      // 先尝试获取文件信息(存在与否、是否文件、大小)
      const info = await fs.stat(filePath).catch(() => {
        console.debug(`文件不存在或无法访问: ${filePath}`);
        return undefined;
      });

      if (info && !info.isFile()) {
        // 路径存在但不是普通文件
        console.error(`路径存在但不是普通文件: ${filePath}`);
        return -1;
      }

      // 若文件已存在且非空,并且不强制覆盖,则不写入
      if (info && info.size > 0 && !Focus) {
        console.info(`文件已存在且非空(大小: ${info.size}字节),跳过写入`);
        this.exists = true;
        return 1;
      }

      // 需要写入:包含三种情况
      // 1) 文件不存在; 2) 文件为空; 3) 文件非空但 Focus=true
      let openMode = fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY;
      if (info && info.size > 0 && Focus) {
        // 强制覆盖:截断到0再写
        console.info(`强制覆盖模式,原文件大小: ${info.size}字节`);
        openMode |= fs.OpenMode.TRUNC;
      } else if (!info) {
        console.info(`文件不存在,将创建新文件`);
      } else {
        console.info(`文件为空(大小: ${info.size}字节),准备写入`);
      }

      console.debug(`打开文件,模式: ${openMode}`);
      fh = fs.openSync(filePath, openMode);

      try {
        fs.writeSync(fh.fd, this.ShareBuffer);
        console.info(`文件写入成功: ${filePath}`);
      } finally {
        // 确保关闭句柄
        fs.closeSync(fh);
        console.debug(`文件句柄已关闭`);
        fh = undefined;
      }

      this.exists = true;
      return 0;
    } catch (err) {
      // 写入失败或权限/路径错误
      console.error(`文件写入失败: ${filePath}, 错误: ${err?.code}, 消息: ${err?.message}`);
      try {
        if (fh) {
          fs.closeSync(fh);
          console.debug(`异常情况下已关闭文件句柄`);
        }
      } catch (closeErr) {
        console.warn(`关闭文件句柄时发生异常: ${closeErr?.message}`);
      }
      return -1;
    }
  }
}

