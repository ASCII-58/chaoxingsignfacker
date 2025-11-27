import { curves, promptAction } from '@kit.ArkUI';
import { bundleManager, common, Want, ConfigurationConstant } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct SettingsComponent {
    @Link isShow: boolean;
    @State toggleIsOn: boolean = false;
    @State version: string = '';
  private context = getContext(this) as common.UIAbilityContext;

    aboutToAppear() {
        this.getVersion();
    }

  async getVersion() {
        try {
            let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
            this.version = bundleInfo.versionName;
        } catch (error) {
            console.error('Failed to get bundle info', error);
            this.version = 'Unknown';
        }
    }

  async clearCache() {
        try {
            let cacheDir = this.context.cacheDir;
            let filenames = await fs.listFile(cacheDir);
            for (let filename of filenames) {
                let path = cacheDir + '/' + filename;
                try {
                    let stat = await fs.stat(path);
                    if (stat.isDirectory()) {
                        await fs.rmdir(path); // Note: might need recursive deletion for non-empty dirs
                    } else {
                        await fs.unlink(path);
                    }
                } catch (e) {
                    // Ignore errors for individual files
                }
            }
            promptAction.showToast({ message: '缓存已清除' });
        } catch (error) {
            console.error('Failed to clear cache', error);
            promptAction.showToast({ message: '清除缓存失败' });
        }
    }

    openUrl(url: string) {
        let want: Want = {
            action: 'ohos.want.action.viewData',
            entities: ['entity.system.browsable'],
            uri: url
        };
        this.context.startAbility(want).catch((err: BusinessError) => {
            console.error('Failed to open URL', err);
            promptAction.showToast({ message: '无法打开链接' });
        });
    }

    build() {
        Column() {
            // Handle bar
            Row()
                .width(40)
                .height(5)
                .backgroundColor($r('sys.color.ohos_id_color_text_tertiary'))
                .borderRadius(2.5)
                .margin({ top: 10, bottom: 20 })

            Text("设置")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ left: 20, bottom: 20 })

            List({ space: 12 }) {
                // Appearance Section
                ListItem() {
                    Column() {
                        Row() {
                            Text("外观")
                                .fontSize(14)
                                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                                .width('100%')
                                .margin({ bottom: 8, left: 4 })
                        }

                        Row() {
                            Row() {
                                Image($r('app.media.brightness'))
                                    .width(24)
                                    .height(24)
                                    .margin({ right: 12 })
                                    .fillColor($r('sys.color.ohos_id_color_text_primary'))
                                Text("深色模式")
                                    .fontSize(16)
                                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                            }

                            Blank()

                            Toggle({ type: ToggleType.Switch, isOn: this.toggleIsOn })
                                .onChange((isOn: boolean) => {
                                    this.toggleIsOn = isOn
                                    this.context.getApplicationContext().setColorMode(isOn ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
                                })
                        }
            .width('100%')
                            .padding(12)
                            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                            .borderRadius(16)
                    }
                }

                // General Section
                ListItem() {
                    Column() {
                        Text("通用")
                            .fontSize(14)
                            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            .width('100%')
                            .margin({ bottom: 8, left: 4 })

                        Column() {
                            // Version
                            Row() {
                                Text("版本")
                                    .fontSize(16)
                                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                                Blank()
                                Text(this.version)
                                    .fontSize(14)
                                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            }
              .width('100%')
                                .padding(12)

                            Divider()
                                .color($r('sys.color.ohos_id_color_list_separator'))
                                .margin({ left: 12, right: 12 })

                            // Clear Cache
                            Row() {
                                Text("清除缓存")
                                    .fontSize(16)
                                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                                Blank()
                                Image($r('app.media.arrow_right'))
                                    .width(16)
                                    .height(16)
                                    .fillColor($r('sys.color.ohos_id_color_text_tertiary'))
                            }
              .width('100%')
                                .padding(12)
                                .onClick(() => {
                                    this.clearCache()
                                })

                            Divider()
                                .color($r('sys.color.ohos_id_color_list_separator'))
                                .margin({ left: 12, right: 12 })

                            // Github
                            Row() {
                                Row() {
                                    Image($r('app.media.github'))
                                        .width(20)
                                        .height(20)
                                        .margin({ right: 8 })
                                        .fillColor($r('sys.color.ohos_id_color_text_primary'))
                                    Text("项目地址")
                                        .fontSize(16)
                                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                                }
                                Blank()
                                Image($r('app.media.arrow_right'))
                                    .width(16)
                                    .height(16)
                                    .fillColor($r('sys.color.ohos_id_color_text_tertiary'))
                            }
              .width('100%')
                                .padding(12)
                                .onClick(() => {
                                    this.openUrl('https://github.com/ASCII-58/chaoxingsignfacker')
                                })
                        }
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                            .borderRadius(16)
                    }
                }
            }
      .width('100%')
                .layoutWeight(1)
                .padding({ left: 16, right: 16 })
        }
    .width('100%')
            .height('100%')
            .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
            .borderRadius({ topLeft: 20, topRight: 20 })
    }
}
