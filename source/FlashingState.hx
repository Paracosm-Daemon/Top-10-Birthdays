package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var warnText:FlxText;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press CANCEL to disable them now or go to Options Menu.\n
			Press ACCEPT to turn on flashing lights.\n
			You've been warned!",
		32);

		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);

		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;

			if (accept || back)
			{
				leftState = true;

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				ClientPrefs.reducedMotion = back;
				ClientPrefs.flashing = accept;

				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound(back ? 'cancelMenu' : 'confirmMenu'));

				switch (back)
				{
					case true:
					{
						FlxTween.tween(warnText, { alpha: 0 }, 1, {
							onComplete: function (twn:FlxTween) {
								MusicBeatState.switchState(new TitleState());
							}
						});
					}
					default:
					{
						FlxFlicker.flicker(warnText, 1, .1, false, true, function(flk:FlxFlicker) {
							new FlxTimer().start(.5, function (tmr:FlxTimer) {
								MusicBeatState.switchState(new TitleState());
							});
						});
					}
				}
			}
		}
		super.update(elapsed);
	}
}
