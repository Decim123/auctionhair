'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "76f08d47ff9f5715220992f993002504",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm.worker.js": "51253d3321b11ddb8d73fa8aa87d3b15",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"version.json": "f5b6e0ce8482f490da4d9094596d1ad0",
"assets/assets/icons/trades_active.svg": "599319f8335810ca0dc77d533db52bbc",
"assets/assets/icons/lots_active.svg": "94eba17e17ef49a66dea3a5d867e4b21",
"assets/assets/icons/chats_active.svg": "541ee86aeef72befc052487e7ce15d77",
"assets/assets/icons/wallet_active.svg": "4213b86065b655361ff47e094e287eba",
"assets/assets/icons/vite.svg": "8e3a10e157f75ada21ab742c022d5430",
"assets/assets/icons/trades.svg": "15668c074989ea3e1d86faff08d1e297",
"assets/assets/icons/lots.svg": "11694b4cc9ad1d968af8be8310aab1c8",
"assets/assets/icons/user.png": "5a94548d3e86d6ab127663c36226f7c3",
"assets/assets/icons/chats.svg": "41453cd1b79cd62f85edbe1af53805b1",
"assets/assets/icons/offer.svg": "f14ad95a9e05efb76ca662b94e913a4c",
"assets/assets/icons/hammer_active.svg": "5544a75ce8ed96af87445b4b63a333f6",
"assets/assets/icons/screp.svg": "e0c5ba632376cda84d2a93e84c661ec3",
"assets/assets/icons/screp_active.svg": "2aace7f75868b04b62c40472cf45d4e4",
"assets/assets/icons/people_active.svg": "0fc236676bcf65d5c824d3c6f3bd84f4",
"assets/assets/icons/like_active.svg": "0b28512a2b50de22ab3ae0a62822959d",
"assets/assets/icons/send.svg": "cd031be79842fddffe039e01eaf11d1a",
"assets/assets/icons/screp_chat.svg": "88c0f66828936ff2e1b1c4a07fd17fc5",
"assets/assets/icons/wallet.svg": "5215e7382760b4464c64a861f38abae1",
"assets/assets/icons/hearth.svg": "7c88049dd6f62be7c0f87ef3e7770264",
"assets/assets/icons/sort_active.svg": "63aeb508776a9718ac472b5f142ef3e9",
"assets/assets/icons/hearth_active.svg": "af70fa04fb6c91e5ab1f527ef09cbac0",
"assets/assets/icons/people.svg": "4ad7b4a45a50f586ce15ec539f887b96",
"assets/assets/icons/sort.svg": "d7a969bc2e40b2240f38152edac22b4c",
"assets/assets/icons/like.svg": "e371bd151b49dc6fc846e71826c8a6a8",
"assets/assets/bank_icons/sber.png": "b58550ed99fe196cbded70e8f46a637c",
"assets/assets/bank_icons/tbank.png": "2dade0322184c23cf465ca9174821348",
"assets/assets/lots/auctions/placeholder.png": "c859c82d851b334d5700be264d0a575b",
"assets/fonts/MaterialIcons-Regular.otf": "7292eb8f10891bb92cbce87ae97a57fb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "747082ae95743c030af90c44113d1c57",
"assets/AssetManifest.bin": "52dadf275dd7b244617d24a178617810",
"assets/AssetManifest.bin.json": "bd859ac2b74113264fade006795b8e59",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/NOTICES": "6675174cba33b8f320028db5982049bd",
"flutter_bootstrap.js": "705479c5bd53f1ee5c82c86eaf640eaa",
"index.html": "210a688476fb27ee77804d7fe43f88b8",
"/": "210a688476fb27ee77804d7fe43f88b8",
"main.dart.js": "389f179b4b3877330905503701a77660",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"manifest.json": "1df9200be8c0b78858a7e061a432330d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
