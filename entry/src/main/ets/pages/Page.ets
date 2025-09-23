import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入默认界面扫码需要的日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ScanBarCodePage {
  build() {
    Column() {
      Row() {
        Button("Promise with options")
          .backgroundColor('#0D9FFB')
          .fontSize(20)
          .fontColor($r('sys.color.comp_background_list_card'))
          .fontWeight(FontWeight.Normal)
          .align(Alignment.Center)
          .type(ButtonType.Capsule)
          .width('90%')
          .height(40)
          .margin({ top: 5, bottom: 5 })
          .onClick(() => {
            // 定义扫码参数options
            let options: scanBarcode.ScanOptions = {
              scanTypes: [scanCore.ScanType.ALL],
              enableMultiMode: true,
              enableAlbum: true
            };
            try {
              // 可调用getHostContext接口获取当前页面关联的Context
              scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options).then((result: scanBarcode.ScanResult) => {
                // 解析码值结果跳转应用服务页
                hilog.info(0x0001, '[Scan CPSample]', `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
              }).catch((error: BusinessError) => {
                hilog.error(0x0001, '[Scan CPSample]',
                  `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
              });
            } catch (error) {
              hilog.error(0x0001, '[Scan CPSample]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          })
      }
      .height('100%')
    }
    .width('100%')
  }
}