'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/chromium/canvaskit.wasm": "393ec8fb05d94036734f8104fa550a67",
"canvaskit/chromium/canvaskit.js": "ffb2bb6484d5689d91f393b60664d530",
"canvaskit/skwasm.wasm": "d1fde2560be92c0b07ad9cf9acb10d05",
"canvaskit/skwasm.worker.js": "51253d3321b11ddb8d73fa8aa87d3b15",
"canvaskit/canvaskit.wasm": "d9f69e0f428f695dc3d66b3a83a4aa8e",
"canvaskit/skwasm.js": "95f16c6690f955a45b2317496983dbe9",
"canvaskit/canvaskit.js": "5caccb235fad20e9b72ea6da5a0094e6",
"flutter.js": "6fef97aeca90b426343ba6c5c9dc5d4a",
"main.dart.js": "f8b8d9d15d39927f542e947395189fd3",
"version.json": "f5b6e0ce8482f490da4d9094596d1ad0",
"assets/assets/icons/trades_active.svg": "599319f8335810ca0dc77d533db52bbc",
"assets/assets/icons/lots_active.svg": "94eba17e17ef49a66dea3a5d867e4b21",
"assets/assets/icons/chats_active.svg": "541ee86aeef72befc052487e7ce15d77",
"assets/assets/icons/wallet_active.svg": "4213b86065b655361ff47e094e287eba",
"assets/assets/icons/vite.svg": "8e3a10e157f75ada21ab742c022d5430",
"assets/assets/icons/trades.svg": "15668c074989ea3e1d86faff08d1e297",
"assets/assets/icons/lots.svg": "11694b4cc9ad1d968af8be8310aab1c8",
"assets/assets/icons/chats.svg": "41453cd1b79cd62f85edbe1af53805b1",
"assets/assets/icons/wallet.svg": "5215e7382760b4464c64a861f38abae1",
"assets/assets/icons/user.png": "5a94548d3e86d6ab127663c36226f7c3",
"assets/assets/icons/offer.svg": "f14ad95a9e05efb76ca662b94e913a4c",
"assets/assets/icons/hammer_active.svg": "5544a75ce8ed96af87445b4b63a333f6",
"assets/assets/icons/screp.svg": "e0c5ba632376cda84d2a93e84c661ec3",
"assets/assets/icons/screp_active.svg": "2aace7f75868b04b62c40472cf45d4e4",
"assets/assets/icons/people_active.svg": "0fc236676bcf65d5c824d3c6f3bd84f4",
"assets/assets/icons/hearth.svg": "7c88049dd6f62be7c0f87ef3e7770264",
"assets/assets/icons/sort_active.svg": "63aeb508776a9718ac472b5f142ef3e9",
"assets/assets/icons/hearth_active.svg": "af70fa04fb6c91e5ab1f527ef09cbac0",
"assets/assets/icons/people.svg": "4ad7b4a45a50f586ce15ec539f887b96",
"assets/assets/icons/sort.svg": "d7a969bc2e40b2240f38152edac22b4c",
"assets/assets/icons/like.svg": "e371bd151b49dc6fc846e71826c8a6a8",
"assets/assets/icons/like_active.svg": "0b28512a2b50de22ab3ae0a62822959d",
"assets/assets/bank_icons/sber.png": "b58550ed99fe196cbded70e8f46a637c",
"assets/assets/bank_icons/tbank.png": "2dade0322184c23cf465ca9174821348",
"assets/assets/lots/auctions/placeholder.png": "c859c82d851b334d5700be264d0a575b",
"assets/fonts/MaterialIcons-Regular.otf": "ea8d29da76111ee67b4fcf383a1e878b",
"assets/shaders/ink_sparkle.frag": "f8b80e740d33eb157090be4e995febdf",
"assets/AssetManifest.json": "917066134d94000d42fcd0a649cbb7fa",
"assets/AssetManifest.bin": "69997de780f2b86d4031570da54b20fd",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/NOTICES": "1848517743ffb1184ca2564fd9dbedb8",
"index.html": "8bb23ab0fd82238b170dc70f8d1141bf",
"/": "8bb23ab0fd82238b170dc70f8d1141bf",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"manifest.json": "1df9200be8c0b78858a7e061a432330d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
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
