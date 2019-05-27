#!/usr/bin/perl -w
#
# -c		show only count of MAC addresses
# -v		show only for specified VLAN number
# -p		show only for specified port number
# -e		print out comma separated CSV; works only without -c option!
# Options c,v,p could be used together or separately.
#

use Net::SNMP;
use Getopt::Std;
use Data::Dumper;

my %options=();

getopts("ecv:p:", \%options);

$count_opt = $options{c} || 0;
$vlan_opt = $options{v} || 0;
$port_opt = $options{p} || 0;
$export_opt = $options{e} || 0;

if($count_opt && $export_opt) {
    print "Only one option -c OR -e could be used same time!\n";
    exit 1;
}

# 1.3.6.1.2.1.17.7.1.2.2.1.2 D-Link/SNR FDB
$base_oid = "1.3.6.1.2.1.17.7.1.2.2.1.2";

# requires a hostname and a community string as its arguments
($session,$error) = Net::SNMP->session(Hostname => $ARGV[0], Community => $ARGV[1], Version => "v2c") 
    || die "SNMP session error: $error";

$result = $session->get_table($base_oid) 
    || die "SNMP request error: ".$session->error;

$session->close;

$total = 0;

while (($key, $port_num) = each (%$result)) {

# CPU MAC address -> port number 0
    if ($port_num == 0) { next; }

	$key =~ s/1.3.6.1.2.1.17.7.1.2.2.1.2.//;
	($vlan, @mac_arr) = split(/\./, $key);
	@hex_mac_arr = join (":", map sprintf("%.2x", $_), @mac_arr);

    if($vlan_opt && $vlan != $vlan_opt || $port_opt && $port_opt != $port_num)  {next;}

    $total++;

    if(!$count_opt) {
	if(!$export_opt) { print "Port $port_num : VLAN: $vlan : MAC: @hex_mac_arr\n";}
	else {print "$port_num,$vlan,@hex_mac_arr\n";}
    }
}

if(!$count_opt && !$export_opt) { print "\nTotal: $total\n"; } elsif(!$export_opt){ print "$total\n";}
