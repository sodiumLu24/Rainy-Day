package;

import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.particles.FlxEmitter;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.FlxSprite;

import Player;
import Spirit;
import HUD;
import LoadPaths;
import PauseSubState;
import OptionsState;
import Enemy;
import DialogBox;

import sys.io.File;
import sys.FileSystem;

using flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{
    public static var instance:PlayState;

    var player:Player;
    var map:FlxOgmo3Loader;
    var walls:FlxTilemap;
    var spirits:FlxTypedGroup<Spirit>;
    var hud:HUD;
    var enemies:FlxTypedGroup<Enemy>;
    var hudCamera:FlxCamera;

    var ground:FlxTilemap;
    var boundary:FlxTilemap;
    var obstacles:FlxTilemap;
    var decor1:FlxTilemap;
    var decor2:FlxTilemap;
    var decor3:FlxTilemap;
    var allWalls:FlxGroup;
    var flashTimer:Float = 0;

    var fog:FlxTiledSprite;
    var rain:FlxEmitter;

    var dialogBox:DialogBox;
    var stageTimes = [0, 60000, 124000, 160000, 202000]; // 各阶段起始点
    var anySees = false;
    private var interactingSpirit:Bool;
    public static var fromPause:Bool = false;

    private var damageCooldown:Float = 0.0;
    private var slowmoTimer:Float = 0.0;

    var lines = DialogueData.getIntro();

    private var allSpiritsCollected:Bool = false;
    private var finalDialogueTriggered:Bool = false;

    private var endingActive:Bool = false;
    private var endingTimer:Float = 0;
    private var endingTextGroup:FlxGroup;
    private var exiting:Bool = false;

    var bgm:FlxSound;
    var currentStage:Int = -1; // 当前阶段索引
    var maxDist:Float = 400;   // 最大影响距离

    override public function create():Void
    {
        instance = this;
        super.create();

        #if FLX_MOUSE
        FlxG.mouse.visible = false;
        #end

        FlxG.camera.bgColor = FlxColor.BLACK;

        bgm = FlxG.sound.load(LoadPaths.loadPaths("m", "Rainy Alter"));
        bgm.looped = true; // 循环播放
        bgm.play();
        setStage(0);

        hudCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        hudCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(hudCamera);

        loadMapAndLayers();

        player = new Player();
        player.maxHealth = 1.0;
        player.health = 1.0;
        player.camera = FlxG.camera;
        add(player);

        enemies = new FlxTypedGroup<Enemy>();
        add(enemies);

        spirits = new FlxTypedGroup<Spirit>();
        map.loadEntities(placeEntities, "entities");

        while (spirits.length < 5)
        {
            var idx = spirits.length;
            var s = new Spirit(64 + idx * 40, 128 + Math.sin(idx) * 20);
            s.camera = FlxG.camera;
            spirits.add(s);
            add(s);
        }

        for (s in spirits.members)
        {
            if (s.hintText != null)
            {
                add(s.hintText);
                s.hintText.camera = FlxG.camera;
            }
        }

        hud = new HUD(player, spirits.members);
        hud.camera = hudCamera;
        add(hud);

        remove(player);
        add(player);
        remove(enemies);
        add(enemies);
        remove(spirits);
        add(spirits);

        FlxG.camera.follow(player, TOPDOWN, 1);
        FlxG.camera.followLerp = 1;

        FlxG.camera.fade(FlxColor.BLACK, 0.33, true);

        var rain = new FlxEmitter();
        rain.makeParticles(2, 6, 0x868FAEE7, 60);
        rain.x = 0;
        rain.y = -10;
        rain.width = FlxG.width;
        rain.height = 10;
        rain.acceleration.set(0, 400);
        rain.velocity.set(0, 200, 0, 200);
        rain.lifespan.set(0.6, 1.2);
        rain.alpha.set(0.4, 0.8);
        rain.start(false, 0.025, 0);
        add(rain);

        fog = new FlxTiledSprite(LoadPaths.loadPaths("i", "fog"), 1224, 816);
        fog.scrollFactor.set(0, 0);
        fog.alpha = 0.6;

        FlxTween.tween(fog, { alpha: 0.8 }, 5, {
            type: FlxTweenType.PINGPONG,
            ease: FlxEase.sineInOut
        });
        add(fog);

        dialogBox = new DialogBox();
        add(dialogBox);

        dialogBox.startDialogue(lines);
    }

function setStage(index:Int):Void
{
    if (index == currentStage) return;
    if (index < 0 || index >= stageTimes.length) return;

    currentStage = index;
    var targetTime = stageTimes[index];
    // 直接跳转时间（若音乐已播放，time 属性可读写）
    bgm.time = targetTime;
    trace("切换到阶段 " + index + "，时间 " + targetTime);
}

    function loadMapAndLayers():Void
    {
        map = new FlxOgmo3Loader("assets/data/level_dream.ogmo", "assets/data/level_dream.json");

        boundary = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "First_layer");
        boundary.follow();
        boundary.setTileProperties(2, ANY);
        boundary.camera = FlxG.camera;
        add(boundary);
        walls = boundary;

        ground = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "Second_layer");
        ground.follow();
        ground.camera = FlxG.camera;
        add(ground);

        decor1 = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "Third_layer");
        decor1.follow();
        decor1.camera = FlxG.camera;
        add(decor1);

        decor2 = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "Fourth_layer");
        decor2.follow();
        decor2.camera = FlxG.camera;
        add(decor2);

        obstacles = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "baket");
        obstacles.follow();
        obstacles.setTileProperties(2, ANY);
        obstacles.camera = FlxG.camera;
        add(obstacles);

        decor3 = map.loadTilemap(LoadPaths.loadPaths("i", "level_dream"), "Fifth_layer");
        decor3.follow();
        decor3.camera = FlxG.camera;
        add(decor3);

        allWalls = new FlxGroup();
        allWalls.add(boundary);
        allWalls.add(obstacles);
    }

    function placeEntities(entity:EntityData):Void
    {
        var x = entity.x;
        var y = entity.y;
        switch (entity.name)
        {
            case "player":
                player.setPosition(x, y);
            case "spirit":
                var s = new Spirit(x, y);
                s.camera = FlxG.camera;
                spirits.add(s);
                add(s);
            case "enemy":
                var e = new Enemy(x, y);
                e.camera = FlxG.camera;
                enemies.add(e);
                add(e);
            default:
                // ignore
        }
    }

    override public function update(elapsed:Float):Void
    {
        anySees = false;
        for (e in enemies.members) {
    if (e != null && e.exists && e.alive && e.seesPlayer) {
        anySees = true;
        break;
    }
}

        // 计算最近敌人距离
    var nearestDist = getNearestEnemyDistance();

    // 根据距离决定阶段索引
    var targetStage = 0;

    if (!endingActive) {
if (nearestDist < 130 && anySees)
        targetStage = 3;
    // else if (nearestDist < 120)
    //     targetStage = 3;      // 追逐
    else if (nearestDist < 240) 
        targetStage = 2; // 激烈
    else if (nearestDist < 500) 
        targetStage = 1; // 中等
    else targetStage = 0;

    if (targetStage != currentStage) {
        setStage(targetStage);
    }
    }
    
    FlxG.watch.addQuick("Music time: + ", bgm.time / 1000);
    FlxG.watch.addQuick("nearestDist:  ", nearestDist);
    FlxG.watch.addQuick("cansee?:  ", anySees);
        if (FlxG.keys.justPressed.CONTROL) {
            player.spiritCount++;
        }
        if (!finalDialogueTriggered && player.spiritCount >= 5)
        {
            finalDialogueTriggered = true;
            triggerFinalDialogue();
        }

        if (endingActive)
        {
            endingTimer -= elapsed;
            if (endingTimer <= 0)
            {
                exitGame(true);
            }
        }

        flashTimer -= elapsed;
        if (flashTimer <= 0 && Math.random() < 0.001)
        {
            FlxG.camera.flash(FlxColor.WHITE, 0.1);
            flashTimer = 3 + Math.random() * 5;
        }

        fog.scrollX -= 10 * elapsed;
        fog.scrollY += 3 * elapsed;

        if (player.health <= 0.3)
        {
            trace(player.health);
            FlxG.camera.flash(0xABFF3370, 1.1);
        }

        if (FlxG.timeScale < 1)
        {
            slowmoTimer -= elapsed;
            if (slowmoTimer <= 0)
            {
                FlxG.timeScale = 1;
            }
        }

        if (damageCooldown > 0) damageCooldown -= elapsed;

        updateSpiritInteraction();
        hud.updateHUD();

        if (FlxG.keys.justPressed.ESCAPE)
        {
            PlayState.fromPause = true;
            openSubState(new PauseSubState());
        }

        FlxG.collide(player, allWalls);
        if (enemies != null)
        {
            FlxG.collide(enemies, allWalls);
            for (e in enemies.members)
            {
                if (e != null && e.exists && e.alive && FlxG.overlap(e, player))
                {
                    if (damageCooldown <= 0)
                    {
                        FlxG.camera.shake(0.01, 0.2);
                        player.health -= 0.1;
                        damageCooldown = 2.0;
                        trace("Player hit! Remaining health: " + player.health);

                        FlxG.timeScale = 0.5;
                        slowmoTimer = 0.5;

                        e.stun(2.0);

                        if (player.health <= 0)
                        {
                            trace("Player health reached 0! Resetting level.");
                            exitGame(false);
                        }
                    }
                }
            }
        }

        enemies.forEachAlive(checkEnemyVision);

        super.update(elapsed);
    }

    function getNearestEnemyDistance():Float
{
    var nearest = Math.POSITIVE_INFINITY;
    for (e in enemies.members) {
        if (e != null && e.exists && e.alive) {
            var d = FlxMath.distanceBetween(player, e);
            if (d < nearest) nearest = d;
        }
    }
    return nearest;
}

    private function triggerFinalDialogue():Void
    {
        player.active = false;
        for (e in enemies.members)
        {
            if (e != null) e.active = false;
        }

        var lines:Array<{speaker:String, text:String}> = [
            {speaker: "???", text: "WHAT HAVE YOU DONE?"},
            {speaker: "???", text: "HAVE YOU REMEMBERED?"},
            {speaker: "???", text: "HAVE YOU EVER REMEMBERED?"}
        ];

        dialogBox.startDialogue(lines, function() {
            startEndingSequence();
        });
    }

    private function startEndingSequence():Void
{
    if (endingActive) return;
    endingActive = true;
    endingTimer = 5.0;

    hud.visible = false;

    endingTextGroup = new FlxGroup();
    endingTextGroup.camera = hudCamera;
    add(endingTextGroup);

    var totalWords = 1000;          // 增加总量
    var added = 0;
    var timer = new FlxTimer();

    timer.start(0.1, function(t:FlxTimer) {
        for (i in 0...9) {         // 每次生成 8 个
            if (added >= totalWords) {
                t.cancel();
                return;
            }
            var text = new FlxText(
                FlxG.random.float(0, FlxG.width),
                FlxG.random.float(0, FlxG.height),
                0,
                randomCaseString("HAVE YOU EVER REMEMBERED?")
            );
            text.color = FlxColor.WHITE;
            text.font = "Time New Roman";
            text.size = FlxG.random.int(8, 24);  // 缩小字体使密度更高
            text.alpha = FlxG.random.float(0.2, 1);
            text.scrollFactor.set(0, 0);
            endingTextGroup.add(text);

            added++;
            setStage(4);
        }
    }, -1);
}

    private function randomCaseString(original:String):String
    {
        var result = "";
        for (i in 0...original.length) {
            var ch = original.charAt(i);
            if (FlxG.random.bool(50)) {
                result += ch.toUpperCase();
            } else {
                result += ch.toLowerCase();
            }
        }
        return result;
    }

    private function exitGame(deleteKey:Bool):Void
    {
        if (exiting) return;
        exiting = true;

        if (deleteKey) {
            try {
                if (FileSystem.exists("RAM.key")) {
                    FileSystem.deleteFile("RAM.key");
                    trace("RAM.key deleted.");
                }
            } catch (e:Dynamic) {
                trace("Failed to delete RAM.key: " + e);
            }
        }
        Sys.exit(0);
    }

    function checkEnemyVision(enemy:Enemy)
    {
        var enemyPos = enemy.getMidpoint();
        var playerPos = player.getMidpoint();
        var canSee = true;
        for (obj in allWalls.members)
        {
            var tilemap:FlxTilemap = cast obj;
            if (tilemap != null && !tilemap.ray(enemyPos, playerPos))
            {
                canSee = false;
                break;
            }
        }
        enemy.seesPlayer = canSee;
        if (canSee)
        {
            enemy.playerPosition.set(playerPos.x, playerPos.y);
        }
    }

    function updateSpiritInteraction():Void
    {
        var px = player.x + player.width / 2;
        var py = player.y + player.height / 2;

        for (s in spirits.members)
        {
            if (s == null || s.collected) continue;

            var sx = s.x + s.width / 2;
            var sy = s.y + s.height / 2;
            var dx = px - sx;
            var dy = py - sy;
            var dist = Math.sqrt(dx * dx + dy * dy);

            var isCollision = player.overlaps(s);
            var inRange = dist <= 32;

            if (isCollision)
            {
                if (FlxG.keys.pressed.N)
                {
                    s.hintText.text = "Release N to stop";
                    s.hintText.visible = true;
                    s.progress += FlxG.elapsed / 30;
                    player.lockMovement = true;
                    interactingSpirit = true;
                    if (s.progress >= 1)
                    {
                        collectSpirit(s);
                        s.hintText.visible = false;
                        player.lockMovement = false;
                        interactingSpirit = false;
                    }
                }
                else
                {
                    interactingSpirit = false;
                    player.lockMovement = false;
                    s.hintText.text = "Press N to collect";
                    s.hintText.visible = true;
                }
            }
            else if (inRange)
            {
                s.hintText.text = "Come to interact";
                s.hintText.visible = true;
                if (!interactingSpirit) player.lockMovement = false;
            }
            else
            {
                s.hintText.visible = false;
                if (!interactingSpirit) player.lockMovement = false;
            }
        }
    }

    private function collectSpirit(spirit:Spirit):Void
    {
        if (spirit.collected) return;
        spirit.collected = true;
        spirit.alpha = 0.5;
        spirit.hintText.visible = false;
        player.spiritCount++;
        hud.updateHUD();
    }

    override public function destroy():Void
    {
        instance = null;
        if (hudCamera != null)
        {
            if (FlxG.cameras.list.indexOf(hudCamera) != -1)
            {
                FlxG.cameras.remove(hudCamera);
            }
            hudCamera = null;
        }
        super.destroy();
    }
}