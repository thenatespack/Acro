#!/usr/bin/env perl
# Sets every tracked file's modification time to the time of the last commit that changed it.
#
# CI restores a cached .build folder before building, but a fresh checkout stamps every file
# with the current time, so the build would treat every source as changed and compile it all
# again. With this, a file keeps the same time from run to run until a commit changes it, and
# only modules whose sources (or dependencies) changed are rebuilt. Needs the full history
# (actions/checkout with fetch-depth: 0). Perl because it is on every runner: the Linux Swift
# image (no Python there), macOS, and Git Bash on Windows.
#
#   perl Scripts/restore-mtimes.pl
use strict;
use warnings;

my %done;
my $time;
my $count = 0;
open(my $log, '-|', 'git', '-c', 'core.quotePath=false', 'log', '--format=@%ct', '--name-only', '--no-renames')
    or die "restore-mtimes: can't run git log: $!\n";
while (my $line = <$log>) {
    chomp $line;
    next if $line eq '';
    if ($line =~ /^@(\d+)$/) {
        $time = $1;
        next;
    }
    # The newest commit that touched a file comes first.
    next if $done{$line}++;
    if (-f $line) {
        utime($time, $time, $line) and $count++;
    }
}
close($log);
print "restore-mtimes: set $count files to their last commit times\n";
