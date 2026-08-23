package options;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;

class KeyBindPage extends FlxGroup
{
    private var actionNames:Array<String> = ["Up", "Down", "Left", "Right", "Jump", "Attack", "Run", "Special"];
    private var defaultKeys1:Array<Int> = [
        FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT,
        FlxKey.SPACE, FlxKey.Z, FlxKey.SHIFT, FlxKey.J
    ];
    private var defaultKeys2:Array<Int> = [
        FlxKey.W, FlxKey.S, FlxKey.A, FlxKey.D,
        FlxKey.NONE, FlxKey.NONE, FlxKey.ALT, FlxKey.NONE
    ];
    private var currentKeys1:Array<Int> = [];
    private var currentKeys2:Array<Int> = [];

    private var keyDisplays1:Array<FlxText> = [];
    private var keyDisplays2:Array<FlxText> = [];
    private var waitingTexts1:Array<FlxText> = [];
    private var waitingTexts2:Array<FlxText> = [];
    private var hitButtons:Array<FlxButton> = [];

    private var scrollableElements:Array<{obj:FlxSprite, origY:Float}> = [];
    private var scrollY:Float = 0;
    private var maxScrollY:Float = 0;
    private var contentHeight:Float = 0;
    private var viewHeight:Float = 0;
    private var titleBottomY:Float = 80;

    private var titleText:FlxText;
    private var waitingLabel:FlxText;

    private var waitingForIndex:Int = -1;
    private var flashTimer:Float = 0;

    public var onKeyBindChange:Void->Void;
    private static inline var CLICK_SOUND:String = "assets/sfx/click.wav";

    private static var keyNames:Map<Int, String> = [
        FlxKey.A => "A", FlxKey.B => "B", FlxKey.C => "C", FlxKey.D => "D",
        FlxKey.E => "E", FlxKey.F => "F", FlxKey.G => "G", FlxKey.H => "H",
        FlxKey.I => "I", FlxKey.J => "J", FlxKey.K => "K", FlxKey.L => "L",
        FlxKey.M => "M", FlxKey.N => "N", FlxKey.O => "O", FlxKey.P => "P",
        FlxKey.Q => "Q", FlxKey.R => "R", FlxKey.S => "S", FlxKey.T => "T",
        FlxKey.U => "U", FlxKey.V => "V", FlxKey.W => "W", FlxKey.X => "X",
        FlxKey.Y => "Y", FlxKey.Z => "Z",
        FlxKey.ZERO => "0", FlxKey.ONE => "1", FlxKey.TWO => "2",
        FlxKey.THREE => "3", FlxKey.FOUR => "4", FlxKey.FIVE => "5",
        FlxKey.SIX => "6", FlxKey.SEVEN => "7", FlxKey.EIGHT => "8", FlxKey.NINE => "9",
        FlxKey.SPACE => "Space", FlxKey.ENTER => "Enter", FlxKey.ESCAPE => "Esc",
        FlxKey.BACKSPACE => "Back", FlxKey.TAB => "Tab",
        FlxKey.SHIFT => "Shift", FlxKey.CONTROL => "Ctrl", FlxKey.ALT => "Alt",
        FlxKey.UP => "↑", FlxKey.DOWN => "↓", FlxKey.LEFT => "←", FlxKey.RIGHT => "→",
        FlxKey.F1 => "F1", FlxKey.F2 => "F2", FlxKey.F3 => "F3", FlxKey.F4 => "F4",
        FlxKey.F5 => "F5", FlxKey.F6 => "F6", FlxKey.F7 => "F7", FlxKey.F8 => "F8",
        FlxKey.F9 => "F9", FlxKey.F10 => "F10", FlxKey.F11 => "F11", FlxKey.F12 => "F12",
        FlxKey.NONE => "None"
    ];

