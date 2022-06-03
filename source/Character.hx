package;

import flixel.animation.FlxAnimation;
import animateatlas.AtlasFrameMaker;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;


typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var lastNoteHit:Note;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var startedDeath:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		setCharacter(character);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			var curAnim:FlxAnimation = animation.curAnim;
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;
				if (heyTimer <= 0)
				{
					if (specialAnim)
					{
						var curName:String = curAnim.name.toLowerCase();
						var stopAnimation:Bool = switch (curCharacter)
						{
							default: curName == 'hey' || curName == 'cheer';
							case 'exTricky': curName == 'hank';
						}

						if (stopAnimation)
						{
							specialAnim = false;
							curAnim.finish();

							dance(true);
						}
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && curAnim.finished)
			{
				specialAnim = false;
				dance(true);
			}

			var singing:Bool = curAnim.name.startsWith('sing');

			if (singing) holdTimer += elapsed;
			switch (isPlayer)
			{
				case true:
				{
					if (curAnim.name.endsWith('miss') && curAnim.finished && !debugMode) playAnim('idle', true, false, 10);
					if (curAnim.name == 'firstDeath' && curAnim.finished && startedDeath) playAnim('deathLoop');

					if (!singing) holdTimer = 0;
				}
				default:
				{
					if (holdTimer >= (Conductor.stepCrochet / 1000) * singDuration)
					{
						dance();
						holdTimer = 0;
					}
				}
			}

			var loopAnim:String = animation.curAnim.name + '-loop';
			if (curAnim.finished && animation.getByName(loopAnim) != null) playAnim(loopAnim);
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(force:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			switch (danceIdle)
			{
				case true:
				{
					danced = !danced;
					playAnim(danced ? 'danceRight$idleSuffix' : 'danceLeft$idleSuffix', force);

					return;
				}
				default:
				{
					var idleFormat:String = 'idle$idleSuffix';
					if (animation.getByName(idleFormat) != null)
						playAnim(idleFormat, force);
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var lowerName:String = AnimName.toLowerCase();

		if (animOffsets.exists(AnimName)) { var daOffset:Array<Dynamic> = animOffsets.get(AnimName); offset.set(daOffset[0], daOffset[1]); }
		else { offset.set(0, 0); }

		if (curCharacter.startsWith('gf'))
		{
			danced = switch (lowerName)
			{
				case 'singright': false;
				case 'singleft': true;

				case 'singup' | 'singdown': !danced;
				default: danced;
			};
		}
	}

	public function setCharacter(?character:String = "bf")
	{
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		var library:String = 'shared';
		curCharacter = character;

		var characterPath:String = 'characters/$curCharacter.json';
		var path:String = Paths.getPreloadPath(characterPath);

		if (!Assets.exists(path))
			path = Paths.getPreloadPath('characters/$DEFAULT_CHARACTER.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		var rawJson = Assets.getText(path);

		var json:CharacterFile = cast Json.parse(rawJson);
		var spriteType = "sparrow";
		// sparrow
		// packer
		// texture
		if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
			spriteType = "packer";
		if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
			spriteType = "texture";

		frames = switch (spriteType)
		{
			default: Paths.getSparrowAtlas(json.image, library);

			case "packer": Paths.getPackerAtlas(json.image, library);
			case "texture": AtlasFrameMaker.construct(json.image);
		}
		imageFile = json.image;
		if (json.scale != 1)
		{
			jsonScale = json.scale;

			setGraphicSize(Std.int(width * jsonScale));
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		singDuration = json.sing_duration;
		healthIcon = json.healthicon;

		flipX = json.flip_x;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
		}
		if (json.no_antialiasing)
		{
			antialiasing = false;
			noAntialiasing = true;
		}

		if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
			healthColorArray = json.healthbar_colors;

		antialiasing = !noAntialiasing;
		if (!ClientPrefs.globalAntialiasing)
			antialiasing = false;

		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = anim.anim;
				var animName:String = anim.name;

				var animLoop:Bool = anim.loop; // Bruh
				var animFps:Int = anim.fps;

				var animIndices:Array<Int> = anim.indices;

				if (animIndices != null && animIndices.length > 0)
				{
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
		else
		{
			quickAnimAdd('idle', 'BF idle dance');
		}

		originalFlipX = flipX;
		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;

		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf'))
				{
					// var animArray
					if (animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
					{
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
					{
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animation.getByName('singLEFTmiss').frames = oldMiss;
					}
			}*/
		}
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;

			if (danceIdle)
			{
				calc /= 2;
			}
			else
			{
				calc *= 2;
			}

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}