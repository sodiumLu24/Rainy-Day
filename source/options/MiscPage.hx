package options;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class MiscPage extends FlxGroup
{
    // 三个选项的状态（外部可通过 getter 访问）
    public var isHardMode:Bool = false;
    public var showDamageNumbers:Bool = false;
    public var showHealthBar:Bool = false;

    // 回调，当任意选项改变时触发（用于保存）
    public var onSettingChange:Void->Void;

    // 复选框组件数组（便于统一管理）
    private var checkboxes:Array<CheckboxItem> = [];

    // 音效（请将 "click.wav" 或 "click.ogg" 放在 assets/sounds/ 下）
    private static inline var CLICK_SOUND:String = "assets/sfx/click.wav";

    public function new(screenWidth:Float, screenHeight:Float)
    {
        super();

        var startY:Float = 80;
        var gap:Float = 40;
        var labelWidth:Float = 200;

        // 三个选项的标签文字
        var labels:Array<String> = ["Hard Mode", "Injure Numbers", "Show Health Bar"];

        for (i in 0...labels.length) {
            var yPos = startY + i * gap;
            var item = new CheckboxItem(
                screenWidth, yPos, labels[i],
                // 点击回调
                function() {
                    // 切换状态
                    var newVal = !getState(i);
                    setState(i, newVal);
                        FlxG.sound.play(CLICK_SOUND);
                    // 通知保存
                    if (onSettingChange != null) {
                        onSettingChange();
                    }
                }
            );
            add(item);
            checkboxes.push(item);
        }

        // 从存档加载初始值（由 OptionsState 调用 setStates 完成）
    }

    // ---------- 状态读写 ----------
    private function getState(index:Int):Bool {
        return switch(index) {
            case 0: isHardMode;
            case 1: showDamageNumbers;
            case 2: showHealthBar;
            default: false;
        }
    }

    private function setState(index:Int, value:Bool):Void {
        switch(index) {
            case 0: isHardMode = value;
            case 1: showDamageNumbers = value;
            case 2: showHealthBar = value;
        }
        checkboxes[index].setChecked(value);
    }

    /**
     * 外部批量设置（加载存档时使用）
     */
    public function setStates(hardMode:Bool, damage:Bool, healthBar:Bool):Void {
        isHardMode = hardMode;
        showDamageNumbers = damage;
        showHealthBar = healthBar;
        checkboxes[0].setChecked(hardMode);
        checkboxes[1].setChecked(damage);
        checkboxes[2].setChecked(healthBar);
    }

    override public function destroy():Void
    {
        for (item in checkboxes) {
            item.destroy();
        }
        super.destroy();
    }
}

/**
 * 单个复选框组件（封装方框+勾+文字+点击按钮）
 */
private class CheckboxItem extends FlxGroup
{
    private var toggleBox:FlxSprite;
    private var checkMark:FlxSprite;
    private var labelText:FlxText;
    private var hitButton:FlxButton;

    public function new(screenWidth:Float, y:Float, label:String, onClick:Void->Void)
    {
        super();

        var boxSize:Int = 24;
        var boxX:Float = (screenWidth - boxSize) / 2 - 80; // 左移留文字空间

        // 外框
        toggleBox = new FlxSprite(boxX, y);
        toggleBox.makeGraphic(boxSize, boxSize, FlxColor.TRANSPARENT);
        var lineOpt = {color: FlxColor.WHITE, thickness: 2};
        FlxSpriteUtil.drawLine(toggleBox, 0, 0, boxSize, 0, lineOpt);
        FlxSpriteUtil.drawLine(toggleBox, boxSize, 0, boxSize, boxSize, lineOpt);
        FlxSpriteUtil.drawLine(toggleBox, 0, boxSize, boxSize, boxSize, lineOpt);
        FlxSpriteUtil.drawLine(toggleBox, 0, 0, 0, boxSize, lineOpt);
        add(toggleBox);

        // 勾号
        checkMark = new FlxSprite(boxX + 4, y + 4);
        checkMark.makeGraphic(boxSize - 8, boxSize - 8, FlxColor.TRANSPARENT);
        var checkOpt = {color: FlxColor.WHITE, thickness: 3};
        FlxSpriteUtil.drawLine(checkMark, 2, 10, 8, 16, checkOpt);
        FlxSpriteUtil.drawLine(checkMark, 8, 16, 16, 4, checkOpt);
        checkMark.visible = false;
        add(checkMark);

        // 文字标签
        labelText = new FlxText(boxX + boxSize + 10, y + 2, 200, label, 14);
        labelText.color = FlxColor.WHITE;
        labelText.font = "Arial";
        labelText.antialiasing = false;
        add(labelText);

        // 点击区域
        hitButton = new FlxButton(boxX - 5, y - 5, "", onClick);
        hitButton.makeGraphic(Std.int(boxSize + 80), Std.int(boxSize + 10), FlxColor.TRANSPARENT, true);
        hitButton.label.visible = false;
        add(hitButton);
    }

    public function setChecked(checked:Bool):Void
    {
        checkMark.visible = checked;
    }

    override public function destroy():Void
    {
        super.destroy();
    }
}