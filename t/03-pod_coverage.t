use Dancer2;
use Dancer2::Plugin::Minion;
use Test::More;
use Test::Pod::Coverage;

pod_coverage_ok(
    "Dancer2::Plugin::Minion",
    {
        also_private => [
            qw/
              BUILDARGS BUILD ClassHooks PluginKeyword dancer_app
              execute_plugin_hook hook keywords on_plugin_import plugin_args
              plugin_setting realms realm realm_providers register register_hook
              register_plugin request var
              /
        ]
    });

done_testing;

