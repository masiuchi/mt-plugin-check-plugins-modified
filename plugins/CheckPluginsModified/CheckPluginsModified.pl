package MT::Plugin::CheckPluginsModified;
use strict;
use warnings;
use base 'MT::Plugin';

our $VERSION = '0.01';
our $NAME    = ( split /::/, __PACKAGE__ )[-1];

my $plugin = __PACKAGE__->new({
    name         => $NAME,
    id           => lc $NAME,
    key          => lc $NAME,
    version      => $VERSION,
    author_link  => 'https://github.com/masiuchi',
    plugin_link  => 'https://github.com/masiuchi/mt-plugin-check-plugins-modified',
    description  => 'Restart FastCGI process if there are some changes in plugins directory.',
    init_request => \&_init_req,
});
MT->add_plugin( $plugin );

sub _init_req {
    if ( $ENV{FAST_CGI} ) {
        my $touch_file = 'check_plugins_modified';
        my $touch_dir  = MT->config->TempDir;
        if ( !( -d $touch_dir ) ) {
            return;  # error
        }

        require File::Spec;
        my $touch_path = File::Spec->catfile( MT->config->TmpDir, $touch_file );

        if ( -e $touch_path ) {
            my $plugin_path = MT->config->PluginPath;
            if ( !( -d $plugin_path ) ) {
                return;  # error
            }

            my $cmd_check = "find $plugin_path -type f -newer $touch_path";
            my $ret       = `$cmd_check`;
            if ( !$ret ) {
                return;  # no change
            }
        }

        # some changes
        my $cmd_touch = "touch $touch_path";
        `$cmd_touch`;

        require MT::Touch;
        MT::Touch->touch( 0, 'config' );
    }
}

1;
__END__
