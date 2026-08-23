package;

import flixel.addons.display.FlxTiledSprite;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.filters.BlurFilter;

class PauseSubState extends FlxSubState
{
    private var blurFilter:BlurFilter;

    override public function create():Void
    {
        super.create();

        // ---- 1. 主摄像机模糊滤镜 ----
        blurFilter = new BlurFilter(4, 4, 1);
        FlxG.camera.filters = [blurFilter];

        // ---- 2. 半透明灰色遮罩 ----
        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY);
        bg.alpha = 0.6;
        bg.scrollFactor.set(0, 0);
        add(bg);

        // ---- 3. 扫描线（VCR 效果） ----
        var scanlineGraphic = generateScanlineTexture(1, 2);
        // 使用 FlxTiledSprite 自动平铺填充全屏
        var scanlines = new FlxTiledSprite(scanlineGraphic, FlxG.width, FlxG.height);
        scanlines.scrollFactor.set(0, 0);
        scanlines.alpha = 0.25;
        add(scanlines);

        // ---- 4. 中央提示文字 ----
        var hintText = new FlxText(0, 0, FlxG.width, "PRESS ESC TO CONTINUE", 40);
        hintText.color = FlxColor.WHITE;
        hintText.alignment = CENTER;
        hintText.font = "Time New Roman";
        hintText.borderSize = 3;
        hintText.antialiasing = true;
        hintText.y = (FlxG.height - hintText.height) / 2;
        hintText.borderStyle = SHADOW;
        hintText.scrollFactor.set(0, 0);
        // hintText.camera = FlxG.camera;
        add(hintText);
    }

    /**
     * 生成扫描线纹理（透明/半透明黑条纹）
     */
    private function generateScanlineTexture(width:Int, height:Int):FlxGraphic
    {
        var bmd = new BitmapData(width, height, true, 0x00000000);
        // 第一行透明
        bmd.setPixel32(0, 0, 0x00000000);
        // 第二行半透明黑（alpha 0.2）
        bmd.setPixel32(0, 1, 0x33000000);
        return FlxGraphic.fromBitmapData(bmd);
    }

    override public function close():Void
    {
        if (blurFilter != null)
        {
            FlxG.camera.filters = null;
            blurFilter = null;
        }
        super.close();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE)
        {
            close();
        }
    }
}