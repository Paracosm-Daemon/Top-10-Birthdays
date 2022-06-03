package;

import flixel.animation.FlxAnimation;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var iconOffsets:Array<Float> = [0, 0];
	private var isPlayer:Bool = false;

	private var char:String = '';
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;

		changeIcon(char);

		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
	override function updateHitbox()
	{
		super.updateHitbox();

		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function setFrame(frame:Int)
	{
		var curAnim:FlxAnimation = animation.curAnim;
		if (curAnim != null) curAnim.curFrame = frame;
	}
	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var frames:Int = 2;
			var grid:Float = 150 * (frames - 1);

			var frameArray:Array<Int> = new Array<Int>();
			for (i in 0...frames) frameArray.push(i);

			var file:Dynamic = Paths.image(getFirstExisting(['icons/$char', 'icons/icon-$char', 'icons/face', 'icons/icon-face']));

			loadGraphic(file); // Load stupidly first for getting the file size
			loadGraphic(file, true, Math.floor(width / frames), Math.floor(height)); // Then load it fr

			iconOffsets[0] = (width - grid) / frames;
			iconOffsets[1] = (width - grid) / frames;

			updateHitbox();

			animation.add(char, frameArray, 0, false, isPlayer);
			animation.play(char);

			this.char = char;
		}
	}

	public function getCharacter():String { return char; }
	private function getFirstExisting(names:Array<String>):String
	{
		for (i in 0...names.length)
		{
			var name:String = names[i];
			if (Paths.fileExists('images/$name.png', IMAGE))
			{
				trace('$name found at index $i');
				return name;
			}
		}
		return null;
	}
}