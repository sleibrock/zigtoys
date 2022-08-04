// loader for life.zig


request = new XMLHttpRequest();
request.open('GET', 'life.wasm');
request.responseType = 'arraybuffer';
request.send();

var results = null;

var set_cell = null;
var get_neighbors = null;
var advance = null;
var get_char = null;

var running = false;

var pre = document.getElementById("life_pre");
var reset = document.getElementById("button");

var main = function(advancer){
	console.log("Main started");
	var loop = function() {
		var string = "";
		pre.textContent = string;
		for(var i=0; i < 1024; i++) {
			if ((i % 32) == 0)
				string += "\n";
			string += String.fromCharCode(get_char(i));
		}
		pre.textContent = string;
		console.log(string);
		var num_changed = advancer();
		if (num_changed == 0)
			running = false;

		if (running)
			window.requestAnimationFrame(loop);
	};
	loop();
};

request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {
			print: (result) => { console.log(`The result is ${result}`); }
		}
	}).then(result => {
		//const get_pixel_color = result.instance.exports.get_pixel_color;
		set_cell = result.instance.exports.set_cell;
		get_neighbors = result.instance.exports.get_neighbors;
		advance = result.instance.exports.advance;
		get_char = result.instance.exports.get_char;
		results = result.instance.exports;
		wasm_loaded = true;


		// bind an event to the reset button
		reset.onclick = function() {
			console.log("Reset clicked");

			for (var i = 0; i < 500; i++) {
				var randind = Math.random() * 1024;
				set_cell(randind);
			};
			running = true;
			main(advance);
		};
		
		// run code post wasm
		main(advance);
	});
};
