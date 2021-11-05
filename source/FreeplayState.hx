package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = []; ///all bpms up to milf
	var beatArray:Array<Int> = [100,100,120,180,150,165,130,150,175,165,110,125,180,180,100,150,159,144,120,190,162];

	var selector:FlxText;
	var curSelected:Int = FlxG.save.data.curselected;
	var curDifficulty:Int = 1;
	var icon:HealthIcon;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var songWait:FlxTimer = new FlxTimer();
	var defaultCamZoom:Float = 1.05;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	private var camZooming:Bool = false;

	var startTimer:FlxTimer;

	var camZoom:FlxTween;

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		Conductor.changeBPM(110);

		if (FlxG.save.data.curselected == null)
			FlxG.save.data.curselected = "0";
		trace('default selected: ' + FlxG.save.data.curselected);

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			songs.push(new SongMetadata(initSonglist[i], 1, 'gf'));
		}

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Looking at the Freeplay song list", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end
		addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);
		addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky', 'spooky', 'monster']);
		addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);
		addWeek(['Avidity'], 4, ['mom']);
		addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);
		
		addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);
		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{

		if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

		///if (curSelected != 4)


		super.update(elapsed);


		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		///var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			Conductor.changeBPM(beatArray[curSelected]);
			FlxG.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			accepted = false;
			
					{
						var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

						trace(poop);
			
						PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = curDifficulty;
			
						PlayState.storyWeek = songs[curSelected].week;
						trace('CUR WEEK' + PlayState.storyWeek);
						LoadingState.loadAndSwitchState(new PlayState());
					}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "   EASY  ]";
			case 1:
				diffText.text = '[ NORMAL ]';
			case 2:
				diffText.text = "[  HARD ";
		}
	}

	override function beatHit()
		{
			super.beatHit();
		
			if (accepted)
				{
					bopOnBeat();
					///iconBop();
					trace(curBeat);
				}
		}

		function bopOnBeat()
			{
				if (accepted)
				{
					if (FlxG.save.data.camzooming)
						{
							if (curSelected == 12)
								{
									
		
											trace('milf');
											if (curBeat % 1 == 0)
												{
													if (curBeat >= 8 && curBeat < 373)
													{
														FlxG.camera.zoom += 0.030;
														camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
													}
		
													if (curBeat >= 168 && curBeat < 200)
														{
																{
																	FlxG.camera.zoom += 0.030;
																}
														}
												}
		
							
										
								}
								else if (curSelected == 18)
									{
												trace('Roses');
												if (curBeat % 2 == 0)
													{
														FlxG.camera.zoom += 0.015;
														camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
													}		
									}
								else if (curSelected == 13)
									{
										
			
												trace('avidity');
												if (curBeat % 1 == 0)
													{
														{
															FlxG.camera.zoom += 0.030;
															camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
														}
		
													}
			
								
											
									}
								else if (curSelected == 9)
									{
										new FlxTimer().start(11.00, function(tmr:FlxTimer)
											{
												trace('blammed');
												if (curBeat % 4 == 0)
													{
														FlxG.camera.zoom += 0.090;
														camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
													}
								
											});
									}
									else if (curSelected == 0)
										{
													if (curBeat % 4 == 0)
														{
															FlxG.camera.zoom += 0.015;
															camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
														}
										
										}
									else if (curBeat % 4 == 0)
										{
											FlxG.camera.zoom += 0.015;
											camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.1);
										}
						}
				}
			}

	var accepted:Bool = true;

	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;
		FlxG.save.data.curselected = curSelected;
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
				{
					FlxG.sound.music.stop();
					songWait.cancel();
					songWait.start(1, function(tmr:FlxTimer) {
					FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
					Conductor.changeBPM(beatArray[curSelected]);
					trace(Conductor.bpm);
					});
				}
		#end
		trace('current selection: ' + curSelected);

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}


		///curSelected = FlxG.save.data.curselected;

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			#if windows
			item.color = FlxColor.WHITE;
            #end
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

		
	/*function iconBop(?_scale:Float = 1.25, ?_time:Float = 0.2):Void {
		iconArray[curSelected].iconScale = iconArray[curSelected].defualtIconScale* _scale;
	
	
		FlxTween.tween(iconArray[curSelected], {iconScale: iconArray[curSelected].defualtIconScale}, _time, {ease: FlxEase.quintOut});
		
	*///}
}   

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
