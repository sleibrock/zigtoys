// loader.js

ZIG = {};
loaded = false;

cnv = window.document.getElementById("output_cnv");
ctx = cnv.getContext('2d');
memvals = {};
img = {};

var main = function() {
    var startaddr = ZIG.startAddr() + 20;
    var bufsize = ZIG.getSize();
    var memvals = new Uint8ClampedArray(ZIG.memory.buffer, startaddr, bufsize);
    var img = new ImageData(memvals, ZIG.getWidth(), ZIG.getHeight());
    var loop = function() {
	ZIG.update();
	ctx.putImageData(img, 0, 0);
	window.requestAnimationFrame(loop);
    };
    loop();
};

window.document.body.onload = function() {
    console.log("Loading WASM");

    WebAssembly.instantiateStreaming(fetch("cnvbuf.wasm"), {
    }).then(res => {
	console.log("WASM loaded");
	ZIG = res.instance.exports;
	ZIG.init();
	loaded = true;

	main();
    });
};

// end loader
