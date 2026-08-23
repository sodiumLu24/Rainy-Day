import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.sound.FlxSound;

using flixel.util.FlxSpriteUtil;

class FSM
{
    public var activeState:Float->Void;
    public function new(initialState:Float->Void)
    {
        activeState = initialState;
    }
    public function update(elapsed:Float)
    {
        activeState(elapsed);
    }
}

class Enemy extends FlxSprite
{
    static inline var WALK_SPEED:Float = 40;
    static inline var CHASE_SPEED:Float = 70;

    var brain:FSM;
    var idleTimer:Float;
    var moveDirection:Float;
    var stepSound:FlxSound;

    public var seesPlayer:Bool;
    public var playerPosition:FlxPoint;

    // 眩晕状态
    public var stunned:Bool = false;
    public var stunTimer:Float = 0;

    public function new(x:Float, y:Float)
    {
        super(x, y);
        var graphic = LoadPaths.loadPaths("c", "enemy");
        loadGraphic(graphic, true, 16, 16);
        setFacingFlip(LEFT, false, false);
        setFacingFlip(RIGHT, true, false);
        animation.add("d_idle", [0]);
        animation.add("lr_idle", [3]);
        animation.add("u_idle", [6]);
        animation.add("d_walk", [0, 1, 0, 2], 6);
        animation.add("lr_walk", [3, 4, 3, 5], 6);
        animation.add("u_walk", [6, 7, 6, 8], 6);
        drag.x = drag.y = 10;
        setSize(8, 8);
        offset.x = 4;
        offset.y = 8;

        brain = new FSM(idle);
        idleTimer = 0;
        seesPlayer = false;
        playerPosition = FlxPoint.get();

        stepSound = FlxG.sound.load(LoadPaths.loadPaths("s", "step"), 0.4);
        stepSound.proximity(x, y, FlxG.camera.target, FlxG.width * 0.6);
    }

    override public function update(elapsed:Float)
    {
        // ---- 眩晕处理 ----
        if (stunned)
        {
            stunTimer -= elapsed;
            velocity.x = velocity.y = 0;
            if (stunTimer <= 0)
            {
                // this.flicker(0);
                stunned = false;
            }
            // 不执行 AI 逻辑
            super.update(elapsed);
            return;
        }

        // 正常 AI 逻辑
        var action = "idle";
        if (velocity.x != 0 || velocity.y != 0)
        {
            action = "walk";
            if (Math.abs(velocity.x) > Math.abs(velocity.y))
            {
                facing = velocity.x < 0 ? LEFT : RIGHT;
            }
            else
            {
                facing = velocity.y < 0 ? UP : DOWN;
            }
            stepSound.setPosition(x + frameWidth / 2, y + height);
            stepSound.play();
        }

        switch (facing)
        {
            case LEFT, RIGHT: animation.play("lr_" + action);
            case UP: animation.play("u_" + action);
            case DOWN: animation.play("d_" + action);
            default:
        }

        brain.update(elapsed);
        super.update(elapsed);
    }

    // ---- 状态函数 ----
    function idle(elapsed:Float)
    {
        if (seesPlayer)
        {
            brain.activeState = chase;
        }
        else if (idleTimer <= 0)
        {
            if (FlxG.random.bool(95))
            {
                moveDirection = FlxG.random.int(0, 8) * 45;
                velocity.setPolarDegrees(WALK_SPEED, moveDirection);
            }
            else
            {
                moveDirection = -1;
                velocity.x = velocity.y = 0;
            }
            idleTimer = FlxG.random.int(1, 4);
        }
        else
            idleTimer -= elapsed;
    }

    function chase(elapsed:Float)
    {
        if (!seesPlayer)
        {
            brain.activeState = idle;
        }
        else
        {
            FlxVelocity.moveTowardsPoint(this, playerPosition, CHASE_SPEED);
        }
    }

    /**
     * 被玩家碰撞时调用，进入眩晕状态
     */
    public function stun(duration:Float):Void
    {
        stunned = true;
        stunTimer = duration;
        velocity.x = velocity.y = 0;
        // 开始闪烁
        this.flicker(duration);
    }
}