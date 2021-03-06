package;

import flixel.animation.FlxAnimation;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;

	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var endSoundName:String = 'gameOverEnd';
	public static var loopSoundName:String = 'gameOver';

	public static var characterName:String = 'top10';

	public static var deathSoundLibrary:String = null;
	public static var loopSoundLibrary:String = null;
	public static var endSoundLibrary:String = null;

	public static var instance:GameOverSubstate;
	public static var conductorBPM:Float = 100;

	public static var neededShitsFailed:Int = 2;

	var isFollowingAlready:Bool = false;
	var isEnding:Bool = false;

	var lastBeat:Int = -1;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var swagShader:ColorSwap = null;
	var stageSuffix:String = "";

	public static function resetVariables()
	{
		deathSoundName = 'fnf_loss_sfx';
		characterName = 'top10';

		endSoundName = 'gameOverEnd';
		loopSoundName = 'gameOver';

		deathSoundLibrary = null;
		loopSoundLibrary = null;
		endSoundLibrary = null;

		conductorBPM = 100;
	}

	override function create()
	{
		instance = this;
		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		Conductor.songPosition = 0;
		boyfriend = new Character(x, y, characterName, true);

		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];

		add(boyfriend);
		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName, deathSoundLibrary));
		Conductor.changeBPM(conductorBPM);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));

		add(camFollowPos);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		var dumbassZoom:Float = FlxG.camera.initialZoom;
		var instance:PlayState = PlayState.instance;

		if (instance != null && instance.stageData != null) dumbassZoom = instance.stageData.defaultZoom;
		if (ClientPrefs.camZooms) FlxG.camera.zoom = FlxMath.lerp(dumbassZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1));

		if (controls.ACCEPT) endBullshit();
		if (controls.BACK && !isEnding)
		{
			FlxG.sound.music.stop();

			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			MusicBeatState.switchState(new MainMenuState());
			TitleState.playTitleMusic();
		}

		var curAnim:FlxAnimation = boyfriend.animation.curAnim;
		if (curAnim != null && curAnim.name == 'firstDeath')
		{
			if ((curAnim.curFrame >= 25 || curAnim.finished) && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);

				updateCamera = true;
				isFollowingAlready = true;
			}
			if (curAnim.finished && !boyfriend.startedDeath && !playingDeathSound) coolStartDeath();
		}
		if (FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;
	}

	override function beatHit()
	{
		super.beatHit();
		if (lastBeat != curBeat && boyfriend.startedDeath && !isEnding)
		{
			if (boyfriend.animation.name == 'deathLoop' && boyfriend.animation.finished) boyfriend.playAnim('deathLoop', true);
			if (ClientPrefs.camZooms) FlxG.camera.zoom += .03;
		}
		lastBeat = curBeat;
	}

	function coolStartDeath(?volume:Float = 1):Void
	{
		if (boyfriend.startedDeath) return;

		FlxG.sound.playMusic(Paths.music(loopSoundName, loopSoundLibrary), volume);
		boyfriend.startedDeath = true;

		beatHit();
	}
	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);

			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName, endSoundLibrary));

			new FlxTimer().start(.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
		}
	}
}