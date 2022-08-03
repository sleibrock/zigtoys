// loader for life.zig


request = new XMLHttpRequest();
request.open('GET', 'life.wasm');
request.responseType = 'arraybuffer';
request.send();

var results = null;

request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {
			print: (result) => { console.log(`The result is ${result}`); }
		}
	}).then(result => {
		//const get_pixel_color = result.instance.exports.get_pixel_color;
		results = result.instance.exports;
		wasm_loaded = true;

		// run code post wasm
	});
};
