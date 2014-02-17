package Plugins::GoogleMusic::AlbumMenu;

use strict;
use warnings;

use Slim::Utils::Log;
use Slim::Utils::Strings qw(cstring);
use Slim::Utils::Prefs;

use Plugins::GoogleMusic::TrackMenu;


my $log = logger('plugin.googlemusic');
my $prefs = preferences('plugin.googlemusic');

my %sortMap = (
	'album' => \&_sortAlbum,
	'artistalbum' => \&_sortArtistAlbum,
	'artistyearalbum' => \&_sortArtistYearAlbum,
	'yearalbum' => \&_sortYearAlbum,
	'yearartistalbum' => \&_sortYearArtistAlbum,
);

sub feed {
	my ($client, $callback, $args, $albums, $opts) = @_;

	return $callback->(menu($client, $args, $albums, $opts));
}

sub menu {
	my ($client, $args, $albums, $opts) = @_;

	my @items;

	if ($opts->{sortAlbums}) {
		my $sortMethod = $opts->{all_access} ?
			$prefs->get('all_access_album_sort_method') :
			$prefs->get('my_music_album_sort_method');
		if (exists $sortMap{$sortMethod}) {
			@$albums = sort {$sortMap{$sortMethod}->()} @$albums;
		}
	}

	for my $album (@{$albums}) {
		push @items, _showAlbum($client, $album, $opts);
	}

	if (!scalar @items) {
		push @items, {
			name => cstring($client, 'EMPTY'),
			type => 'text',
		}
	}

	return {
		items => \@items,
	};
}

sub _showAlbum {
	my ($client, $album, $opts) = @_;

	my $albumYear = $album->{year} || " ? ";

	my $item = {
		name  => $album->{name} . " (" . $albumYear . ")",
		name2  => $album->{artist}->{name},
		line1 => $album->{name} . " (" . $albumYear . ")",
		line2 => $album->{artist}->{name},
		cover => $album->{cover},
		image => $album->{cover},
		type  => 'playlist',
		url   => \&_albumTracks,
		hasMetadata   => 'album',
		passthrough => [ $album , { all_access => $opts->{all_access}, playall => 1, sortByTrack => 1 } ],
		albumData => [
			{ type => 'link', label => 'ARTIST', name => $album->{artist}->{name}, url => 'anyurl',
		  },
			{ type => 'link', label => 'ALBUM', name => $album->{name} },
			{ type => 'link', label => 'YEAR', name => $album->{year} },
		],
	};

	# If the albums are sorted by name add a text key to easily jump
	# to albums on squeezeboxes
	if ($opts->{sortAlbums}) {
		my $sortMethod = $opts->{all_access} ?
			$prefs->get('all_access_album_sort_method') :
			$prefs->get('my_music_album_sort_method');
		if ($sortMethod eq 'album') {
			$item->{textkey} = substr($album->{name}, 0, 1);
		}
	}

	return $item;
}

sub _albumTracks {
	my ($client, $callback, $args, $album, $opts) = @_;

	my $tracks;

	my $info = Plugins::GoogleMusic::Library::get_album($album->{uri});
	if ($info) {
		$tracks = $info->{tracks};
	} else {
		$tracks = [];
	}

	Plugins::GoogleMusic::TrackMenu::feed($client, $callback, $args, $tracks, $opts);

	return;
}

sub _sortAlbum {
	return lc($a->{name}) cmp lc($b->{name});
}

sub _sortArtistAlbum {
	return lc($a->{artist}->{name}) cmp lc($b->{artist}->{name}) or
		lc($a->{name}) cmp lc($b->{name});
}

sub _sortArtistYearAlbum {
	return lc($a->{artist}->{name}) cmp lc($b->{artist}->{name}) or
		($b->{year} || -1) <=> ($a->{year} || -1) or
		lc($a->{name}) cmp lc($b->{name});
}

sub _sortYearAlbum {
	return ($b->{year} || -1) <=> ($a->{year} || -1) or
		lc($a->{name}) cmp lc($b->{name});
}

sub _sortYearArtistAlbum {
	return ($b->{year} || -1) <=> ($a->{year} || -1) or
		lc($a->{artist}->{name}) cmp lc($b->{artist}->{name}) or
		lc($a->{name}) cmp lc($b->{name});
}

1;