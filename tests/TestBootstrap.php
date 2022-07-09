<?php declare(strict_types=1);

namespace Shopware\Core;

require __DIR__ . '/../platform/src/Core/TestBootstrapper.php';

(new TestBootstrapper())
    ->addCallingPlugin()
    ->setForceInstallPlugins((bool) ($_SERVER['FORCE_INSTALL_PLUGINS'] ?? ''))
    ->setPlatformEmbedded(true)
    ->bootstrap();
