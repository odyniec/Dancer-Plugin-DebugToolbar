package Dancer::Plugin::DebugToolbar;

=head1 NAME

Dancer::Plugin::DebugToolbar - A debugging toolbar for Dancer web applications

=cut

use strict;

use Dancer ':syntax';
use Dancer::App;
use Dancer::Plugin;
use Dancer::Route::Registry;
use File::ShareDir;
use File::Spec::Functions qw(catfile);
use Scalar::Util qw(blessed looks_like_number);
use Time::HiRes qw(time);

our $VERSION = '0.01';

# Distribution-level shared data directory
my $dist_dir = File::ShareDir::dist_dir('Dancer-Plugin-DebugToolbar');

# Information to be displayed to the user
my $info = {};
my $time_start;
my $toolbar_enabled = 0;
my $base = '/dancer-debug-toolbar';
my $route_pattern;

# Template for the HTML code to be appended to the requested page
my $template = <<'END';
<script type="text/javascript" src="%BASE%/js/init.js"></script>
<script type="text/javascript">
dancer_plugin_debugtoolbar.html = '%HTML%';
dancer_plugin_debugtoolbar.info = '%INFO%';
</script>
<script type="text/javascript" src="%BASE%/js/jquery.min.js"></script>
<script type="text/javascript" src="%BASE%/js/yaml_min.js"></script>
<script type="text/javascript" src="%BASE%/js/toolbar.js"></script>
<style type="text/css">
@import url("%BASE%/css/toolbar.css");
</style>
END

sub _value_html {
    my ($value, $level, $omit_type) = @_;
    my $s = '';
    
    if (UNIVERSAL::isa($value, "HASH")) {
        # Hash
        if (!$omit_type) {
            if (my $class = blessed($value)) {
                $s .= '<div class="value">' .
                    '<a href="http://search.cpan.org/perldoc?' . $class .
                    '">' . $class . '</a></div>';
            }
            else {
                $s .= '<div class="value">HASH</div>';
            }
        }
        
        if ($level < 5) {
            $s .= '<div class="sub hash" style="display: none;">' .
                _build_data_html($value, $level + 1) . '</div>';
        }
    }
    elsif (UNIVERSAL::isa($value, "ARRAY")) {
        # Array
        if (!$omit_type) {
            $s .= '<div class="value">ARRAY</div>';
        }
        
        if ($level < 5) {
            $s .= '<div class="sub array" style="display: none;">' .
                _build_data_html($value, $level + 1) . '</div>';
        }
    }
    elsif (looks_like_number($value)) {
        # Number
        $s .= '<div class="value value-number">' . $value . '</div>';
    }
    elsif (defined $value) {
        # String
        $s .= '<div class="value value-string">&quot;' . $value .
            '&quot;</div>';
    }
    elsif (!defined $value) {
        # Undefined
        $s .= '<div class="value value-undefined">undefined</div>';
    }
    else {
        $s .= '<div class="value">' . $value . '</div>';
    }
    
    return $s;
}

sub _build_data_html {
    my ($vars, $level, $no_sort) = @_;
    
    $level = $level || 0;

    my $s = '<ul>';        

    if (UNIVERSAL::isa($vars, "Dancer::Plugin::DebugToolbar::_hash_set")) {
        if (scalar keys %$vars > 0) {
            foreach my $name ($no_sort ? keys %$vars : sort keys %$vars) {
                $s .= '<li><div class="field">';
                $s .= '<span class="set name">' . $name . '</span></div>';
                $s .= _value_html($vars->{$name}, $level, 1);
                $s .= '</li>';
            }
        }
        else {
            $s .= '<li><div class="value-empty">empty</div></li>';
        }
    }
    elsif (UNIVERSAL::isa($vars, "ARRAY")) {
        if (scalar @$vars > 0) {
            my $i = 0;
            
            # List array members
            foreach my $value (@$vars) {
                $s .= '<li><div class="field">';
                $s .= '<span class="name">' . $i++ . '</span></div>';
                $s .= _value_html($value, $level);
                $s .= '</li>';
            }
        }
        else {
            $s .= '<li><div class="value-empty">empty</div></li>';
        }
    }
    elsif (UNIVERSAL::isa($vars, "HASH")) {
        if (scalar keys %$vars > 0) {
            foreach my $name ($no_sort ? keys %$vars : sort keys %$vars) {
                $s .= '<li><div class="field">';
                $s .= '<span class="name">' . $name . '</span></div>';
                $s .= _value_html($vars->{$name}, $level);
                $s .= '</li>';
            }
        }
        else {
            $s .= '<li><div class="value-empty">empty</div></li>';
        }
    }
    
    $s .= '</ul>';
    
    if ($level == 0) {
        $s =~ s!\n!\\\\n!gm;
    }
    
    return $s;
}

before sub {
    return if (!$toolbar_enabled);
    
    $time_start = time;
};

