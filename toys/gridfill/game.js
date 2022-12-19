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
    console.log("Start address: " + startaddr);
    console.log("Buffer size: " + bufsize);
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
	if (res == 0) {
	    console.log("Failed to allocate memory");
	    return;
	}
	loaded = true;

	// bind an on-click event for the canvas
	cnv.addEventListener('click', (evt) => {
	    var rect = cnv.getBoundingClientRect();
	    console.log(evt);
	    var w_ratio = (rect.width / 480);
	    var h_ratio = (rect.height / 480);
	    var x = evt.clientX - rect.left;
	    var y = evt.clientY - rect.top;
	    var sx = Math.trunc(x / w_ratio);
	    var sy = Math.trunc(y / h_ratio);
	    console.log(rect);
	    console.log({sx: sx, sy: sy});
	    var res = ZIG.handle_input(sx, sy);
	    console.log("handle_input: " + res);
	})

	main();
    });
};

// end game.js
