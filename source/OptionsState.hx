package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSpriteUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup;
import options.VolumePage;
import options.FullscreenPage;
import options.MiscPage;
import options.KeyBindPage;
import flixel.input.keyboard.FlxKey;
import LoadPaths.LoadPaths.loadPaths;

class OptionsState extends FlxState
{
    private var currentPage:Int = 0;
    private var maxPage:Int = 3;
    private var volumePage:VolumePage;
    private var fullscreenPage:FullscreenPage;
    private var miscPage:MiscPage;
    private var keyBindPage:KeyBindPage;

    private var dots:Array<FlxSprite> = [];
    private var bg:FlxSprite;
    private var title:FlxText;
    private var exitButton:FlxButton;
    private var prevButton:FlxButton;
    private var nextButton:FlxButton;

    var fromGame:Bool = false;
    
    override public function create():Void
    {
        super.create();

        FlxG.mouse.visible = true;
        
        bg = new FlxSprite(-145, -74, "assets/images/options/bg.png");
        bg.setGraphicSize(FlxG.width * 1.1, FlxG.height);
        bg.antialiasing = true;
        add(bg);

        title = new FlxText(88, 0, 480, "OPTIONS", false);
        title.antialiasing = false;
        title.color = FlxColor.WHITE;
        title.setFormat("arial", 30, FlxColor.WHITE);
        add(title);

        createPageDots();

        volumePage = new VolumePage(FlxG.width, FlxG.height);
        fullscreenPage = new FullscreenPage(FlxG.width, FlxG.height);
        miscPage = new MiscPage(FlxG.width, FlxG.height);
        keyBindPage = new KeyBindPage(FlxG.width, FlxG.height);
        add(volumePage);
        add(fullscreenPage);
        add(miscPage);
        add(keyBindPage);

        volumePage.onVolumeChange = function(val:Float) {
            FlxG.save.data.volume = val;
            FlxG.save.flush();
        };
        fullscreenPage.onFullscreenChange = function(fs:Bool) {
            FlxG.save.data.fullscreen = fs;
            FlxG.save.flush();
        };
        miscPage.onSettingChange = function() {
            FlxG.save.data.hardMode = miscPage.isHardMode;
            FlxG.save.data.showDamage = miscPage.showDamageNumbers;
            FlxG.save.data.showHealthBar = miscPage.showHealthBar;
            FlxG.save.flush();
        };
        keyBindPage.onKeyBindChange = function() {};

        prevButton = new FlxButton(20, FlxG.height / 4 - 30, "<", function() { changePage(-1); });
        prevButton.label.font = "Arial";
        prevButton.label.size = 50;
        prevButton.setGraphicSize(50, 50);
        prevButton.updateHitbox();
        prevButton.makeGraphic(50, 50, 0x00000000);
        prevButton.label.color = FlxColor.WHITE;
        add(prevButton);

        nextButton = new FlxButton(FlxG.width - 70, FlxG.height / 4 - 30, ">", function() { changePage(1); });
        nextButton.label.font = "Arial";
        nextButton.label.size = 50;
        nextButton.setGraphicSize(50, 50);
        nextButton.updateHitbox();
        nextButton.makeGraphic(50, 50, 0x00000000);
        nextButton.label.color = FlxColor.WHITE;
        add(nextButton);

        exitButton = new FlxButton(FlxG.width - 28, 8, "X", function(){
            onBack();
        });
        exitButton.label.font = "Arial";
        exitButton.label.size = 20;
        exitButton.label.color = FlxColor.WHITE;
        exitButton.makeGraphic(20, 20, 0x00000000);
        add(exitButton);

        loadSettings();
        showPage(0);
        updateDots();
    }

    private function createPageDots():Void
    {
        var dotSize = 14;
        var gap = 20;
        var totalWidth = (maxPage + 1) * (dotSize + gap) - gap;
        var startX = (FlxG.width - totalWidth) / 2;
        var y = 40;
        for (i in 0...maxPage + 1) {
            var dot = new FlxSprite(startX + i * (dotSize + gap), y);
            dot.makeGraphic(dotSize, dotSize, FlxColor.WHITE);
            add(dot);
            dots.push(dot);
        }
    }

    private function updateDots():Void
    {
        for (i in 0...dots.length) {
            var dot = dots[i];
            var isCurrent = (i == currentPage);
            var size = Std.int(dot.width);
            dot.makeGraphic(size, size, isCurrent ? FlxColor.WHITE : FlxColor.TRANSPARENT);
            if (!isCurrent) {
                FlxSpriteUtil.drawLine(dot, 0, 0, size, 0);
            }
        }
    }

