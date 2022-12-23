Zigtoys - Demos with WASM
===

Zigtoys is a repository dedicated as a Zig experimental playground. It started entirely with me having little-to-no insight into WebAssembly, and with these miniature demo apps I have a little more confidence and insight into the workings of WebAssembly.

## General Rules of Thumb

JavaScript-to-Zig - the types.

JavaScript when calling WASM functions converts types in weird ways, and some things do not work the way you would like it to.

For starters, you might want to forget about the idea of strings entirely. A normal string in JavaScript is a specially-allocated object on the JavaScript heap, and it can be garbage-collected as needed by the JavaScript runtime engine. That is to say, it's lifetime isn't exactly... guaranteed, by any systems for what I can tell, and isn't a reliable method for sharing data.

Sharing a pointer to this array is nothing short of hard, because Zig doesn't have access to the JavaScript memory. Strings are really specialized, heap-allocated lists containing numbers that represent ASCII characters, and as such we would need to come up with strategies in order to share information with Zig.

Let's imagine we have an array of eight bytes that can store messages to pass between Zig/JS space. We can write this in Zig with:

```zig
var stringbuf: [8]u8 = undefined;

export fn setCharAt(index: u32, val: u8) bool {
	if (index >= 8)
		return false;
	stringbuf[index] = val;
	return true;
}
```

And a JavaScript function to iterate through JavaScript strings and pass it in.

```javascript
var pass_string = function(str) {
    for(var i=0; i<str.length; i++) {
		ZIG.setCharAt(i, str[i]);
	}
};
```

By default, Zig works really well when types are `u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`, `f32` and `f64`. However, when you pass values larger than these types into Zig, they aren't implicitly clamped to a value range, and instead you need to take that into consideration when designing applications. If you pass `256` to a `u8` expecting function, it won't be `255`.

However this can impede performance penalties since it's (very tiny) array copying. If you really need to communicate parameter modifications, you might want to consider using numerical values mapped to enumerations in Zig. Unless of course you're designing a text-based application.

### Pointers - usable, but use wisely

Pointers can be used to export a lot of data from the memory buffer, but taking in pointers shouldn't even be considered for public external facing functions. It doesn't exist. As far as Zig is concerned, the `*T` type should refer to an *exact* memory location of *one* item, not many items. A `*[]T` is a slice that needs at *compile-time* to know the length of the array itself.

What you can do:

```zig
const someVar: u32 = 10000;

export fn addrToVar() *u32 {
	return &someVar;
}
```

This is a safe operation as it is a fixed memory address inside our WASM code. Exporting pointers to things inside our WASM is fine. We cannot however do the reverse since JavaScript cannot give away pointer locations in memory and expect to safely share that with Zig. Therefore, the reverse scenario isn't possible.

```zig
// take an address from javascript
// illegal/shouldn't work at all
export fn countItems(items: *[]u32) u32 {
	// unknown array size to zig, not compile-time known
	// ...
}
```

Performance - WASM isn't always the solution

When I say WASM isn't always the solution, I mean it in a very nice way. WASM is an engine that lives inside a C/C++ codebase, and is interpreted in a very deterministic way. That being said, because it lives inside a C/C++ codebase, any WASM code is inherently never going to be as fast as the *actual* browser running it. You can get close, but you'll never reach the sun.

This model of execution can be thought of as the following graph:

```
  [JavaScript]
   ^       ^
  /         \
 v           v
[WASM] <---> [Browser]
```

It is impossible to have WASM without JavaScript being ran somewhere, but once WASM starts running, you don't necessarily need much JavaScript to keep it afloat. Life is easier when you use JavaScript that is *directly* connected to browser-specific code. Web APIs that are dependent upon the browser implementation are fast and are machine code backed in the browser.

You can do a lot of things in WASM and use JavaScript to plug in some holes without creating performance dips, but sometimes it might end up being a lot more peaceful to use external references to functions that the Web APIs can provide. You can fill a 4K resolution video buffer all by yourself with WASM so you can write byte streams to it, or you can let the browser manage the video output aspects by using things like Canvas or WebGL. Your call on whatever makes your life easier. But the browser code will likely be faster.

### Memory - use the allocator!

A hot take issue is that Zig is a radically different language from C/C++ and Rust because of it's approach to memory allocation. Memory isn't implicitly allocated throughout the program via fancy stuff like classes, templates, generics or extreme compile-time magic. Memory is either compile-time known, or dependent upon a runtime allocator.

With this in mind, you can write Zig programs that do not involve allocators, and it's cool! You'll have less memory bugs to worry about and less hair-pulling when you write code that is deterministic, statically known, and no worries about having to assign or free memory from the program space. However, static no-allocation programs can only get you so far in the world before you have to start creating large buffer pools.

In WASM, when exporting Zig, if you have a 1000 element array, and you set it to define, WebAssembly *doesn't know* what that can mean by default, and as such, Zig will provide code that fills the entire thing *with zeroes*. That's right, in your output WASM blob will be an array of elements 1000-wide with all zeroes. That can be 1000 bytes, or it can be 4000 bytes.... or worse, depending if you you use structs with lots of fields.

