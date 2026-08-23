package options;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class FullscreenPage extends FlxGroup
{
    private var toggleBox:FlxSprite;
    private var checkMark:FlxSprite;
    private var labelText:FlxText;
    private var hitButton:FlxButton;

    public var onFullscreenChange:Bool->Void;

    public function new(screenWidth:Float, screenHeight:Float)
    {
        super();

        var boxSize = 24;
        var boxX = (screenWidth - boxSize) / 2 - 80; // 左移，为文字留空间
        var boxY = 180;

        // ---------- 复选框外框（只用 drawLine） ----------
        toggleBox = new FlxSprite(boxX, boxY);
        toggleBox.makeGraphic(boxSize, boxSize, FlxColor.TRANSPARENT);
        // 绘制四条边框线（白色，粗细2）
        var lineOptions = {color: FlxColor.WHITE, thickness: 2};
        FlxSpriteUtil.drawLine(toggleBox, 0, 0, boxSize, 0, lineOptions);        // 上
        FlxSpriteUtil.drawLine(toggleBox, boxSize, 0, boxSize, boxSize, lineOptions); // 右
        FlxSpriteUtil.drawLine(toggleBox, 0, boxSize, boxSize, boxSize, lineOptions); // 下
        FlxSpriteUtil.drawLine(toggleBox, 0, 0, 0, boxSize, lineOptions);        // 左
        add(toggleBox);

        // ---------- 勾选标记（勾号，使用 drawLine） ----------
        checkMark = new FlxSprite(boxX + 4, boxY + 4);
        checkMark.makeGraphic(boxSize - 8, boxSize - 8, FlxColor.TRANSPARENT);
        // 绘制一个勾：从 (2,10) -> (8,16) -> (16,4)
        var checkOptions = {color: FlxColor.WHITE, thickness: 3};
        FlxSpriteUtil.drawLine(checkMark, 2, 10, 8, 16, checkOptions);
        FlxSpriteUtil.drawLine(checkMark, 8, 16, 16, 4, checkOptions);
        checkMark.visible = false; // 默认不勾选
        add(checkMark);

        // ---------- 文字标签（缩小字号，带毛边） ----------
        labelText = new FlxText(boxX + boxSize + 10, boxY + 2, 200, "Fullscreen", 14); // 字体缩小
        labelText.color = FlxColor.WHITE;
        labelText.font = "Arial"; // 系统字体
        labelText.antialiasing = false; // 关闭抗锯齿，产生毛边效果
        add(labelText);

        // ---------- 点击区域（透明按钮覆盖） ----------
        hitButton = new FlxButton(boxX - 5, boxY - 5, "", function() {
            toggleFullscreen();
        });
        hitButton.makeGraphic(Std.int(boxSize + 80), Std.int(boxSize + 10), FlxColor.TRANSPARENT, true);
        hitButton.label.visible = false;
        add(hitButton);

        // 初始化状态
        updateCheckbox(FlxG.fullscreen);
    }

    private function toggleFullscreen():Void
    {
        var newFullscreen = !FlxG.fullscreen;
        FlxG.fullscreen = newFullscreen;
        if (!newFullscreen) {
            FlxG.resizeWindow(640, 480);
        }
        updateCheckbox(newFullscreen);
        if (onFullscreenChange != null) {
            onFullscreenChange(newFullscreen);
        }
    }

    private function updateCheckbox(fullscreen:Bool):Void
    {
        checkMark.visible = fullscreen;
        // 可选：改变外框颜色或粗细突出选中状态（这里简单保持白色）
        // 如果需要，可以重新绘制边框，但为了简洁，只控制勾的显隐
    }

    /**
     * 外部设置全屏状态（用于加载存档）
     */
    public function setFullscreen(value:Bool):Void
    {
        if (value != FlxG.fullscreen) {
            FlxG.fullscreen = value;
            if (!value) {
                FlxG.resizeWindow(640, 480);
            }
            updateCheckbox(value);
        }
    }

    override public function destroy():Void
    {
        super.destroy();
    }
}