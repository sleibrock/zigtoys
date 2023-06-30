Zigtoys - Demos with WASM
===

# Update: Pause on Developments

In a [recent issue submitted by the lead developer on Zig, Andrew Kelley](https://github.com/ziglang/zig/issues/16270), it seems that Zig will be parting ways with LLVM in the near (or far) future. WebAssembly is a tier 1 target, but I suspect that gutting LLVM from Zig will impact the ability of Zig to create stable WASM output for a while. The last version used in this project was `0.11`, so should you have continued interest in this project, please keep using `0.11`.

I will be pausing active development on this repo for the time until a decision is made about the future of Zig and LLVM. As much as I would love to continue writing Zig, as I believe is an interesting and fun language, the fact that I have to consider and weigh long-term options like this make my continued interest in Zig more difficult. The repo will still be open until then for any and all PRs.

---


Zigtoys is a collection of "toy" applications I have written in Zig, targeting WebAssembly. It is a demonstration of what you can do with some very minimal Zig. The goal is to focus on design and creating composable code that is easy to re-use, with simplicity in mind.

[dev.to](https://dev.to/) articles I have written using this repo:
* [WebAssembly with Zig, Part 1](https://dev.to/sleibrock/webassembly-with-zig-part-1-4onm)
* [WebAssembly with Zig, Part 2](https://dev.to/sleibrock/webassembly-with-zig-pt-ii-ei7)

## Build Command

The Zig compiler options are prone to change, and most recently have changed with version `0.11`. The command to build all source files here with current Zig is as follows:

```shell
$ zig build-lib <file> -target wasm32-freestanding -dynamic -rdynamic -O ReleaseSmall
```

Behavior was changed in Zig's compiler to remove certain implicit behavior, so the `-rdynamic` flag is now required in order to export WASM binaries.

(As it stands, I currently cannot figure out for my life how to navigate the `build.zig` library, so I am ignoring it for now until it's relatively "stable", as just like the compiler options, should be considered always changing)

## Personal Notes on Zig/WASM

Below is a collection of notes I have written when I got started with Zig and WASM compilation. Do not take them as official documentation; there are multiple ways you can approach problems. I try to cover all bases, but this is mostly a self-discovery project.

### Calling Zig from JavaScript

The first thing that you'll want to familiarize yourself is the convention of invoking Zig functions from JavaScript space. In reality you're not calling Zig, you're calling WASM functions, which were compiled from Zig. When Zig is compiled to WASM, they're compiled in a way that conforms to the WebAssembly standard, so there's a basic ABI that Zig must compile for in order for this all to work.

To WebAssembly, there's only four data types: `i32`, `i64`, `f32`, and `f64`. That's right, there's no unsigned values here; it's just enough to make us compatible with probably every JavaScript runtime with minimal issues. If you're passing integers or pointers, they're going to be signed integers. Booleans will be considered integers as well. Anything needing a decimal point is floating-point.

Zig has a lot of types, but has to cram all their typing to meet this ABI. Any `u32` you use in Zig code will more likely than not end up as an `i32`, and anything smaller than that is going to get chucked into an `i32` and padded appropriately. The careful use of your `u8` or `u16`'s or even `u1` may get disregarded, so get yourself comfortable with the 32-bits of space you'll get assigned for almost every variable.

So, for the most part, when you try to call a Zig function, remember that it really only understands *numbers*. Anything else would be futile.

### Okay, So Strings

Passing a string into a WebAssembly function isn't quite so easy. There are ways of working around it with two different trains of thought. But right off that bat:

```javascript
WASMblob.function("Hello world!");
```

Won't amount to much good for us. JavaScript is a dynamically-typed language, meaning it allows us to allocate dynamic-length types like strings on the fly. Once the string is used, it gets deallocated almost immediately after since there's no point in keeping it alive.

Even then, the above function is tricky, because Zig doesn't play the nicest with unknown-sized types. It also can't take slices as inputs, it needs *pointers* to the string in some capacity. JavaScript, when you pass a string like that, doesn't pass a pointer. Most likely because there is no permanent binding for the above-used string. Once the garbage collector throws it away, what is Zig supposed to do about that? It's gone and done.

In some capacity, I find it easier to work with Zig when you treat it as a simple machine with basic interactions. Should you have need to copy string data over, and you want to do it without allocations, consider using static-sized input copy-arrays to copy information over from JavaScript. Use small chunk sizes to 

```zig
const buflen: usize = 32;
var stringbuf: [buflen]u8 = undefined;

export fn setCharAt(index: u32, val: u8) bool {
    if (index >= buflen)
        return false;
    stringbuf[index] = val;
    return true;
}
```

This is a simple function by which WASM will set aside memory for a 32-byte long string to copy information from JavaScript space one byte at a time. It's not hard to implement this in the JavaScript side.

```javascript
var pass_string = function(str) {
    for(var i=0; i < str.length; i++) {
        WASM.setCharAt(i, str[i]);
    }
};
```

Now you have a simple interface to copy strings over slow one at a time, and a Boolean return value indicates if the copy was successful or not.

However, it would be dishonest to say that this is the only way to copy strings into WASM space. When a string in JavaScript is made, it's allocated as a buffer of integers, but in order to pass it along to WASM, you must use a specific array of clamped integers to do so and pass it as a pointer. `UInt8ClampedArray` is a way of doing so. It needs to not get cleaned up by the garbage collector, so it must be bound to a variable in a safe lexical scope area. On top of that, the length of the array must also be passed as well.

### So what about Pointers?

In order for Zig to be compliant to a C ABI for WASM purposes, we first must learn how Zig handles pointers to values.

* `*T` - a pointer to a single item of type `T`
* `[*]T` - a pointer an unknown-sized array of items of type `T`

The asterisk in the middle of square brackets sort of makes sense when you look at definitions like `[10]u8`, which is an array of 10 `u8` integers. However it changes when we look at fix-sized arrays.

* `*[N]T` - a pointer to an `N`-sized array of type `T`

The normal declaration for arrays uses the `[N]T` format, so it makes sense, moving the asterisk is anothing quirk, but okay. Fine.

* `[]T` - this is a *slice*; it contains a pointer to `[*]T` and a length.

Alright, things are fine up until now. However, there's one type of array/slice we left out, called "sentinel-terminated", which means that we can define a type of an array with a value that sits at the end of an array. Meaning if we define `[_]u8{ 1, 2, 3, 4 }`, in the fifth position (index 4) sits a zero to indicate a null-termination. Most things can be zero-terminated, but some arrays will not be, so you can define what the terminator value will be with this syntax.

* `[N:x]T` - an `N`-sized array where the last value in position `N` is expected to be the value of `x` for a given type `T`

This also works on slices, with:

* `[:x]T` - a slice where the last value should be `x` for a slice of type `T`

That felt like an exhausting amount of work, but the null-terminating syntax is helpful. It was always implicit in C language that most arrays should end with `\0` as the terminating character, but here we can define that as part of the *type* itself, so the compiler can do some extra work to figure things out.

Now, a way you can pass strings around to WASM and back would be to pass a pointer to an array of characters, so this would mean a type of `[*]u8`. If you wrote a function to work on top of that, then you're getting somewhere.

```zig
fn do_stuff(buffer: [*]u8) void {
	// do stuff with a buffer
	for (buffer) |char| {
		// ~~ code ~~
	}
}
```

However, this lacks a length. The length of this array is unknown, thanks to the typing, so this doesn't really work. It would be a better idea to use a null-terminating string instead.

```zig
fn do_stuff(buffer: [*:0]u8) void {
	// ...
```

...But JavaScript strings by default aren't null-terminated. In order to get a string fully-working from JavaScript into WASM space, you'd have to fully-copy the string into WASM memory, insert a null-terminator character, then you can pass the pointer to that memory over to Zig. The whole process is honestly quite tedious.

```javascript
var my_string = "hello!";
var ptr_to_str = WASM.allocate_string(my_string.length + 1);
var buffer = Uint8Array(WASM.memory, ptr_to_str, my_string.length + 1);
buffer.set(my_string); // O(n) copy
buffer[my_string.length + 1] = 0; // null terminate it
WASM.do_stuff(ptr_to_str);
```

Note that the allocation *can* fail, so you must also handle a case for if and when that can occur. I didn't define what `allocate_string` might look like, but I leave that up to the reader as an exercise.

### Performance - WASM isn't always the solution

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

### No Zig Errors

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

Zig cannot for some obscure reasons to me use the errors to export to a C ABI. Maybe something about the errors just isn't compatible with C, who knows. But this is fine with me. You normally shouldn't be introducing error-stricken code into your programs that often with WASM; WASM is a tiny little car engine with some memory, the only reasons it should really be failing are out-of-bounds errors, networking failure, or parsing issues. Past that, you should engineer your WASM code in a way that reduces errors to the smallest possible error vector imaginable. It will save you headaches later on in life.

### Defer

The `defer` keyword is popular in programs to release system resources so we don't forget about it much later in larger programs. At the end of scope, if a `defer` keyword was used, it'll execute whatever expression was combined with it.

The `defer` keyword probably... shouldn't be used, if we're dealing with WASM applications. Depending on your applications, it might not be required to allocate and free your memory; because that's not really required. When a user quits your application, the memory is freed by the WebAssembly virtual machine running your code. It's not entirely your responsibility, it's the host environment's job.

If I'm designing a game world and it's goal is to live and run until the user closes out of the webpage/PWA, then it's not entirely necessary to free memory. Maybe if you had a more fleshed out game, then going to menu and starting/loading savefiles, yeah, maybe freeing memory is a fine thing to do. But other than that, these functions may share different scopes, and the `defer` keyword may not make sense when sharing memory across many different Zig functions.


### Enumeration Safety

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
        else => 99, // handles all non-valid values now
    };
}
```

Remember to be conscious of using `enum(T)` to remember exactly what type you put in it. It allows you an easy way of assigning names to numerical values, but WASM will translate it and it won't be technically safe when exposed to the JavaScript environment.
