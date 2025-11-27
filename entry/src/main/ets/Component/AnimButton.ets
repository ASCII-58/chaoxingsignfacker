import { hdsEffect } from '@kit.UIDesignKit';

@Component
export struct AnimButton {
    @BuilderParam content: () => void
        @State buttonScale: number = 1
    @State lightSourceType: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;
    onClickAction: () => void = () => { }

    build() {
        Button() {
            this.content()
        }
    .borderRadius(999)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .shadow({
                radius: 8,
                color: '#00000020',
                offsetX: 0,
                offsetY: 3
            })
            .scale({ x: this.buttonScale, y: this.buttonScale })
            .animation({ duration: 200, curve: Curve.EaseInOut })
        .visualEffect(new hdsEffect.HdsEffectBuilder()
            .pointLight({
                sourceType: this.lightSourceType,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER
            })
            .buildEffect())
            .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                    this.buttonScale = 0.92
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                        this.lightSourceType = hdsEffect.PointLightSourceType.BRIGHT;
                    })
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.buttonScale = 1
                    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                        this.lightSourceType = hdsEffect.PointLightSourceType.NONE;
                    })
                }
            })
            .onClick(() => {
                this.onClickAction()
            })
    }
}
