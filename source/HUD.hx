package;

import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import Player;
import flixel.FlxG;

class HUD extends FlxGroup
{
    private var player:Player;
    private var spirits:Array<Spirit>; // 引用所有 Spirit

    // 原有 HUD 元素
    private var healthBar:FlxBar;
    private var staminaBar:FlxBar;
    private var healthText:FlxText;
    private var spiritCountText:FlxText;

    // Spirit 显示元素
    private var icons:Array<FlxSprite> = [];
    private var bars:Array<FlxBar> = [];
    private var countText:FlxText;

    public function new(player:Player, spirits:Array<Spirit>)
    {
        super();
        this.player = player;
        this.spirits = spirits;

        // ---- 原有 HUD ----
        healthBar = new FlxBar(10, 20, LEFT_TO_RIGHT, 100, 10, player, "health", 0, player.maxHealth);
        healthBar.createFilledBar(FlxColor.RED, FlxColor.GREEN);
        add(healthBar);
        healthText = new FlxText(10, 30, 100, "HP", 10);
        healthText.color = FlxColor.WHITE;
        add(healthText);

        staminaBar = new FlxBar(10, 45, LEFT_TO_RIGHT, 100, 10, player, "stamina", 0, Player.MAX_STAMINA);
        staminaBar.createFilledBar(FlxColor.GRAY, FlxColor.YELLOW);
        add(staminaBar);

        // ---- Spirit 显示（原 SpiritDisplay） ----
        var xPos = FlxG.width - 120;
        var yPos = 10;
        var gap = 20;

        for (i in 0...5)
        {
            var s = spirits[i];
            if (s == null) continue;

            var icon = new FlxSprite(xPos + i * gap, yPos);
            icon.loadGraphic(LoadPaths.loadPaths("i", "spirit"));
            icon.setGraphicSize(14, 14);
            add(icon);
            icons.push(icon);

            var bar = new FlxBar(xPos + i * gap, yPos + 16, LEFT_TO_RIGHT, 14, 4, s, "progress", 0, 1);
            bar.createFilledBar(FlxColor.GRAY, FlxColor.GREEN);
            add(bar);
            bars.push(bar);
        }

        countText = new FlxText(xPos, yPos + 30, 100, "0/5", 12);
        countText.color = FlxColor.WHITE;
        add(countText);

        // 原有 Spirit 计数文本（可保留或移除，这里保留但仅显示总数）
        spiritCountText = new FlxText(10, 70, 100, "Spirits: 0/5", 10);
        spiritCountText.color = FlxColor.WHITE;
        add(spiritCountText);
    }

    public function updateHUD():Void
    {
        if (player == null) return;

        // 更新原有 HUD
        healthBar.value = player.health;
        staminaBar.value = player.stamina;

        // 更新 Spirit 显示
        for (i in 0...5)
        {
            var s = spirits[i];
            if (s != null)
            {
                icons[i].alpha = s.collected ? 0.5 : 1;
                bars[i].value = s.progress;
            }
        }
        var collected = 0;
        for (s in spirits) if (s.collected) collected++;
        countText.text = collected + "/5";
        spiritCountText.text = "Spirits: " + collected + "/5";
    }
}