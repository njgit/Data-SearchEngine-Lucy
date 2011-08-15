use strict;
use warnings;

# ABSTRACT: Lucy backend for Data::SeachEngine 
package Data::SearchEngine::Lucy;

use Moose;
use Lucy::Search::IndexSearcher; 
use Data::SearchEngine::Paginator;
use Data::SearchEngine::Item;
use Data::SearchEngine::Results;

with 'Data::SearchEngine';

has '_lucy'   => ( isa => 'Lucy::Search::IndexSearcher', is => 'rw', lazy_build => 1);
has 'url'     => ( isa => 'Str', is => 'rw', required => 1);
has 'options' => ( isa => 'HashRef', is => 'rw', default => sub { {} } ); 

sub _build__lucy {
	my $self = shift;
	return Lucy::Search::IndexSearcher->new( index => $self->url );
}


sub search {
   my ( $self, $query )  =  @_;

   my $options = $self->options;
   $options->{rows} = $query->count;
   
   if($query->page > 1) {
        $options->{start} = ($query->page - 1) * $query->count;
   }
 
   my $start = time;
   
   # Get the hits
   my $resp = $self->_lucy->hits(   
     query => $query->query, 
     offset => $options->{start},
     num_wanted => $options->{rows}      
   );
   
   # Put into a result object
  
    # The response will have no pager if there were no results, so we handle
    # that here.
    my $num_hits = $resp->total_hits;
    my $pager = Data::SearchEngine::Paginator->new(
        current_page => $num_hits ? $query->page: 0,
        entries_per_page => $num_hits ? $query->count: 0,
        total_entries => $num_hits ? $resp->total_hits : 0
    );
    
   my $result = Data::SearchEngine::Results->new(
            query       => $query,
            pager       => $pager
        );   
   
   #-- Optional Highlighting  --#
   my $highlighter;   
   if( defined( $options->{highlighter} ) ) {
       
       $highlighter = Lucy::Highlight::Highlighter->new(
        searcher => $self->_lucy,
        query    => $query->query, 
        field    =>  defined($options->{highlighter}->{highlighted_field} ) ?  $options->{highlighter}->{highlighted_field} : 'content',
        excerpt_length => defined($options->{highlighter}->{excerpt_length} ) ?  $options->{highlighter}->{excerpt_length} : 100,
    );    
   };
   
   #-- Hits into Data::SearchEngine::Results object --#   
   my $values;
   while ( my $hit = $resp->next ) {
     $values = $hit->get_fields();
     # if $highlighting 
     $values->{excerpt} = $highlighter->create_excerpt($hit) if ( $options->{highlighter} );
      
     $result->add( Data::SearchEngine::Item->new(        
              id => $hit->get_doc_id(),
              score => $hit->get_score(),
              values => $values,
     ));     
   }
   
   return $result;
}


1;
