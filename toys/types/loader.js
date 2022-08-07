request = new XMLHttpRequest();
request.open('GET', 'ztypes.wasm');
request.responseType = 'arraybuffer';
request.send();

var do_u32 = null;
var do_u64 = null;
var do_i32 = null;
var do_i64 = null;
var do_str = null;
var do_struct = null;

request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {
			print: function(x) { console.log("Got data"); console.log(x); } 
		}
	}).then(result => {
		do_u32 = result.instance.exports.do_u32;
		do_u64 = result.instance.exports.do_u64;
		do_i32 = result.instance.exports.do_i32;
		do_i64 = result.instance.exports.do_i64;
		do_str = result.instance.exports.do_str;
		do_struct = result.instance.exports.do_struct;

		// create a running body of code
	});
};

