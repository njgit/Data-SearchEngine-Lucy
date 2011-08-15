use strict;
use warnings;
use lib 'buildlib';
use Test::More tests => 3;
use Data::Dumper;
 
use Data::SearchEngine::Lucy;
use Data::SearchEngine::Query;

use Lucy::Test::TestUtils qw( create_index persistent_test_index_loc );

my $options = { highlighter => { excerpt_length => 100 }  };

my $lucy = Data::SearchEngine::Lucy->new( url => persistent_test_index_loc(), options => $options );

ok ( $lucy, 'lucy object');

my $query = Data::SearchEngine::Query->new(
             count => 10,
             page => 1,
             query => 'united',
           );
                      
ok ( $query, 'query object' );

my $result =  $lucy->search( $query );

ok( $result, 'result object');

warn Dumper($result);

# while ( my $hit = $resp->next ) {
        # warn $hit;
# }