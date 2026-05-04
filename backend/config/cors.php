<?php

/*
|--------------------------------------------------------------------------
| Cross-Origin Resource Sharing (CORS) Configuration
|--------------------------------------------------------------------------
|
| Allows the Flutter web app (running on a random localhost port via
| `flutter run -d chrome`) to call the Laravel API. For dev only — tighten
| `allowed_origins` before shipping.
|
*/

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'storage/*'],

    'allowed_methods' => ['*'],

    // Flutter web picks a random localhost port each run, so we accept any.
    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // Sanctum tokens travel in the Authorization header (not cookies), so
    // we don't need credentials. Keep false to allow `allowed_origins: *`.
    'supports_credentials' => false,
];
