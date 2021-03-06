package App::es::ParamValidation;

use File::Slurp qw{ read_file };
use JSON        qw{ decode_json };
use URI::Split  qw{ uri_split };
use MooX::Types::MooseLike;
use base qw(Exporter);
our @EXPORT_OK = ();

our $VERSION = "0.1";

my $regex_name = qr/^[a-zA-Z0-9_.-]*$/;

my %validation = (

    subname_opt => sub {
        return 1 unless $_[0]; # optional
        die "[ERROR] invalid index name sub-string: $_[0]\n"
            unless $_[0] =~ /$regex_name/;
    },

    type => sub {
        die "[ERROR] invalid type name: $_[0]\n"
            unless $_[0] and $_[0] =~ /$regex_name/;
    },

    doc_id => sub {
        die "[ERROR] invalid document id: $_[0]\n"
            unless $_[0] and $_[0] =~ /$regex_name/;
        1;
    },

    index_y => sub {
        die "[ERROR] invalid index/alias name: $_[0]\n"
            unless $_[0] and $_[0] =~ /^[a-zA-Z0-9_.-]+$/;
        my $check = $_[1]->es->index_exists(index=>$_[0]);
        die "[ERROR] index/alias does not exists: $_[0]\n"
            unless $check and ref($check) eq 'HASH' and $check->{ok};
        1;
    },

    index_n => sub {
        die "[ERROR] invalid index/alias name: $_[0]\n"
            unless $_[0] and $_[0] =~ /$regex_name/;
        my $check = $_[1]->es->index_exists(index=>$_[0]);
        die "[ERROR] index/alias already exists: $_[0]\n"
            if $check and ref($check) eq 'HASH' and $check->{ok};
        1;
    },

    json_file => sub {
        die "[ERROR] file doesn't exist: $_[0]\n"
            unless $_[0] and -f $_[0];
        die "[ERROR] not a valid json file: $_[0]\n"
            unless decode_json(read_file($_[0]));
        1;
    },

    field => sub {
        die "[ERROR] missing field name"
        unless $_[0];
        die "[ERROR] invalid field name: $_[0]\n"
        unless $_[0] =~ /^ [a-zA-Z0-9_-]+ $/x;
    },

    searchstr => sub {
        die "[ERROR] missing searchstr"
            unless $_[0];
        utf8::decode($_[0]);
        die "[ERROR] invalid searchstr: $_[0]\n"
            unless $_[0] =~ /^([a-zA-Z0-9_.-]+ :)? [\w\d\s._-]+$/x;
        1;
    },

    string => sub {
        die "[ERROR] missing string"
            unless $_[0];
        utf8::decode($_[0]);
        die "[ERROR] invalid string: $_[0]\n"
            unless $_[0] =~ /^[\w\d_\s-]+$/x;
        1;
    },

    size => sub {
        die "[ERROR] invalid size: $_[0]\n"
            unless $_[0] and $_[0] =~ /^[0-9]*$/;
    },

    index_fq => sub {
        my ($scheme, $hostport, $path, undef, undef) = uri_split($_[0]);
        die "Error: $_[0] is not a full URL for an index." unless $hostport && $path;
        $path =~ s{^/}{};
        $path =~ s{/$}{};
        die "Error: $_[0] does not refers to an index." if $path =~ m{/};
    },

    alias_n => sub {
        die "[ERROR] invalid index/alias name: $_[0]\n"
        unless $_[0] and $_[0] =~ /$regex_name/;
    }
);

$validation{index_y_notalias} = sub {
    my $aliases = $_[1]->_get_elastic_search_aliases;
    if ( $validation{index_y}->(@_) ) {
        die "[ERROR] index $_[0] is an anlias\n"
            if grep { /^$_[0]$/ } @$aliases;
    }
    1;
};

$validation{index_y_opt} = sub {
    return 1 unless $_[0]; # optional
    return $validation{index_y}->(@_);
};

$validation{alias_y} = $validation{index_y};

sub get_validator {
    my ( $class, $arg_type ) = @_;
    return ($validation{ $arg_type } || sub { undef });
}

MooX::Types::MooseLike::register_types([
    +{
        name => "ESExistingIndex",
        test => App::es::ParamValidation->get_validator("index_y"),
    },
    +{
        name => "ESName",
        test => sub {
            $_[0] =~ /^ [a-zA-Z0-9_-]+ $/x;
        },
        message => sub { "$_[0] does not look like a valid name" }
    },
], __PACKAGE__);

1;
__END__

=head1 NAME

App::es - ElasticSearch command line client.

=head1 DESCRIPTION

Please read the usage and document in the L<es> program.

=head1 AUTHORS

Mickey Nasriachi E<lt>mickey75@gmail.comE<gt>

Kang-min Liu E<lt>gugod@gugod.orgE<gt>


=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com. With approval from
Booking.com, this module was generalized and published on CPAN, for which the
authors would like to express their gratitude.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Mickey Nasriachi

Copyright (C) 2013 by Kang-min Liu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

