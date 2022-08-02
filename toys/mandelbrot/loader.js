request = new XMLHttpRequest();
request.open('GET', 'simple.wasm');
request.responseType = 'arraybuffer';
request.send();

request.onload = function() {
	var bytes = request.response;
	WebAssembly.instantiate(bytes, {
		env: {
			print: (result) => { console.log(`The result is ${result}`); }
		}}).then(result => {
			const add = result.instance.exports.add;
			add(1, 2);
		});
};
