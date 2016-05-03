
TwistedMetal.Preloader = function (game) {

	this.background = null;
	this.preloadBar = null;

	this.ready = false;

};

TwistedMetal.Preloader.prototype = {
	// Load assets.
	preload: function () {
		this.preloadBar = this.add.sprite(120, 200, 'missile-command/preloaderBar');
		this.load.setPreloadSprite(this.preloadBar);
		this.load.image('titlepage', '<%= asset_path('missile-command/title-page.png') %>');
	    this.load.atlas('tank', '<%= asset_path('twisted-metal/tanks.png') %>', '<%= asset_path('twisted-metal/tanks.json') %>');
	    this.load.atlas('enemy', '<%= asset_path('twisted-metal/enemy-tanks.png') %>', '<%= asset_path('twisted-metal/tanks.json') %>');
	    this.load.image('logo', '<%= asset_path('twisted-metal/logo.png') %>');
	    this.load.image('bullet', '<%= asset_path('twisted-metal/bullet.png') %>');
	    this.load.image('earth', '<%= asset_path('twisted-metal/earth.png') %>');
	    this.load.spritesheet('kaboom', '<%= asset_path('twisted-metal/explosion.png') %>', 64, 64, 23);
 
	},

	create: function () {

		this.preloadBar.cropEnabled = false;

		// Start the main menu.
		// this.state.start('MainMenu');
		this.state.start('Game');

	},

	update: function () {

		// if (this.cache.isSoundDecoded('titleMusic') && this.ready == false)
		// {
			// this.ready = true;
			// this.state.start('MainMenu');
		// }

	}

};
