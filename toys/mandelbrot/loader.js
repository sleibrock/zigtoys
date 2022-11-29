request = new XMLHttpRequest();
request.open('GET', 'mandelbrot.wasm');
request.responseType = 'arraybuffer';
request.send();


var cnv = window.document.getElementById("canvas");
var ctx = cnv.getContext("2d");

var wasm_loaded = false;
get_pixel_color = (x, y) => 0;

var main = function() {
	for (var i = 0; i < cnv.width; i++) {
		for (var j = 0; j < cnv.height; j++) {
			var iters = get_pixel_color(i, j);
			ctx.fillStyle = "rgb(" + iters +", "+iters+", "+iters+")";
			ctx.fillRect(i, j, 1, 1);
		}
	}
};


request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {
			print: (result) => { console.log(`The result is ${result}`); }
		}
	}).then(result => {
		get_pixel_color = result.instance.exports.get_pixel_color;
		wasm_loaded = true;

		// create a running body of code
		main();
	});
};

