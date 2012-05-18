package MT::Plugin::CheckPluginsModified;
use strict;
use warnings;
use base 'MT::Plugin';

our $VERSION = '0.02';
our $NAME = ( split /::/, __PACKAGE__ )[-1];

my $plugin = __PACKAGE__->new(
    {   name        => $NAME,
        id          => lc $NAME,
        key         => lc $NAME,
        version     => $VERSION,
        author_link => 'https://github.com/masiuchi',
        plugin_link =>
            'https://github.com/masiuchi/mt-plugin-check-plugins-modified',
        description =>
            'Restart FastCGI process if there are some changes in plugins directory.',
        init_request => \&_init_req,
    }
);
MT->add_plugin($plugin);

sub _init_req {
    if ( $ENV{FAST_CGI} ) {
        my $touch_file = 'check_plugins_modified';
        my $touch_dir  = MT->config->TempDir;
        if ( !( -d $touch_dir ) ) {
            return;    # error
        }

        my $plugin_path = MT->config->PluginPath;
        if ( !( -d $plugin_path ) ) {
            return;    # error
        }

        my $cmd_check_removed = "find $plugin_path | wc -l";
        my $file_num = `$cmd_check_removed`;

        require File::Spec;
        my $touch_path
            = File::Spec->catfile( MT->config->TempDir, $touch_file );

        if ( -e $touch_path ) {
            my $cmd_check_modified
                = "find $plugin_path -newer $touch_path";
            my $ret = `$cmd_check_modified`;

            open my $fh, '<', $touch_path;
            my $prev_file_num = readline $fh;
            close $fh;

            chomp $prev_file_num;

            if ( $file_num == $prev_file_num && !$ret ) {
                return;    # no change
            }
        }

        # some changes
        open my $fh, '>', $touch_path;
        print $fh $file_num;
        close $fh;

        require MT::Touch;
        MT::Touch->touch( 0, 'config' );
    }
}

1;
__END__