    public function new(screenWidth:Float, screenHeight:Float)
    {
        super();
        loadKeyBinds();
        for (i in 0...currentKeys1.length) {
            if (!keyNames.exists(currentKeys1[i])) currentKeys1[i] = defaultKeys1[i];
            if (!keyNames.exists(currentKeys2[i])) currentKeys2[i] = defaultKeys2[i];
        }

        var startY:Float = 100;
        var gap:Float = 55;
        var labelWidth:Float = 80;
        var keyWidth:Float = 80;

        titleText = new FlxText(0, 60, screenWidth, "KEY BINDINGS", 20);
        titleText.color = FlxColor.WHITE;
        titleText.font = "Arial";
        titleText.antialiasing = false;
        titleText.alignment = CENTER;
        add(titleText);

        waitingLabel = new FlxText(0, screenHeight - 50, screenWidth, "", 16);
        waitingLabel.color = FlxColor.YELLOW;
        waitingLabel.font = "Arial";
        waitingLabel.antialiasing = false;
        waitingLabel.alignment = CENTER;
        waitingLabel.visible = false;
        add(waitingLabel);

        contentHeight = startY + actionNames.length * gap;
        viewHeight = screenHeight - 120;
        maxScrollY = Math.max(0, contentHeight - viewHeight);

        // 计算居中偏移
        var totalWidth = labelWidth + 10 + keyWidth + 10 + keyWidth;
        var offsetX = (screenWidth - totalWidth) / 2;

        for (i in 0...actionNames.length) {
            var yPos = startY + i * gap;

            // 动作名称
            var label = new FlxText(offsetX, yPos, labelWidth, actionNames[i] + ":", 18);
            label.color = FlxColor.WHITE;
            label.font = "Arial";
            label.antialiasing = false;
            add(label);
            scrollableElements.push({obj: label, origY: yPos});

            // 主键框
            var boxX1 = offsetX + labelWidth + 10;
            var box = createKeyBox(boxX1, yPos, keyWidth);
            add(box);
            scrollableElements.push({obj: box, origY: yPos - 2});

            // 主键文字
            var keyText1 = new FlxText(boxX1 + 5, yPos + 2, keyWidth - 10, getKeyName(currentKeys1[i]), 18);
            keyText1.color = FlxColor.WHITE;
            keyText1.font = "Arial";
            keyText1.antialiasing = false;
            keyText1.alignment = CENTER;
            add(keyText1);
            keyDisplays1.push(keyText1);
            scrollableElements.push({obj: keyText1, origY: yPos + 2});

            // 主键等待文字
            var waitText1 = new FlxText(boxX1 + 5, yPos + 2, keyWidth - 10, "???", 18);
            waitText1.color = FlxColor.YELLOW;
            waitText1.font = "Arial";
            waitText1.antialiasing = false;
            waitText1.alignment = CENTER;
            waitText1.visible = false;
            add(waitText1);
            waitingTexts1.push(waitText1);
            scrollableElements.push({obj: waitText1, origY: yPos + 2});

            // 主键点击按钮
            var btn1 = createHitButton(boxX1 - 5, yPos - 7, keyWidth + 10, i);
            add(btn1);
            hitButtons.push(btn1);
            scrollableElements.push({obj: btn1, origY: yPos - 7});

            // 副键框
            var boxX2 = boxX1 + keyWidth + 10;
            var box2 = createKeyBox(boxX2, yPos, keyWidth);
            add(box2);
            scrollableElements.push({obj: box2, origY: yPos - 2});

            // 副键文字
            var keyText2 = new FlxText(boxX2 + 5, yPos + 2, keyWidth - 10, getKeyName(currentKeys2[i]), 18);
            keyText2.color = FlxColor.WHITE;
            keyText2.font = "Arial";
            keyText2.antialiasing = false;
            keyText2.alignment = CENTER;
            add(keyText2);
            keyDisplays2.push(keyText2);
            scrollableElements.push({obj: keyText2, origY: yPos + 2});

            // 副键等待文字
            var waitText2 = new FlxText(boxX2 + 5, yPos + 2, keyWidth - 10, "???", 18);
            waitText2.color = FlxColor.YELLOW;
            waitText2.font = "Arial";
            waitText2.antialiasing = false;
            waitText2.alignment = CENTER;
            waitText2.visible = false;
            add(waitText2);
            waitingTexts2.push(waitText2);
            scrollableElements.push({obj: waitText2, origY: yPos + 2});

            // 副键点击按钮
            var btn2 = createHitButton(boxX2 - 5, yPos - 7, keyWidth + 10, i + 8);
            add(btn2);
            hitButtons.push(btn2);
            scrollableElements.push({obj: btn2, origY: yPos - 7});
        }

        updateScroll(0);
    }

