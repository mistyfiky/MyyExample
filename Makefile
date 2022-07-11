.DEFAULT_GOAL := checks

clean :
	rm -fr platform var vendor
.PHONY : clean

platform :
	git -c advice.detachedHead=0 clone --depth=1 --branch=v6.4.11.1 https://github.com/shopware/platform.git && rm -fr $@/.git
	composer -d $@ config repositories.$$(jq -r '.name' composer.json) path '..'
	composer -d $@ config minimum-stability dev
	composer -d $@ require --no-install --no-scripts $$(jq -r '.name' composer.json)

platform/vendor : | platform
	composer -d $(firstword $|) install

vendor :
	composer install

ecs-lint ecs : | platform/vendor
	$(firstword $|)/bin/ecs check --config ecs.php
.PHONY : ecs-fix

ecs-fix : | platform/vendor
	$(firstword $|)/bin/ecs check --config ecs.php --fix
.PHONY : ecs-fix

platform/src/Administration/Resources/app/administration/node_modules : export PUPPETEER_SKIP_DOWNLOAD = 1
platform/src/Administration/Resources/app/administration/node_modules : | platform
	npm clean-install --prefix $(dir $@)

eslint-lint eslint : | platform/src/Administration/Resources/app/administration/node_modules
	$(firstword $|)/.bin/eslint --ignore-path .eslintignore --no-error-on-unmatched-pattern --config $(dir $(firstword $|)).eslintrc.js --ext .js,.vue src/Resources/app/administration
.PHONY : eslint-lint

eslint-fix : | platform/src/Administration/Resources/app/administration/node_modules
	$(firstword $|)/.bin/eslint --ignore-path .eslintignore --no-error-on-unmatched-pattern --config $(dir $(firstword $|)).eslintrc.js --ext .js,.vue --fix src/Resources/app/administration
.PHONY : eslint-fix

platform/var/cache/phpstan_dev/Shopware_Core_DevOps_StaticAnalyze_StaticAnalyzeKernelPhpstan_devDebugContainer.xml : | platform platform/vendor
	php $(firstword $|)/src/Core/DevOps/StaticAnalyze/PHPStan/phpstan-bootstrap.php

phpstan : | platform/vendor platform/var/cache/phpstan_dev/Shopware_Core_DevOps_StaticAnalyze_StaticAnalyzeKernelPhpstan_devDebugContainer.xml
	$(firstword $|)/bin/phpstan analyze --configuration phpstan.neon
.PHONY : phpstan

database :
	docker run -it -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=shopware_test -p 3306:3306 --rm mysql
.PHONY : database

phpunit : export DATABASE_URL ?= mysql://root:root@127.0.0.1:3306/shopware
phpunit : | platform/vendor vendor
	$(firstword $|)/bin/phpunit --configuration phpunit.xml
.PHONY : phpunit

checks check : ecs eslint phpstan phpunit
.PHONY : checks
