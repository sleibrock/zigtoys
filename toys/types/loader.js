request = new XMLHttpRequest();
request.open('GET', 'ztypes.wasm');
request.responseType = 'arraybuffer';
request.send();

var loaded = false;
var ZIG = {};

request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {}
	}).then(result => {
	    loaded = true;
	    ZIG = result.instance.exports;
	    ZIG.init();
	    // create a running body of code
	});
};

var fill_up = function(arr) {
    if (loaded)
	for(var i = 0; i < 1024; i++)
	    arr[i] = ZIG.get(i);
};

var bytes = new Uint8Array(1024);

// end
