package;

import flixel.group.FlxGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import LoadPaths.LoadPaths.loadPaths;

class MenuState extends FlxState
{
	var bg:FlxSprite;
	var titleText:FlxSprite;
	var hintText:FlxText;
	var hintText2:FlxText;
	#if desktop
	var exitButton:FlxButton;
	#end

	override public function create()
	{
		// ---- 自定义鼠标指针 ----
		var sprite = new FlxSprite(LoadPaths.loadPaths("ui", "cursor"));
		FlxG.mouse.load(sprite.pixels);

		// ---- 背景动画 ----
		bg = new FlxSprite(-145, -110);
		bg.loadGraphic(loadPaths("ai", "Rain"), true);
		bg.frames = FlxAtlasFrames.fromSparrow(loadPaths("ai", "Rain"), loadPaths("ax", "Rain"));
		bg.animation.addByPrefix("Rain", "Rain", 30, true);
		bg.animation.play("Rain");
		bg.setGraphicSize(FlxG.width * 1.1, FlxG.height * 1.1);
		bg.antialiasing = true;
		add(bg);

		// ---- 标题图片（淡入 + 上移） ----
		titleText = new FlxSprite(-452, -288, loadPaths("i", "titleText"));
		titleText.setGraphicSize(FlxG.width, FlxG.height);
		titleText.antialiasing = true;
		titleText.alpha = 0;
		titleText.y = -288 - 40;
		add(titleText);

		// ---- 底部提示文字（先添加到状态，但不可见） ----
		hintText = new FlxText(0, FlxG.height - 60, FlxG.width, "Press ENTER to begin", 17);
		hintText.setFormat("Arial", 20, FlxColor.WHITE, CENTER);
		hintText.alpha = 0;
		add(hintText);

		hintText2 = new FlxText(0, FlxG.height - 30, FlxG.width, "Press TAB to set options", 17);
		hintText2.setFormat("Arial", 20, FlxColor.WHITE, CENTER);
		hintText2.alpha = 0;
		add(hintText2);

		// ---- 标题补间（完成后触发提示淡入） ----
		FlxTween.tween(titleText, {
			alpha: 1,
			y: -288
		}, 0.9, {
			ease: FlxEase.quadOut,
			startDelay: 0.2,
			onComplete: function(tween:FlxTween) {
				// 提示淡入（alpha 0→1）
				FlxTween.tween(hintText, {alpha: 1}, 0.6, {
					ease: FlxEase.quadOut,
					onComplete: function(t) {
						// 淡入完成后开始闪烁
						startPulsing(hintText);
						startPulsing(hintText2);
					}
				});
				FlxTween.tween(hintText2, {alpha: 1}, 0.6, {
					ease: FlxEase.quadOut
				});
			}
		});

		// ---- 退出按钮（右上角 X） ----
		#if desktop
		exitButton = new FlxButton(FlxG.width - 28, 8, "X", clickExit);
		exitButton.label.font = "Arial";
		exitButton.label.size = 20;
		exitButton.label.color = FlxColor.WHITE;
		exitButton.makeGraphic(20, 20, 0x00000000);
		add(exitButton);
		#end

		// ---- 背景音乐 ----
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(loadPaths("m", "Rainy"), 1, true);

		// ---- 淡入效果 ----
		FlxG.camera.fade(FlxColor.BLACK, 0.33, true);

		super.create();
	}

	/**
	 * 让文本无限循环脉动闪烁（alpha 0.2 ↔ 1）
	 */
	function startPulsing(text:FlxText):Void
	{
		FlxTween.tween(text, {alpha: 0.2}, 0.5, {
			type: FlxTweenType.PINGPONG,
			ease: FlxEase.sineInOut,
			startDelay: 0
		});
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER)
			clickPlay();
		else if (FlxG.keys.justPressed.TAB)
			clickOptions();

		FlxG.watch.addQuick("Background X", bg.x);
		FlxG.watch.addQuick("Background Y", bg.y);
		FlxG.watch.addQuick("Title Text X", titleText.x);
		FlxG.watch.addQuick("Title Text Y", titleText.y);

		super.update(elapsed);
	}

	function clickPlay()
	{
		FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function()
		{
			FlxG.switchState(new PlayState());
		});
	}

	function clickOptions()
	{
		FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function()
		{
			FlxG.switchState(new OptionsState());
		});
	}

	#if desktop
	function clickExit()
	{
		Sys.exit(0);
	}
	#end
}