package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * 全功能对话框组（适配 320×240 等小分辨率）
 * 用法：
 *   var dialog = new DialogBox();  // 自动适配屏幕
 *   add(dialog);
 *   dialog.startDialogue([...], function() { ... });
 */
class DialogBox extends FlxGroup
{
    // UI 组件
    public var background:FlxSprite;
    public var speakerText:FlxText;
    public var textField:FlxText;
    public var continueHint:FlxText;

    // 状态
    public var isActive:Bool = false;
    public var isTyping:Bool = false;
    private var lines:Array<{speaker:String, text:String}> = [];
    private var currentIndex:Int = 0;
    private var fullText:String = "";
    private var currentCharIndex:Int = 0;
    private var typeTimer:FlxTimer;
    private var onCompleteCallback:Void->Void;
    private var waitingForInput:Bool = false;

    /**
     * @param x     可选，对话框左上角 X，默认居中
     * @param y     可选，对话框左上角 Y，默认居中
     * @param width 可选，对话框宽度，默认屏幕宽度的 90%
     * @param height 可选，对话框高度，默认根据内容自适应（最小 80px）
     */
    public function new(?x:Float, ?y:Float, ?width:Float, ?height:Float)
    {
        super();

        // ---- 计算自适应尺寸 ----
        var screenW = FlxG.width;
        var screenH = FlxG.height;
        var defaultWidth = screenW * 0.9;
        var defaultHeight = 80; // 最小高度
        var textSize = 12;      // 小屏用 12px

        // 如果用户未指定，使用自适应值
        var boxX = (x != null) ? x : (screenW - defaultWidth) / 2;
        var boxY = (y != null) ? y : (screenH - defaultHeight) / 2;
        var boxW = (width != null) ? width : defaultWidth;
        var boxH = (height != null) ? height : defaultHeight;

        // ---- 背景 ----
        background = new FlxSprite(boxX, boxY);
        background.makeGraphic(Std.int(boxW), Std.int(boxH), FlxColor.GRAY);
        background.alpha = 0.8;
        background.scrollFactor.set(0, 0);
        add(background);

        // ---- 说话者名称（位于背景上方） ----
        var speakerSize = 12;
        speakerText = new FlxText(boxX + 6, boxY - speakerSize - 2, boxW - 12, "", speakerSize);
        speakerText.color = FlxColor.YELLOW;
        speakerText.font = "Time New Roman";
        speakerText.antialiasing = true;
        speakerText.scrollFactor.set(0, 0);
        add(speakerText);

        // ---- 对话正文 ----
        textField = new FlxText(boxX + 6, boxY + 6, boxW - 12, "", textSize);
        textField.color = FlxColor.WHITE;
        textField.font = "Time New Roman";
        textField.antialiasing = true;
        textField.scrollFactor.set(0, 0);
        add(textField);

        // ---- 提示（"按空格继续"） ----
        var hintSize = 10;
        continueHint = new FlxText(boxX + 6, boxY + boxH - hintSize - 4, boxW - 12, "Press ANY", hintSize);
        continueHint.color = FlxColor.GRAY;
        continueHint.font = "Time New Roman";
        continueHint.antialiasing = true;
        continueHint.scrollFactor.set(0, 0);
        continueHint.visible = false;
        add(continueHint);

        // 初始隐藏
        visible = false;
        isActive = false;
    }

    /**
     * 开始对话队列
     * @param lines         数组，每项 {speaker:String, text:String}
     * @param onComplete    全部对话结束后的回调
     */
    public function startDialogue(lines:Array<{speaker:String, text:String}>, ?onComplete:Void->Void):Void
    {
        if (lines.length == 0) return;

        this.lines = lines;
        this.onCompleteCallback = onComplete;
        currentIndex = 0;
        visible = true;
        isActive = true;
        waitingForInput = false;
        showNextLine();
    }

    /**
     * 显示下一条对话
     */
    private function showNextLine():Void
    {
        if (currentIndex >= lines.length)
        {
            endDialogue();
            return;
        }

        var entry = lines[currentIndex];
        speakerText.text = entry.speaker;
        fullText = entry.text;
        currentCharIndex = 0;
        isTyping = true;
        waitingForInput = false;
        continueHint.visible = false;

        textField.text = "";
        if (typeTimer != null) typeTimer.cancel();
        typeTimer = new FlxTimer().start(0.05, function(timer:FlxTimer)
        {
            if (currentCharIndex < fullText.length)
            {
                textField.text += fullText.charAt(currentCharIndex);
                currentCharIndex++;
            }
            else
            {
                isTyping = false;
                timer.cancel();
                waitingForInput = true;
                continueHint.visible = true;
            }
        }, 0);
        currentIndex++;
    }

    /**
     * 跳过当前打字（立刻显示完整文本）
     */
    public function skipTyping():Void
    {
        if (isTyping)
        {
            textField.text = fullText;
            isTyping = false;
            if (typeTimer != null) typeTimer.cancel();
            waitingForInput = true;
            continueHint.visible = true;
        }
    }

    /**
     * 结束对话
     */
    private function endDialogue():Void
    {
        visible = false;
        isActive = false;
        isTyping = false;
        waitingForInput = false;
        continueHint.visible = false;
        if (typeTimer != null) typeTimer.cancel();
        if (onCompleteCallback != null) onCompleteCallback();
    }

    /**
     * 外部调用可提前终止对话
     */
    public function close():Void
    {
        endDialogue();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!isActive) return;

        // 按空格跳过打字或推进到下一条
        if (FlxG.keys.justPressed.ANY)
        {
            if (isTyping)
            {
                skipTyping();
            }
            else if (waitingForInput)
            {
                showNextLine();
            }
        }
    }
}


class DialogueData
{
    public static function getIntro():Array<{speaker:String, text:String}>
    {
        return [
            {speaker: "PLAYER", text: "who are you"},
            {speaker: "ENEMY", text: "the one about to kill you"}
        ];
    }

    public static function getGreeting():Array<{speaker:String, text:String}>
    {
        return [
            {speaker: "NPC", text: "Hello!"},
            {speaker: "PLAYER", text: "Hi there."}
        ];
    }
}