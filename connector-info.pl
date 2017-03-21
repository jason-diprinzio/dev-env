#!/usr/bin/perl
#
use strict;
use warnings;

my $line=<>;
my @tokens = split('/', $line); 
my $last_token = @tokens; 

my $conn_name = $tokens[$last_token-1];

@tokens = split('-', $conn_name);
$last_token = @tokens;

print($tokens[2]);
print(" ");
print($tokens[1]);