    private function changePage(delta:Int):Void
    {
        var newPage = currentPage + delta;
        if (newPage < 0) newPage = maxPage;
        else if (newPage > maxPage) newPage = 0;
        if (newPage == currentPage) return;
        if (currentPage == 3) keyBindPage.cancelWaiting();
        currentPage = newPage;
        showPage(currentPage);
        updateDots();
    }

    private function showPage(page:Int):Void
    {
        volumePage.visible = false;
        fullscreenPage.visible = false;
        miscPage.visible = false;
        keyBindPage.visible = false;
        volumePage.active = false;
        fullscreenPage.active = false;
        miscPage.active = false;
        keyBindPage.active = false;

        switch (page) {
            case 0: volumePage.visible = volumePage.active = true;
            case 1: fullscreenPage.visible = fullscreenPage.active = true;
            case 2: miscPage.visible = miscPage.active = true;
            case 3: keyBindPage.visible = keyBindPage.active = true;
        }
    }

    private function loadSettings():Void
    {
        if (FlxG.save.data.volume != null) volumePage.setVolume(FlxG.save.data.volume, true);
        if (FlxG.save.data.fullscreen != null) fullscreenPage.setFullscreen(FlxG.save.data.fullscreen);
        var hardMode:Bool = FlxG.save.data.hardMode != null ? FlxG.save.data.hardMode : false;
        var showDamage:Bool = FlxG.save.data.showDamage != null ? FlxG.save.data.showDamage : false;
        var showHealth:Bool = FlxG.save.data.showHealthBar != null ? FlxG.save.data.showHealthBar : false;
        miscPage.setStates(hardMode, showDamage, showHealth);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (keyBindPage.visible && keyBindPage.active) {
            keyCheck();
        }

        if (volumePage.visible) volumePage.update(elapsed);
        if (fullscreenPage.visible) fullscreenPage.update(elapsed);
        if (miscPage.visible) miscPage.update(elapsed);
        if (keyBindPage.visible) keyBindPage.update(elapsed);
    }

    private function keyCheck():Void {
        var keyPressed:Int = -1;
        var validKeys:Array<Int> = [
            FlxKey.A, FlxKey.B, FlxKey.C, FlxKey.D, FlxKey.E, FlxKey.F, FlxKey.G,
            FlxKey.H, FlxKey.I, FlxKey.J, FlxKey.K, FlxKey.L, FlxKey.M, FlxKey.N,
            FlxKey.O, FlxKey.P, FlxKey.Q, FlxKey.R, FlxKey.S, FlxKey.T, FlxKey.U,
            FlxKey.V, FlxKey.W, FlxKey.X, FlxKey.Y, FlxKey.Z,
            FlxKey.ZERO, FlxKey.ONE, FlxKey.TWO, FlxKey.THREE, FlxKey.FOUR,
            FlxKey.FIVE, FlxKey.SIX, FlxKey.SEVEN, FlxKey.EIGHT, FlxKey.NINE,
            FlxKey.SPACE, FlxKey.ENTER, FlxKey.ESCAPE, FlxKey.BACKSPACE,
            FlxKey.TAB, FlxKey.SHIFT, FlxKey.CONTROL, FlxKey.ALT,
            FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT,
            FlxKey.F1, FlxKey.F2, FlxKey.F3, FlxKey.F4, FlxKey.F5, FlxKey.F6,
            FlxKey.F7, FlxKey.F8, FlxKey.F9, FlxKey.F10, FlxKey.F11, FlxKey.F12
        ];
        for (k in validKeys) {
            if (FlxG.keys.anyJustPressed([k])) {
                keyPressed = k;
                break;
            }
        }
        if (keyPressed != -1) {
            keyBindPage.handleKeyInput(keyPressed);
        }
    }

    private function onBack():Void
{
    keyBindPage.cancelWaiting();
    volumePage.destroy();
    fullscreenPage.destroy();
    miscPage.destroy();
    keyBindPage.destroy();

    if (fromGame) {
        FlxG.switchState(new PlayState()); // 返回游戏
    } else {
        FlxG.switchState(new MenuState()); // 返回主菜单
    }
}

    override public function destroy():Void
    {
        keyBindPage.cancelWaiting();
        volumePage.destroy();
        fullscreenPage.destroy();
        miscPage.destroy();
        keyBindPage.destroy();
        super.destroy();
    }
}