This affects your WASM size, and the larger your static arrays get, the larger the WASM buffer grows, meaning the slower it will take to carry over the network. This is pretty much not ideal at all, and as such you should defer to memory assignment with allocators and get familiar with them, because they're pretty easy to work with.

The default `std.mem.page_allocator` works really well and when loading WASM modules, the memory management is pretty hands-off and requires zero effort on my part. The only hang-up is that you have to deal with errors yourself in a "C" style way, instead of using mechanisms inside Zig that help us deal with errors (error values, `try` keyword, etc).

### No Error Enumerations

That's right, we can't use Zig errors, something pretty fundamental to the language. Oh well, maybe one day. But for now, any code that makes use of `try` needs to be refactored to use `catch` in the code and deal with the error explicitly.

```zig
// bad - can't use the !T error return
export fn init(alloc: *Allocator) !void {
	var some_mem: [1000]u32 = try alloc.initCapacity(u32, 1000);
}

// ok - using catch to "catch" the error
export fn init(alloc: *Allocator) u32 {
	var some_mem: [1000]u32 = alloc.initCapacity(u32, 1000) catch |err| {
		switch (err) {
			else => { return 0; },
		}
	};
}
```

Zig uses a C ABI to export code into WASM, which is perfectly fine, but changes how we can use the language. Bit of a let down, but it is what it is, and it isn't that much work to get it set up. There's only so many places your code should be yielding errors, and it's typically due to external I/O like open/reading files, memory, system calls or subprocesses. In the case of WASM, you *shouldn't* really have that many problems unless you're dealing with a lot of network-oriented data, like pulling in images or videos over the net.

### Defer

The `defer` keyword is popular in programs to release system resources so we don't forget about it much later in larger programs. At the end of scope, if a `defer` keyword was used, it'll execute whatever expression was combined with it.

The `defer` keyword probably... shouldn't be used, if we're dealing with WASM applications. Depending on your applications, it might not be required to allocate and free your memory; because that's not really required. When a user quits your application, the memory is freed by the WebAssembly virtual machine running your code. It's not entirely your responsibility, it's the host environment's job.

If I'm designing a game world and it's goal is to live and run until the user closes out of the webpage/PWA, then it's not entirely necessary to free memory. Maybe if you had a more fleshed out game, then going to menu and starting/loading savefiles, yeah, maybe freeing memory is a fine thing to do. But other than that, these functions may share different scopes, and the `defer` keyword may not make sense when sharing memory across many different Zig functions.


### Enumerations

Lastly a word about enumerations. If you do this:

```zig
const Entity = enum(u8) {
	CellA = 0,
	CellB = 1,
	CellC = 2,
};

pub fn doWithEntity(ent: Entity) u32 {
	return switch(ent) {
		.CellA => 0,
		.CellB => 1,
		.CellC => 2,
	};
}
```

This code is valid Zig and passes the compiler. What it *doesn't* pass is the user test, because this will not work in a way you would like it to.

```javascript
var do_ent = function(x) {
	return ZIG.doWithEntity(x);
}

console.log(do_ent(3));
```

What is the expected output of this? That's because we don't know! I have no idea what this should actually be returning because the logic just isn't there, and Zig can't do anything with it. The Zig compiler says the enumeration is fully mapped out and checked within the `switch`, but as this gets converted to WASM, there is no check in place for this, because `Entity` gets converted into a `u8`, and instead of checking for `.CellA` or `.CellB`, it actually only checks for `1` or `2`, and these are converted into jump (`JMP`) instructions which move the instruction pointer forwards or backwards. Since none of these cases pass true, then... it probably either doesn't work or gives you zero, which isn't ideal.

In fact I even ran it through Godbolt and this was the output.

```
do:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     al, dil
        mov     byte ptr [rbp - 5], al
        test    al, al
        je      .LBB0_2
        jmp     .LBB0_6
.LBB0_6:
        mov     al, byte ptr [rbp - 5]
        sub     al, 1
        je      .LBB0_3
        jmp     .LBB0_7
.LBB0_7:
        mov     al, byte ptr [rbp - 5]
        sub     al, 2
        je      .LBB0_4
        jmp     .LBB0_1
.LBB0_1:
        movabs  rdi, offset example.do__anon_212
        mov     esi, 23
        xor     eax, eax
        mov     edx, eax
        movabs  rcx, offset .L__unnamed_1
        call    example.panic
```
The `je` instruction jumps on equivalence, but if it doesn't, it'll hop to the next `jmp` instruction to then look at other cases. When all else fails, it proceeds to `.LBB0_1` which will yield a `call` to some panic function. If that panic function doesn't exist, then.... Undefined behavior in WASM maybe?

Either way, consider this a bit of a footgun and don't write state machines without including an extra case to handle for invalid numerical inputs. That way you can include an `else` in the `switch` branch while still covering valid use cases.

```zig
const Entity = enum(u8) {
	CellA = 0,
	CellB = 1,
	CellC = 2,
	Bad = 3,
};

pub fn doWithEntity(ent: Entity) u32 {
	return switch(ent) {
		.CellA => 0,
		.CellB => 1,
		.CellC => 2,
		else => 99,
	};
}
```

Remember to be conscious of using `enum(T)` to remember exactly what type you put in it. It allows you an easy way of assigning names to numerical values, but WASM will translate it and it won't be technically safe when exposed to the JavaScript environment.
