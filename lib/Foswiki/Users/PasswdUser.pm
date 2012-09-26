# See bottom of file for license and copyright information

=begin TML

---+ package Foswiki::Users::PasswdUser

Support for /etc/passwd via getpwnam

Subclass of =[[%SCRIPTURL{view}%/%SYSTEMWEB%/PerlDoc?module=Foswiki::Users::Password][Foswiki::Users::Password]]=.
See documentation of that class for descriptions of the methods of this class.

Does not support registration.

=cut

package Foswiki::Users::PasswdUser;
use strict;
use warnings;

use Foswiki::Users::Password ();
our @ISA = ('Foswiki::Users::Password');

use Assert;
use Error qw( :try );

# 'Use locale' for internationalisation of Perl sorting in getTopicNames
# and other routines - main locale settings are done in Foswiki::setupLocale
BEGIN {

    # Do a dynamic 'use locale' for this module
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub new {
    my ( $class, $session ) = @_;
    my $this = bless( $class->SUPER::new($session), $class );
    $this->{error} = undef;

    return $this;
}

sub readOnly {
    return 1;
}

sub canFetchUsers {
    return 1;
}

{
    # Iterator over users in /etc/passwd
    package EtcPasswdIt;

    use Foswiki::Iterator ();
    our @ISA = ('Foswiki::Iterator');

    sub new {
        my $class = shift;
        setpwent();
        my ($first) = getpwent();
        return bless( { next => $first, }, $class );
    }

    sub hasNext {
        my $this = shift;
        return $this->{next};
    }

    sub next {
        my $this  = shift;
        my $entry = $this->{next};
        ( $this->{next} ) = getpwent();
        endpwent() unless $this->{next};
        return $entry;
    }
}

sub fetchUsers {
    return new EtcPasswdIt();
}

sub fetchPass {
    my ( $this, $login ) = @_;

    if ($login) {
        my ( $user, $passwd ) = getpwnam($login);
        return $passwd;
    }
    $this->{error} = 'No user';

    return 0;
}

sub checkPassword {
    my ( $this, $login, $password ) = @_;

    $this->{error} = undef;

    my $pw = $this->fetchPass($login);
    return 0 unless defined $pw;

    my $encryptedPassword = crypt( $password, $pw );

    return 1 if ( $encryptedPassword eq $pw );

    # pw may validly be '', and must match an unencrypted ''. This is
    # to allow for sysadmins removing the password field in
    # order to reset the password.
    return 1 if ( defined $password && $pw eq '' && $password eq '' );

    $this->{error} = 'Invalid user/password';
    return 0;
}

sub isManagingEmails {
    return 0;
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
