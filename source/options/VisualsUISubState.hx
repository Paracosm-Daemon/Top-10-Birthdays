package options;

import flixel.FlxG;

using StringTools;

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Note Splashes', "If unchecked, hitting \"Sick!\" notes won't show particles.", 'noteSplashes', 'bool', true);
		addOption(option);

		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool', false);
		addOption(option);

		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', 'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool', true);
		addOption(option);

		var option:Option = new Option('Reduced Motion', "If checked, extra effects such as the camera moving when a character hits a note are disabled.",
			'reducedMotion', 'bool', false);
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom',
			'bool', true);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency', 'How transparent the health bar and icons should be.', 'healthBarAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		addOption(option);

		var option:Option = new Option('Scroll Underlay', 'How transparent the underlay under your strumline should be.', 'scrollUnderlay', 'percent', 0);
		option.scrollSpeed = 1.6;

		option.minValue = 0;
		option.maxValue = 1;

		option.changeValue = .05;
		option.decimals = 2;

		addOption(option);
		#if !mobile
		var option:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool', false);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end

		super();
	}

	override function destroy()
	{
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.showFPS;
	}
	#end
}