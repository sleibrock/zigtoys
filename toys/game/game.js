// game.js - load the WASM, display the game, update the engine

var canvas = window.document.getElementById("game_canvas");
var ctx = canvas.getContext('2d');

var Game = {
    'init': null,
    'get_pos': null,
    'set_pos': null,
    'update': null,
    'loaded': false,
    'running': false,
};


var main = function() {
    console.log("Main function started");

    var loop = function() {
	// clear the background
	ctx.fillStyle = "white";
	ctx.fillRect(0, 0, 100, 100);
	for(var x = 0; x < 10; x++) {
	    for(var y = 0; y < 10; y++) {
		var cell = Game.get_pos(x, y);
		if (cell == 1)
		    ctx.fillStyle = "red";
		else if (cell == 2)
		    ctx.fillStyle = "grey";
		else
		    ctx.fillStyle = "white";
		ctx.fillRect(x*10, y*10, (x*10)+10, (y*10)+10);
	    }
	}

	// loop to next frame
	if (Game.running)
	    window.requestAnimationFrame(loop);
    };
    loop();
};

window.document.body.onload = function() {
    var env = { env: {} };
    WebAssembly.instantiateStreaming(fetch("game.wasm"), env).then(result => {
	console.log("Loaded the WASM!");
	Game = result.instance.exports;
	Game.loaded = true;
	Game.init();
	main(); // begin
    });
};

// end
