<?php

use Kirby\Cms\App;

// Load plugin classes manually
require_once __DIR__ . '/src/Helper.php';
require_once __DIR__ . '/src/PageMeta.php';
require_once __DIR__ . '/src/SiteMeta.php';
require_once __DIR__ . '/src/Sitemap.php';
require_once __DIR__ . '/src/SitemapPage.php';

App::plugin('baukastenMeta/meta', [
    'options' => [
        'cache' => true,
        'schema' => true,
        'social' => true,
        'twitter' => false,
        'robots' => true,
        'robots.canonical' => true,
        'robots.index' => true,
        'robots.follow' => true,
        'robots.archive' => true,
        'robots.imageindex' => true,
        'robots.snippet' => true,
        'robots.translate' => true,
        'title.separators' => ['~', '-', '–', '—', ':', '/', '⋆', '·', '•', '~', '×', '*', '‣', '→', '←', '<', '>', '«', '»', '‹', '›', '♠︎', '♣︎', '♥︎', '♦︎', '☙', '❦', '❧', '☭'],
    ],

    'blueprints' => [
        'fields/meta/general-group'             => require __DIR__ . '/blueprints/fields/meta/general-group.php',
        'fields/meta/global-general-group'      => require __DIR__ . '/blueprints/fields/meta/global-general-group.php',
        'fields/meta/global-opengraph-group'    => __DIR__ . '/blueprints/fields/meta/global-opengraph-group.yml',
        'fields/meta/global-robots-group'       => require __DIR__ . '/blueprints/fields/meta/global-robots-group.php',
        'fields/meta/global-schema-group'       => __DIR__ . '/blueprints/fields/meta/global-schema-group.yml',
        'fields/meta/og-image'                  => __DIR__ . '/blueprints/fields/meta/og-image.yml',
        'fields/meta/opengraph-group'           => __DIR__ . '/blueprints/fields/meta/opengraph-group.yml',
        'fields/meta/robots-group'              => require __DIR__ . '/blueprints/fields/meta/robots-group.php',
        'files/meta-logo'                       => __DIR__ . '/blueprints/files/meta-logo.yml',
        'files/meta-og-image'                   => __DIR__ . '/blueprints/files/meta-og-image.yml',
        'tabs/meta/page'                        => require __DIR__ . '/blueprints/tabs/page.php',
        'tabs/meta/site'                        => require __DIR__ . '/blueprints/tabs/site.php',
    ],
    'filesMethods' => require __DIR__ . '/config/files-methods.php',
    'pageMethods' => require __DIR__ . '/config/page-methods.php',
    'siteMethods' => require __DIR__ . '/config/site-methods.php',
    'translations' => [
        'da' => require __DIR__ . '/translations/da.php',
        'de' => require __DIR__ . '/translations/de.php',
        'en' => require __DIR__ . '/translations/en.php',
        'fr' => require __DIR__ . '/translations/fr.php',
        'sv_SE' => require __DIR__ . '/translations/sv_SE.php',
    ],
]);
