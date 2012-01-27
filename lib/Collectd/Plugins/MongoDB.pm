
package Collectd::Plugins::MongoDB;

use strict;
use warnings;
use Collectd qw( :all );
use MongoDB;

my $connection;
sub mongo_init {
	$connection = eval{MongoDB::Connection->new(host => $hostname_g.':27017', auto_connect=>1,auto_reconnect=>1)};
	if(!$connection) {
		plugin_log(ERROR,"Connection to MongoDB has failed. Will retry later before attempting to read metrics.");
	}
	return 1;
}
sub mongo_read {
	if(!$connection) {
		$connection = eval{MongoDB::Connection->new(host => $hostname_g.':27017', auto_connect=>1,auto_reconnect=>1)};
		if(!$connection) {
			plugin_log(ERROR,"Connection to MongoDB has failed. Will retry later before attempting to read metrics.");
			return 0;
		}
	}

	my $db = $connection->get_database("admin");
	my $status= eval{$db->run_command({'serverStatus' => 1})};
	if(!$status) { #if the get database failed, it's probably because of a dead connection, so ditch the connection and skip the rest of the check
		plugin_log(ERROR,"MongoDB query has failed. Will try to reconnect again later.");
		$connection=0;
		return 0;
	}
	my %v = ( 'host'=>$hostname_g, 'interval'=>$interval_g , 'time'=>time(), 'plugin'=>'mongodb');

	$v{'type'}='opcounters';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'opcounters'}->{'insert'};
	$v{'values'}[1]=$status->{'opcounters'}->{'query'};
	$v{'values'}[2]=$status->{'opcounters'}->{'update'};
	$v{'values'}[3]=$status->{'opcounters'}->{'delete'};
	$v{'values'}[4]=$status->{'opcounters'}->{'getmore'};
	$v{'values'}[5]=$status->{'opcounters'}->{'command'};
        plugin_dispatch_values(\%v);

	$v{'type'}='opcounters';
	$v{'type_instance'}='repl';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'opcounters'}->{'insert'};
	$v{'values'}[1]=$status->{'opcounters'}->{'query'};
	$v{'values'}[2]=$status->{'opcounters'}->{'update'};
	$v{'values'}[3]=$status->{'opcounters'}->{'delete'};
	$v{'values'}[4]=$status->{'opcounters'}->{'getmore'};
	$v{'values'}[5]=$status->{'opcounters'}->{'command'};
        plugin_dispatch_values(\%v);
	delete $v{'type_instance'};


	$v{'type'}='globalLock';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'globalLock'}->{'totalTime'};
	$v{'values'}[1]=$status->{'globalLock'}->{'lockTime'};
	plugin_dispatch_values(\%v);
	
	$v{'type'}='lockQueue';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'globalLock'}->{'currentQueue'}->{'total'};
	$v{'values'}[1]=$status->{'globalLock'}->{'currentQueue'}->{'readers'};
	$v{'values'}[2]=$status->{'globalLock'}->{'currentQueue'}->{'writers'};
	plugin_dispatch_values(\%v);

	$v{'type'}='mongo_memory';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'mem'}->{'resident'}*1024*1024;
	$v{'values'}[1]=$status->{'mem'}->{'virtual'}*1024*1024;
	$v{'values'}[2]=$status->{'mem'}->{'mapped'}*1024*1024;
	$v{'values'}[3]=$status->{'mem'}->{'mappedWithJournal'}*1024*1024;
	plugin_dispatch_values(\%v);

	$v{'type'}='backgroundFlushing';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'backgroundFlushing'}->{'flushes'};
	$v{'values'}[1]=$status->{'backgroundFlushing'}->{'total_ms'};
	$v{'values'}[2]=$status->{'backgroundFlushing'}->{'last_ms'};
	$v{'values'}[3]=$status->{'backgroundFlushing'}->{'average_ms'};
	plugin_dispatch_values(\%v);

	$v{'type'}='network';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'network'}->{'bytesIn'};
	$v{'values'}[1]=$status->{'network'}->{'bytesOut'};
	$v{'values'}[2]=$status->{'network'}->{'numRequests'};
	plugin_dispatch_values(\%v);

	$v{'type'}='indexCounters';
	$v{'type_instance'}='btree';
	$v{'values'}=();
	$v{'values'}[0]=$status->{'indexCounters'}->{'btree'}->{'accesses'};
	$v{'values'}[1]=$status->{'indexCounters'}->{'btree'}->{'hits'};
	$v{'values'}[2]=$status->{'indexCounters'}->{'btree'}->{'misses'};
	$v{'values'}[3]=$status->{'indexCounters'}->{'btree'}->{'resets'};
	plugin_dispatch_values(\%v);
	
	return 1;
}

plugin_register(TYPE_READ, 'MongoDB', 'mongo_read');
plugin_register(TYPE_INIT, 'MongoDB', 'mongo_init');

return 1;