    private function createKeyBox(x:Float, y:Float, width:Float):FlxSprite {
        var box = new FlxSprite(x, y - 2);
        box.makeGraphic(Std.int(width), 30, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRect(box, 0, 0, width, 30, FlxColor.TRANSPARENT, {color: FlxColor.WHITE, thickness: 2});
        return box;
    }

    private function createHitButton(x:Float, y:Float, width:Float, index:Int):FlxButton {
        var btn = new FlxButton(x, y, "", function() {
            startWaiting(index);
        });
        btn.makeGraphic(Std.int(width), 34, FlxColor.TRANSPARENT, true);
        btn.label.visible = false;
        return btn;
    }

    private function updateScroll(delta:Float):Void {
        if (maxScrollY == 0) return;
        scrollY += delta;
        scrollY = FlxMath.bound(scrollY, 0, maxScrollY);
        for (item in scrollableElements) {
            if (item.obj != null) {
                item.obj.y = item.origY - scrollY;
                var dist = item.obj.y - titleBottomY;
                item.obj.alpha = dist < 0 ? 0 : (dist < 30 ? dist / 30 : 1);
            }
        }
        titleText.alpha = 1;
    }

    private function startWaiting(index:Int):Void {
        if (waitingForIndex != -1) cancelWaiting();
        waitingForIndex = index;
        flashTimer = 0;
        var isPrimary = index < 8;
        var actionIdx = isPrimary ? index : index - 8;
        var display = isPrimary ? keyDisplays1[actionIdx] : keyDisplays2[actionIdx];
        var waitText = isPrimary ? waitingTexts1[actionIdx] : waitingTexts2[actionIdx];
        display.visible = false;
        waitText.visible = true;
        waitingLabel.visible = true;
        waitingLabel.text = "Press any key for '" + actionNames[actionIdx] + "' " + (isPrimary ? "(Primary)" : "(Secondary)") + " (ESC to cancel)";
        FlxG.sound.play(CLICK_SOUND);
    }

    public function cancelWaiting():Void {
        if (waitingForIndex != -1) {
            var isPrimary = waitingForIndex < 8;
            var idx = isPrimary ? waitingForIndex : waitingForIndex - 8;
            if (isPrimary) {
                keyDisplays1[idx].visible = true;
                waitingTexts1[idx].visible = false;
            } else {
                keyDisplays2[idx].visible = true;
                waitingTexts2[idx].visible = false;
            }
            waitingForIndex = -1;
            waitingLabel.visible = false;
        }
    }

    private function getKeyName(key:Int):String {
        if (!keyNames.exists(key)) return "Key" + key;
        return keyNames[key];
    }

    private function loadKeyBinds():Void {
        if (FlxG.save.data.keyBinds1 != null && FlxG.save.data.keyBinds2 != null) {
            var saved1:Array<Int> = FlxG.save.data.keyBinds1;
            var saved2:Array<Int> = FlxG.save.data.keyBinds2;
            if (saved1.length == defaultKeys1.length && saved2.length == defaultKeys2.length) {
                currentKeys1 = saved1;
                currentKeys2 = saved2;
                return;
            }
        }
        currentKeys1 = defaultKeys1.copy();
        currentKeys2 = defaultKeys2.copy();
    }

    public function handleKeyInput(key:Int):Void {
        if (waitingForIndex == -1) return;
        if (!keyNames.exists(key) && key != FlxKey.NONE) return;

        if (key == FlxKey.ESCAPE) {
            cancelWaiting();
            return;
        }

        var isPrimary = waitingForIndex < 8;
        var actionIdx = isPrimary ? waitingForIndex : waitingForIndex - 8;
        var targetArray = isPrimary ? currentKeys1 : currentKeys2;
        var displayArray = isPrimary ? keyDisplays1 : keyDisplays2;

        targetArray[actionIdx] = key;
        displayArray[actionIdx].text = getKeyName(key);
        updateInputClass();
        saveKeyBinds();
        FlxG.sound.play(CLICK_SOUND);
        cancelWaiting();
        if (onKeyBindChange != null) onKeyBindChange();
    }

    private function updateInputClass():Void {
        try {
            var cls = Type.resolveClass("Input");
            if (cls == null) return;
            var fields = ["up1","up2","down1","down2","left1","left2","right1","right2","jump1","jump2","attack1","attack2","run1","run2","special1","special2"];
            var allKeys = currentKeys1.concat(currentKeys2);
            for (i in 0...fields.length) {
                if (i < allKeys.length) Reflect.setField(cls, fields[i], allKeys[i]);
            }
        } catch (e:Dynamic) {}
    }

    private function saveKeyBinds():Void {
        FlxG.save.data.keyBinds1 = currentKeys1.copy();
        FlxG.save.data.keyBinds2 = currentKeys2.copy();
        FlxG.save.flush();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        var scrollAmount = FlxG.mouse.wheel;
        if (scrollAmount != 0 && maxScrollY > 0) {
            updateScroll(-scrollAmount * 8);
        }
        if (waitingForIndex != -1 && waitingLabel.visible) {
            flashTimer += elapsed;
            var alpha = 0.5 + 0.5 * Math.sin(flashTimer * 6);
            waitingLabel.alpha = alpha;
            var isPrimary = waitingForIndex < 8;
            var idx = isPrimary ? waitingForIndex : waitingForIndex - 8;
            var waitText = isPrimary ? waitingTexts1[idx] : waitingTexts2[idx];
            if (waitText != null) waitText.alpha = alpha;
        }
    }

    override public function destroy():Void {
        cancelWaiting();
        super.destroy();
    }
}