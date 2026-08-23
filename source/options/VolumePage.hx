package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class VolumePage extends FlxGroup
{
    // UI 组件
    public var volumeText:FlxText;
    public var bar:FlxBar;
    public var handle:FlxSprite;

    // 几何参数
    private var barX:Float;
    private var barY:Float;
    private var barWidth:Float;
    private var barHeight:Float;

    // 交互状态
    private var isDragging:Bool = false;
    private var currentTween:FlxTween = null;

    // 回调：当音量改变时通知外部（用于保存）
    public var onVolumeChange:Float->Void;

    public function new(screenWidth:Float, screenHeight:Float)
    {
        super();

        // 音量文字
        volumeText = new FlxText(0, 60, screenWidth, "", 22);
        volumeText.setFormat("Arial", 22, FlxColor.WHITE, CENTER);
        add(volumeText);

        // 滑块参数
        barWidth = 300;
        barHeight = 16;
        barX = (screenWidth - barWidth) / 2;
        barY = 160;

        // 轨道背景
        var track = new FlxSprite(barX, barY);
        track.makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.GRAY);
        add(track);

        // FlxBar
        bar = new FlxBar(barX, barY, LEFT_TO_RIGHT,
                         Std.int(barWidth), Std.int(barHeight),
                         null, null, 0, 1);
        bar.createFilledBar(0xFF444444, 0xFFFFAA00, true, 0xFF000000);
        bar.value = FlxG.sound.volume;
        add(bar);

        // 手柄
        handle = new FlxSprite(0, barY - 6);
        handle.makeGraphic(6, Std.int(barHeight + 12), FlxColor.WHITE);
        handle.origin.set(handle.width / 2, handle.height / 2);
        add(handle);

        updateHandlePosition();
        refreshText();
    }

    /**
     * 设置当前音量（无动画）
     */
    public function setVolume(value:Float, silent:Bool = false):Void
    {
        value = FlxMath.bound(value, 0, 1);
        bar.value = value;
        FlxG.sound.volume = value;
        updateHandlePosition();
        refreshText();
        if (!silent && onVolumeChange != null) {
            onVolumeChange(value);
        }
    }

    /**
     * 平滑滑动到目标值（点击轨道时使用）
     */
    public function startSmoothSlide(targetValue:Float):Void
    {
        if (currentTween != null) {
            currentTween.cancel();
            currentTween = null;
        }

        var startVal = bar.value;
        currentTween = FlxTween.tween(bar, {value: targetValue}, 0.3, {
            ease: FlxEase.quadOut,
            onUpdate: function(_) {
                updateHandlePosition();
                refreshText();
                FlxG.sound.volume = bar.value;
            },
            onComplete: function(_) {
                currentTween = null;
                if (onVolumeChange != null) onVolumeChange(bar.value);
                updateHandlePosition();
                refreshText();
            }
        });
    }

    /**
     * 每帧更新（处理拖拽交互）
     */
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        var mouse = FlxG.mouse.getWorldPosition();
        var mx = mouse.x;
        var my = mouse.y;

        var pad = 10;
        var inBarBounds = (mx >= barX - pad && mx <= barX + barWidth + pad &&
                           my >= barY - pad && my <= barY + barHeight + pad);

        if (FlxG.mouse.justPressed && inBarBounds) {
            // 取消缓动
            if (currentTween != null) {
                currentTween.cancel();
                currentTween = null;
            }

            // 判断是否点击在手柄附近
            var handleLeft = handle.x - 5;
            var handleRight = handle.x + handle.width + 5;
            var isOnHandle = (mx >= handleLeft && mx <= handleRight &&
                              my >= barY - pad && my <= barY + barHeight + pad);

            if (isOnHandle) {
                isDragging = true;
            } else {
                var target = (mx - barX) / barWidth;
                target = FlxMath.bound(target, 0, 1);
                startSmoothSlide(target);
            }
        }

        if (FlxG.mouse.justReleased) {
            if (isDragging && onVolumeChange != null) {
                onVolumeChange(bar.value);
            }
            isDragging = false;
        }

        if (isDragging) {
            if (currentTween != null) {
                currentTween.cancel();
                currentTween = null;
            }
            var ratio = (mx - barX) / barWidth;
            ratio = FlxMath.bound(ratio, 0, 1);
            bar.value = ratio;
            FlxG.sound.volume = ratio;
            updateHandlePosition();
            refreshText();
        }

        if (isDragging && !FlxG.mouse.pressed) {
            isDragging = false;
        }
    }

    // ---------- 辅助方法 ----------
    private function updateHandlePosition():Void
    {
        var posX = barX + bar.value * barWidth;
        handle.x = posX - handle.width / 2;
    }

    private function refreshText():Void
    {
        var pct = Math.round(bar.value * 100);
        volumeText.text = "Volume: " + pct + "%";
    }

    /**
     * 清理资源（取消缓动）
     */
    override public function destroy():Void
    {
        if (currentTween != null) {
            currentTween.cancel();
            currentTween = null;
        }
        super.destroy();
    }
}