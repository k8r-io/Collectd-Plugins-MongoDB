
package Collectd::Plugins::MongoDB;

use strict;
use warnings;
use Collectd qw( :all );
use MongoDB;

my @opcounters = ('insert','query','update','delete','getmore','command');
my $connection;
sub mongo_init {
	$connection = MongoDB::Connection->new(host => $hostname_g.':27017', auto_connect=>1,auto_reconnect=>1) or plugin_log(ERROR,"Failed connecting to MongoDB and stuff!");
}
sub mongo_read {
	my $db = $connection->get_database("admin");
	my $status= $db->run_command({'serverStatus' => 1});
	my %v = ( 'host'=>$hostname_g, 'interval'=>$interval_g , 'time'=>time(), 'plugin'=>'mongodb');

	$v{"type"}="opcounters";
	$v{"values"}=();
	my @values;
	foreach(@opcounters) {
		push @values, $status->{'opcounters'}->{$_};
	}
	$v{"values"}=\@values;
        plugin_dispatch_values(\%v);
}

plugin_register(TYPE_READ, 'MongoDB', 'mongo_read');
plugin_register(TYPE_INIT, 'MongoDB', 'mongo_init');

return 1;
