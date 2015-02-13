use strict;
use warnings;

{
    handle_message => sub {
        my ($host, $t, $hdl, $run_engine, $json) = @_;
        my $value;
        if ($t eq 'get_new_number') {
            eval { $run_engine->();};
            return {response => $main::mattworker_data{engine_result}};
        }
        return {};
    },
    engine_part => sub {
        my ($session, $type, $data, $caches) = @_;
        my $file = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberFile};
        unless ($file) {
            Foswiki::Func::writeWarning("No NumberFile configured");
            return undef;
        }
        my $returnValue;
        unless( -e $file ) {
            $returnValue = '0';
        } else {
            open FILE, "<", $file;
            my @lines = <FILE>;
            if(scalar @lines) {
                $returnValue = $lines[0];
            } else {
                $returnValue = '0';
            }
            close(FILE);
        }

        $returnValue++;

        open FILE, ">", $file;
        print FILE $returnValue;
        close(FILE);

        $main::mattworker_data{engine_result} = $returnValue
    },
};
