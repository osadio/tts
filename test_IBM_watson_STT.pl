#!/usr/bin/perl

use warnings;
use strict;
use File::Copy qw(move);
use File::Temp qw(tempfile);
use LWP::UserAgent;
use JSON;
use Encode qw(encode);
use MIME::Base64;

my $url = "https://api.eu-gb.speech-to-text.watson.cloud.ibm.com/instances/ad3550a8-6de4-4825-8d3f-cbe1a8e50d22/v1/recognize?model=fr-FR_BroadbandModel";
my $audio = "";
my $ua_timeout = 30;

open(FILE, "<" . $ARGV[0]);
while(<FILE>)
{
    $audio .= $_;
}
close(FILE);


my $debug = 0;
my $name = "holla";

my %response = (
	utterance  => -1,
	confidence => -1,
);
set_channel_vars(%response);


my $ua = LWP::UserAgent->new(ssl_opts => { SSL_verify_mode => {verify_hostname => 1} });
$ua->agent("Asterisk AGI speech recognition script");
$ua->env_proxy;
$ua->timeout($ua_timeout);
$ua->credentials("api.eu-gb.speech-to-text.watson.cloud.ibm.com:443", "IBM Watson Gateway(Log-in)", "apikey", "5gtQXAqCwHpCkdEvBeUlMsSHwF897g6g4kjQBDry2LS7");


my $uaresponse = $ua->post(
	$url,
	Content_Type => "audio/flac",
	Content      => $audio,
);


if (!$uaresponse->is_success) {
	print "VERBOSE \"Unable to get recognition data.\" 3\n";
	checkresponse();
	die "$name Unable to get recognition data.\n";
}
my $jdata = decode_json($uaresponse->content);
$response{utterance} = encode('utf8', $jdata->{"results"}[0]->{"alternatives"}[0]->{"transcript"});
$response{confidence} = $jdata->{"results"}[0]->{"alternatives"}[0]->{"confidence"};


set_channel_vars(%response);
exit;

sub set_channel_vars {
	my %resp = @_;
	foreach (keys %resp) {
		print "SET VARIABLE \"$_\" \"$response{$_}\"\n";
		checkresponse();
	}
}


sub checkresponse {
	my $input = <STDIN>;
	my @values;

	chomp $input;
	if ($input =~ /^200 result=(-?\d+)\s?(.*)$/) {
		warn "$name Command returned: $input\n" if ($debug);
		@values = ("$1", "$2");
	} else {
		$input .= <STDIN> if ($input =~ /^520-Invalid/);
		warn "$name Unexpected result: $input\n";
		@values = (-1, -1);
	}
	return @values;
}