# --
# Ticket/Number/AutoIncrement.pm - a ticket number auto increment generator
# Copyright (C) 2002-2003 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: AutoIncrement.pm,v 1.7 2003-03-18 15:35:30 wiktor Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --
# Note: 
# available objects are: ConfigObject, LogObject and DBObject
# 
# Generates auto increment ticket numbers like ss.... (e. g. 1010138, 1010139, ...)
# --
 
package Kernel::System::Ticket::Number::AutoIncrement;

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.7 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

sub CreateTicketNr {
    my $Self = shift;
    my $JumpCounter = shift || 0;

    # --
    # get needed config options 
    # --
    my $CounterLog = $Self->{ConfigObject}->Get('CounterLog');
    my $SystemID = $Self->{ConfigObject}->Get('SystemID');

    # --
    # read count
    # --
    open (COUNTER, "< $CounterLog") || die "Can't open $CounterLog: $!";
    my $Line = <COUNTER>;
    my ($Count) = split(/;/, $Line);
    close (COUNTER);
    if ($Self->{Debug} > 0) {
        $Self->{LogObject}->Log(
          Priority => 'debug',
          Message => "Read counter: $Count",
        );
    }

    # --
    # count auto increment ($Count++)
    # --
    $Count++;
    $Count = $Count + $JumpCounter;

    # --
    # write new count
    # --
    if (open (COUNTER, "> $CounterLog")) {
        flock (COUNTER, 2) || warn "Can't set file lock ($CounterLog): $!";
        print COUNTER $Count . "\n";
        close (COUNTER);
        if ($Self->{Debug} > 0) {
            $Self->{LogObject}->Log(
              Priority => 'debug',
              Message => "Write counter: $Count",
            );
        }
    }
    else {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message => "Can't write $CounterLog: $!",
        );
        die "Can't write $CounterLog: $!";
    }

    # --
    # pad ticket number with leading '0' to length 5
    # --
    while ( length( $Count ) < 5 ) {
        $Count = "0" . $Count;
    }

    # --
    # new ticket number
    # --
    my $Tn = $SystemID . $Count;

    # --
    # Check ticket number. If exists generate new one! 
    # --
    if ($Self->CheckTicketNr(Tn=>$Tn)) {
        $Self->{LoopProtectionCounter}++;
        if ($Self->{LoopProtectionCounter} >= 1000) {
          # loop protection
          $Self->{LogObject}->Log(
            Priority => 'error',
            Message => "CounterLoopProtection is now $Self->{LoopProtectionCounter}!".
                   " Stoped CreateTicketNr()!",
          );
          return;
        }
        # --
        # create new ticket number again
        # --
        $Self->{LogObject}->Log(
          Priority => 'notice',
          Message => "Tn ($Tn) exists! Creating new one.",
        );
        $Tn = $Self->CreateTicketNr($Self->{LoopProtectionCounter});
    }
    return $Tn;
}
# --
sub GetTNByString {
    my $Self = shift;
    my $String = shift || return;

    # --
    # get needed config options 
    # --
    my $SystemID = $Self->{ConfigObject}->Get('SystemID');
    my $TicketHook = $Self->{ConfigObject}->Get('TicketHook');

    # --
    # check ticket number
    # --
    if ($String =~ /$TicketHook:+.{0,1}($SystemID\d{2,10})\-FW/i) {
        return $1;
    }
    else {
        if ($String =~ /$TicketHook:+.{0,1}($SystemID\d{2,10})/i) {
            return $1;
        }
        else {
            return;
        }
    }
}
# --
1;