after sub {
	return if (!$toolbar_enabled);
	
    $info->{'time'} = time - $time_start;
    
    my $data = $info->{'data'} = {};
    
    #
    # Get configuration
    #
    $data->{'config'} = {
        'html' => _build_data_html(config),
        'dumper' => to_dumper(config),
        'yaml' => to_yaml(config)
    };
    
    #
    # Get shared variables
    #
    $data->{'vars'} = {
    	'html' => _build_data_html(vars),
    	'dumper' => to_dumper(vars),
    	'yaml' => to_yaml(vars)
    };
    
    #
    # Get the current request object
    #
    $data->{'request'} = {
        'html' => _build_data_html(request),
        'dumper' => to_dumper(request),
        'yaml' => to_yaml(request)
    };
    
    #
    # Get session data, if available
    #
    if (config->{'session'}) {
        $data->{'session'} = {
            'html' => _build_data_html(session),
            'dumper' => to_dumper(session),
            'yaml' => to_yaml(session)
        };
    }
    
    #
    # Get routes
    #
    my $routes = Dancer::App->current->registry->routes();
    
    $info->{'routes'} = {
        # All routes
        all => {},
        # Matching routes
        matching => {}
    };
    
    my $all = $info->{'routes'}->{'all'};
    my $matching = $info->{'routes'}->{'matching'};
    
    foreach my $type (keys %$routes) {
        $all->{uc $type} = [];
        $matching->{uc $type} = [];
        
        foreach my $route (@{$routes->{$type}}) {
            # Exclude our own route used to get JS/CSS files
            next if ($route->{'pattern'} eq $route_pattern);
            
            my $route_data =
                bless({ $route->{'pattern'} => {
                    'Pattern' => $route->{'pattern'},
                    'Compiled regexp' => $route->{'_compiled_regexp'},
                } }, "Dancer::Plugin::DebugToolbar::_hash_set");
            
            # Is this a matching route?
            if ($route->match_data) {
                $route_data->{$route->{'pattern'}}->{'Match data'} =
                    $route->{'match_data'};
            }
            
            my $route_info = {
                'html' => _build_data_html($route_data, undef, 1)
            };

            # Add the route to the list of all routes
            push(@{$all->{uc $type}}, $route_info);
            
            # If this is a matching route, add it to a separate list of matching
            # routes
            if ($route->match_data) {
                push(@{$matching->{uc $type}}, $route_info);
            }
            
        }
    }
    
    foreach my $key ('config', 'vars', 'request', 'session') {
    	if (defined $data->{$key}->{'dumper'}) {
            $data->{$key}->{'dumper'} =~ s!\n!\\\\n!gm;
    	}
    }
    
    my $info_json = to_json($info);
    # Do some replacements so that the JSON data can be made into a JS string
    # wrapped in single quotes
    $info_json =~ s!\\!\\\\!gm;
    $info_json =~ s!\n!\\\n!gm;
    $info_json =~ s!'!\\'!gm;
    
    # Read the toolbar HTML
    my $html;
    open(F, "<", catfile($dist_dir, 'debugtoolbar', 'html', 'toolbar.html'));
    {
        local $/;
        $html = <F>;
    }
    close(F);
        
    $html =~ s!\n!\\\n!gm;
    $html =~ s!'!\\'!gm;
    
    $template =~ s/%BASE%/$base/mg;
    $template =~ s/%HTML%/$html/mg;
    $template =~ s/%INFO%/$info_json/mg;
    
    my $response = shift;
    my $content = $response->content;
    
    $content =~ s!(?=</body>\s*</html>\s*$)!$template!msi;
    
    $response->content($content);
};

register enable_debug_toolbar => sub {
    my (%options) = @_;
    
    if (defined $options{'base'}) {
        $base = $options{'base'};
    }
    
    $route_pattern = qr(^$base/.*);
    
    get $route_pattern => sub {
        (my $path = request->path_info) =~ s!^$base/!!;
        send_file(catfile($dist_dir, 'debugtoolbar', split(m!/!, $path)),
            system_path => 1);
    };

    $toolbar_enabled = 1;
};

register disable_debug_toolbar => sub {
	$toolbar_enabled = 0;
	
	# TODO: Remove route?
};

register_plugin;

1; # End of Dancer::Plugin::DebugToolbar
__END__

=pod

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Dancer::Plugin::DebugToolbar;

    if (config->{environment} eq 'development') {
        enable_debug_toolbar;
    }
    ...

=head1 DESCRIPTION

Dancer::Plugin::DebugToolbar allows you to add a debugging toolbar to your
Dancer web application.

=head1 AUTHOR

Michal Wojciechowski, C<< <odyniec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-debugtoolbar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-DebugToolbar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::DebugToolbar


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-DebugToolbar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-DebugToolbar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-DebugToolbar>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-DebugToolbar/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michal Wojciechowski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
