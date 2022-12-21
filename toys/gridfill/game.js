// game.js

var cnv = window.document.getElementById("game_canvas");
var ctx = cnv.getContext('2d');
var toggle = window.document.getElementById("toggle_controls");


var App = {
    zig: null,
    loaded: false,
    array: null,
    img: null,
};

var initialize = function() {
    console.log("Initializing App data");
    var startaddr = App.zig.startAddr();
    var bufsize = App.zig.getSize();
    console.log("Start address: " + startaddr);
    console.log("Buffer size: " + bufsize);
    App.array = new Uint8ClampedArray(
	App.zig.memory.buffer, startaddr, bufsize
    );
    App.img = new ImageData(
	App.array, App.zig.getWidth(), App.zig.getHeight()
    );
}

var update = function() {
    ctx.putImageData(App.img, 0, 0);
};

window.document.body.onload = function() {
    console.log("Loading WASM");

    WebAssembly.instantiateStreaming(fetch("main.wasm"), {
    }).then(res => {
	console.log("WASM loaded");
	App.zig = res.instance.exports;
	date = new Date();
	var res = App.zig.init(640, 480, date.getMilliseconds());
	console.log("Memory allocated: " + res);
	if (res == 0) {
	    console.log("Failed to allocate memory");
	    return;
	}
	App.loaded = true;

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
	    var numc = App.zig.handle_input(sx, sy);
	    console.log({num_filled: numc});
	    update();
	})

	initialize();
	update();
    });
};

// PWA/service worker related code
if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .register('/zigtoys/toys/gridfill/sw.js')
    .then(() => { console.log('Service Worker Registered'); });
}

// end game.js
