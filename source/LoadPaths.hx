package;
using StringTools;

class LoadPaths {
    public static function loadPaths(type:String, name:String):String {
        switch (type) {
            case "ai":
                return "assets/animations/" + name + '.png';
            case "ax":
                return "assets/animations/" + name + '.xml';
            case "c":
                return "assets/images/characters/" + name + '.png';
            case "m":
                return "assets/music/" + name + '.ogg';
            case "s":
                return "assets/sfx/" + name + '.wav';
            case "i":
                return "assets/images/" + name + '.png';
            case "f":
                return "assets/fonts/" + name + '.ttf';
            case "ui":
                return "assets/images/ui/" + name + '.png';
            default:
                return "assets/" + type + "/" + name;
        }
    }
}