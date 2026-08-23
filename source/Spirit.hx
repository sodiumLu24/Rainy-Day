package;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Spirit extends FlxSprite
{
    public var collected:Bool = false;
    public var progress:Float = 0;
    public var hintText:FlxText;

    public function new(x:Float, y:Float)
    {
        super(x, y);
        loadGraphic(LoadPaths.loadPaths("i", "spirit"));
        setGraphicSize(16, 16);
        updateHitbox();

        hintText = new FlxText(0, 0, 0, "", 8);
        hintText.color = FlxColor.WHITE;
        hintText.setBorderStyle(SHADOW, FlxColor.BLACK, 1, 1);
        hintText.visible = false;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (hintText != null && hintText.visible)
        {
            hintText.x = x + width / 2 - hintText.width / 2;
            hintText.y = y - 12;
        }
    }

    override public function destroy():Void
    {
        if (hintText != null)
        {
            hintText.destroy();
            hintText = null;
        }
        super.destroy();
    }
}