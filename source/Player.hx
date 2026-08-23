package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class Player extends FlxSprite
{
    static inline var SPEED:Float = 100;
    static inline var RUN_SPEED_MULT:Float = 1.5;
    public static inline var MAX_STAMINA:Float = 100;
    static inline var STAMINA_DRAIN:Float = 20;
    static inline var STAMINA_RECOVER_IDLE:Float = 15;
    static inline var STAMINA_RECOVER_WALK:Float = 5;
    static inline var STEP_COOLDOWN:Float = 0.35;

    public var health:Float = 100;
    public var maxHealth:Float = 100;
    public var stamina:Float = MAX_STAMINA;
    public var spiritCount:Int = 0;

    public var lockMovement:Bool = false;

    private var stepSound:FlxSound;
    private var flashCooldown:Float = 0;
    private var stepTimer:Float = 0;

    public function new(x:Float = 0, y:Float = 0)
    {
        super(x, y);
        loadGraphic(LoadPaths.loadPaths("c", "Na3Lu"), true, 16, 16);
        setFacingFlip(LEFT, false, false);
        setFacingFlip(RIGHT, true, false);
        animation.add("d_idle", [0]);
        animation.add("lr_idle", [3]);
        animation.add("u_idle", [6]);
        animation.add("d_walk", [0, 1, 0, 2], 6);
        animation.add("lr_walk", [3, 4, 3, 5], 6);
        animation.add("u_walk", [6, 7, 6, 8], 6);

        drag.x = drag.y = 800;
        setSize(8, 8);
        offset.set(4, 8);

        stepSound = FlxG.sound.load(LoadPaths.loadPaths("s", "step"));
        stepSound.volume = 0.3;
    }

    override public function update(elapsed:Float):Void
    {
        stepTimer -= elapsed;

        // ---- 移动逻辑（仅设置速度，不处理体力） ----
        if (lockMovement)
        {
            velocity.set(0, 0);
        }
        else
        {
            updateMovement(elapsed);
        }

        // ---- 脚步声 ----
        if (!lockMovement && (velocity.x != 0 || velocity.y != 0) && touching == NONE && stepTimer <= 0)
        {
            stepSound.play();
            stepTimer = STEP_COOLDOWN;
        }

        // ---- 调用父类 update（处理碰撞，更新 touching 和 velocity） ----
        super.update(elapsed);

        // ---- 体力消耗与恢复（在碰撞之后） ----
        if (!lockMovement)
        {
            var isMoving = (velocity.x != 0 || velocity.y != 0);
            var shouldConsume = isRunning() && stamina > 0 && touching == NONE && isMoving;

            if (shouldConsume)
            {
                stamina -= STAMINA_DRAIN * elapsed;
                if (stamina < 0) stamina = 0;
            }
            else
            {
                // 恢复体力：行走或站立
                var recover = isMoving ? STAMINA_RECOVER_WALK : STAMINA_RECOVER_IDLE;
                stamina = Math.min(MAX_STAMINA, stamina + recover * elapsed);
            }
        }
        else
        {
            // 锁定状态（如交互）下恢复体力
            stamina = Math.min(MAX_STAMINA, stamina + STAMINA_RECOVER_IDLE * elapsed);
        }
    }

    private function updateMovement(elapsed:Float):Void
    {
        var up = Input.isUp();
        var down = Input.isDown();
        var left = Input.isLeft();
        var right = Input.isRight();

        if (up && down) up = down = false;
        if (left && right) left = right = false;

        // 是否按住奔跑键且体力>0
        var shouldRun = isRunning() && stamina > 0;
        var baseSpeed = shouldRun ? SPEED * RUN_SPEED_MULT : SPEED;

        var moveX:Float = 0;
        var moveY:Float = 0;

        if(up) moveY -= 1;
        if(down) moveY += 1;
        if(left) moveX -= 1;
        if(right) moveX += 1;

        // 归一化向量
        if(moveX != 0 || moveY != 0)
        {
            var len = Math.sqrt(moveX*moveX + moveY*moveY);
            moveX /= len;
            moveY /= len;

            velocity.x = moveX * baseSpeed;
            velocity.y = moveY * baseSpeed;

            // 朝向更新
            if(Math.abs(moveX) > Math.abs(moveY))
                facing = moveX < 0 ? LEFT : RIGHT;
            else
                facing = moveY < 0 ? UP : DOWN;
        }
        else
        {
            velocity.x = velocity.y = 0;
        }

        // 动画（基于 velocity，但碰撞后 velocity 会被修改，这里只做初步设定）
        var action = (velocity.x != 0 || velocity.y != 0) ? "walk" : "idle";
        switch (facing)
        {
            case LEFT, RIGHT: animation.play("lr_" + action);
            case UP: animation.play("u_" + action);
            case DOWN: animation.play("d_" + action);
            default:
        }
    }

    private function isRunning():Bool
    {
        return Input.isRun();
    }

    override public function destroy():Void
    {
        stepSound.stop();
        super.destroy();
    }
}