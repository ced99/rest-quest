#!/usr/bin/env perl

my $name1 = 'Player1';
my $name2 = 'Player2';

if (my $pid1 = fork()) {
    if (my $pid2 = fork()) {
        `node ../server/rest-quest-master/server.js`;
    } else {
        sleep 2;
        open my $fh, "perl -Ilib/ client.pl client.pl -name=$name1|";
        while (<$fh>) {
            #print "$_\n";
            if (/game (\w+)/) {
                print "$name1 $1\n";
            }
        }
        waitpid $pid1, 0;
        kill 'INT', $pid2;
        waitpid $pid2, 0;
    }
} else {
    sleep 2;
    open my $fh, "perl -Ilib/ client.pl client.pl -name=$name2|";
    while (<$fh>) {
        #print "$_\n";
        if (/game (\w+)/) {
            print "$name2 $1\n";
        }
    }
}
