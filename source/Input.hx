package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

class Input
{
    // 主键和副键
    public static var up1:Int = FlxKey.UP;
    public static var up2:Int = FlxKey.W;
    public static var down1:Int = FlxKey.DOWN;
    public static var down2:Int = FlxKey.S;
    public static var left1:Int = FlxKey.LEFT;
    public static var left2:Int = FlxKey.A;
    public static var right1:Int = FlxKey.RIGHT;
    public static var right2:Int = FlxKey.D;
    public static var jump1:Int = FlxKey.SPACE;
    public static var jump2:Int = FlxKey.NONE;
    public static var attack1:Int = FlxKey.Z;
    public static var attack2:Int = FlxKey.NONE;
    public static var run1:Int = FlxKey.SHIFT;
    public static var run2:Int = FlxKey.ALT;
    public static var special1:Int = FlxKey.J;
    public static var special2:Int = FlxKey.NONE;
    // 测试键（交互切换）
    public static var test1:Int = FlxKey.N;
    public static var test2:Int = FlxKey.NONE;

    static function isKeyPressed(key:Int):Bool {
        return FlxG.keys.anyPressed([key]);
    }
    static function isKeyJustPressed(key:Int):Bool {
        return FlxG.keys.anyJustPressed([key]);
    }

    public static function isUp():Bool return isKeyPressed(up1) || isKeyPressed(up2);
    public static function isDown():Bool return isKeyPressed(down1) || isKeyPressed(down2);
    public static function isLeft():Bool return isKeyPressed(left1) || isKeyPressed(left2);
    public static function isRight():Bool return isKeyPressed(right1) || isKeyPressed(right2);
    public static function isJump():Bool return isKeyPressed(jump1) || isKeyPressed(jump2);
    public static function isAttack():Bool return isKeyPressed(attack1) || isKeyPressed(attack2);
    public static function isRun():Bool return isKeyPressed(run1) || isKeyPressed(run2);
    public static function isSpecial():Bool return isKeyPressed(special1) || isKeyPressed(special2);
    public static function isTestJustPressed():Bool return isKeyJustPressed(test1) || isKeyJustPressed(test2);

    public static function isUpJustPressed():Bool return isKeyJustPressed(up1) || isKeyJustPressed(up2);
    public static function isDownJustPressed():Bool return isKeyJustPressed(down1) || isKeyJustPressed(down2);
    public static function isLeftJustPressed():Bool return isKeyJustPressed(left1) || isKeyJustPressed(left2);
    public static function isRightJustPressed():Bool return isKeyJustPressed(right1) || isKeyJustPressed(right2);
    public static function isJumpJustPressed():Bool return isKeyJustPressed(jump1) || isKeyJustPressed(jump2);
    public static function isAttackJustPressed():Bool return isKeyJustPressed(attack1) || isKeyJustPressed(attack2);
    public static function isRunJustPressed():Bool return isKeyJustPressed(run1) || isKeyJustPressed(run2);
    public static function isSpecialJustPressed():Bool return isKeyJustPressed(special1) || isKeyJustPressed(special2);
}