// loader.js

ZIG = {};
MEM = new WebAssembly.Memory({
    initial: 10,
    maximum: 20,
});
memvals = {};
loaded = false;

cnv = window.document.getElementById("output_cnv");
ctx = cnv.getContext('2d');
img = {};

var main = function() {
    var loop = function() {
	ZIG.update();
	startaddr = ZIG.startAddr();
	endaddr = startaddr + ZIG.getSize();
	memvals = new Uint8ClampedArray(ZIG.memory.buffer.slice(startaddr, endaddr));
	img = new ImageData(memvals, ZIG.getWidth(), ZIG.getHeight());
	ctx.putImageData(img, 0, 0);
	window.requestAnimationFrame(loop);
    };
    loop();
};

window.document.body.onload = function() {
    console.log("Loading WASM");

    WebAssembly.instantiateStreaming(fetch("cnvbuf.wasm"), {
	js: { mem: MEM },
    }).then(res => {
	console.log("WASM loaded");
	ZIG = res.instance.exports;
	ZIG.init();
	loaded = true;

	main();
    });
};
