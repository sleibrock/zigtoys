// cache artifacts in here for PWA purposes
// use the Cache Web API to store items

self.addEventListener('install', (e) => {
    e.waitUntil(
	caches.open('fox-store').then((cache) => cache.addAll([
	    '/zigtoys/toys/gridfill/',
	    '/zigtoys/toys/gridfill/index.html',
	    '/zigtoys/toys/gridfill/game.js',
	    '/zigtoys/toys/gridfill/main.wasm',
	    '/zigtoys/toys/gridfill/icons/apple-icon-114x114.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-120x120.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-144x144.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-152x152.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-180x180.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-57x57.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-60x60.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-72x72.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-76x76.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon.png',
	    '/zigtoys/toys/gridfill/icons/apple-icon-precomposed.png',
	    '/zigtoys/toys/gridfill/icons/ms-icon-144x144.png',
	    '/zigtoys/toys/gridfill/icons/ms-icon-150x150.png',
	    '/zigtoys/toys/gridfill/icons/ms-icon-310x310.png',
	    '/zigtoys/toys/gridfill/icons/ms-icon-70x70.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-144x144.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-192x192.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-36x36.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-48x48.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-72x72.png',
	    '/zigtoys/toys/gridfill/icons/android-icon-96x96.png',
	])),
    );
});

self.addEventListener('fetch', (e) => {
    console.log(e.request.url);
    e.respondWith(
	caches.match(e.request).then((response) => response || fetch(e.request)),
    );
});
