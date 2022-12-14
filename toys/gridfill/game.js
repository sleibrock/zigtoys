// game.js

ZIG = {};
loaded = false;

cnv = window.document.getElementById("game_canvas");
ctx = cnv.getContext('2d');
memvals = {};
img = {};

var main = function() {
    var startaddr = ZIG.startAddr();
    var bufsize = ZIG.getSize();
    var memvals = new Uint8ClampedArray(
	ZIG.memory.buffer, startaddr, bufsize
    );
    var img = new ImageData(
	memvals, ZIG.getWidth(), ZIG.getHeight()
    );
    console.log("Got to before loop");
    var loop = function() {
	ZIG.update();
	ctx.putImageData(img, 0, 0);
	window.requestAnimationFrame(loop);
    };
    loop();
};

window.document.body.onload = function() {
    console.log("Loading WASM");

    WebAssembly.instantiateStreaming(fetch("main.wasm"), {
    }).then(res => {
	console.log("WASM loaded");
	ZIG = res.instance.exports;
	date = new Date();
	var res = ZIG.init(640, 480, date.getMilliseconds());
	console.log("Memory allocated: " + res);
	if (res == 0)
	    console.log("Failed to allocate memory");
	loaded = true;

	main();
    });
};

// end game.js
