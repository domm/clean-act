#!usr/bin/env perl
use strict;
use warnings;

use 5.028;

use DBI;

my $dbh = DBI->connect('dbi:Pg:service=actclean');

my %clean = (
    bios           => [qw(bio)],
    conferences    => [qw()],
    events         => [qw()],
    invoice_num    => [qw()],
    invoices       => [qw(first_name last_name company address vat)],
    news           => [qw()],
    news_items     => [qw(title text)],
    order_items    => [qw(name)],
    orders         => [qw()],
    participations => [qw(tshirt_size ip)],
    pm_groups      => [qw()],
    rights         => [qw()],
    schema         => [qw()],
    tags           => [qw()],
    talks          => [qw(title abstract url_abstract url_talk comment)],
    tracks         => [qw(title description)],
    twostep        => [],
    user_talks     => [qw()],
    users          => [
        qw(passwd first_name last_name nick_name town web_page gpg_key_id pause_id monk_id im photo_name company company_url address vat pm_group_url)
    ],
);

$dbh->do(<<'EORANDTEXT');
CREATE OR REPLACE FUNCTION
random_text(INTEGER)
RETURNS TEXT
LANGUAGE SQL
AS $$
SELECT array_to_string(array(
  SELECT SUBSTRING('1234567890 abcdefghi jklmnopqr stuvwxyz' 
    FROM floor(random()*39)::int+1 FOR 1)
  FROM generate_series(1, $1)), '');
$$;
EORANDTEXT

say "delete all from twostep";
$dbh->do("delete from twostep");

for my $table ( sort keys %clean ) {
    say "Cleaning $table";
    for my $col ( $clean{$table}->@* ) {
        say $col;
        $dbh->do(
            "update $table set $col = random_text(length($col)) where $col is not null"
        );
    }
}

say "clean some special fields (users.email, users.login)";
$dbh->do(
    q{UPDATE users SET email=replace(random_text(length(first_name)) || '@' || random_text(length(last_name)) || '.pm',' ','_'), login=replace(random_text(length(login)) || floor(random() * 200 + 1)::int,' ','_')}
);

# some non-text fields
say "clean some ints";
$dbh->do(
    "UPDATE invoices SET amount = floor(random() * 200 + 1)::int where amount is not null"
);
$dbh->do(
    "UPDATE order_items SET amount = floor(random() * 200 + 1)::int where amount is not null"
);
$dbh->do(
    "UPDATE participations SET nb_family = floor(random() * 3)::int where nb_family > 0"
);
$dbh->do(
    "UPDATE users SET salutation = floor(random() * 5)::int where salutation is not null"
);

say "clean pm_groups";
my @groups = map { ucfirst( ( $_ x 5 ) . '.pm' ) } ( 'a' .. 'z' );
$dbh->do( "UPDATE users SET pm_group = (array["
        . join( ',', map {"'$_'"} @groups )
        . "])[floor(random() * 27)] || '.pm' where pm_group is not null" );

