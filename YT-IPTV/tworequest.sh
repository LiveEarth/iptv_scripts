#!/bin/bash
#copyright 2020 https://github.com/kanliot Apache 2.0 Free to use

helpexit () {
    echo "Usage: m3ufromyt ./out.m3u"
    echo "Create a nice m3u file from an youtube url."
    echo 'a SINGLE youtube url will be prompted for..'
    echo "please don't redirect output."
    echo "you should enter a youtube url at the prompt."
    echo "Youtube urls to a playlist, or to channel/videos have been tested"
    echo 'this script is slow on big channels.  about 1000 videos per hour'
    echo 'option -r allows you to reverse the .m3u playlist'
    echo 'option -q allows you to make this program quiet'
    exit
}
test $# -eq 0 && helpexit
for a
do test "$a" = '-h' && helpexit
    test "$a" = '--help' && helpexit
    test "$a" = '-r' && rev=yes && continue
    test "$a" = '-q' && quiet=yes && continue
    outfile=$a
done

2>/dev/null touch "$outfile" || { echo cannot stat:\'"$outfile"\'; exit 1;}

echo -n enter youtube URL": "
read

perl3 () {
    perl -e'
    #!/usr/bin/perl

    use open ":std", ":utf8";
    $| = 1;

    sub to_seconds {
        my $has_ms = scalar $_[0] =~ /\.\d+/;

        my @components = split /[;:\.]/, $_[0];
        push @components, 0 if not $has_ms;

        @components = reverse @components;

        push @components, 0 if $#components < 3;    # hours are opt.
        push @components, 0 if $#components < 3;    # minutes are opt.

        # now we should have an array of ms, s, min, h.
        return ( ( $components[3] * 60 + $components[2] ) * 60 + $components[1] ) +
          ".$components[0]";

    #         return (($components[3] * 60 + $components[2]) * 60 + $components[1]) * 1000 + ".$components[0]" * 1000;
    }

    sub date {
        my $a     = shift;
        my $month = substr( $a, 4, 2 );
        my $day   = substr( $a, 6, 2 );
        my $year  = substr( $a, 0, 4 );
        join "/", $day, $month, $year;
    }
    while (1) {
        last if eof STDIN;
        my $s = to_seconds( scalar readline STDIN );
        $a = date( scalar readline STDIN );
        $b = <STDIN>;
        $_ = <STDIN>;
        y/,/./;    # comma is field sep in m3u EXTINF
#        print "#EXTINF:$s,$a $_", "http://www.youtube.com/watch?v=$b\n";
        print "#EXTINF:YT,$a $_", "http://www.youtube.com/watch?v=$b\n";
    }
    print "#done.\n";
    '
}
perl2 () {
    perl -e'
    #!/usr/bin/perl

    use open ":std", ":utf8";
    $| = 1;

    sub to_seconds {
        my $has_ms = scalar $_[0] =~ /\.\d+/;

        my @components = split /[;:\.]/, $_[0];
        push @components, 0 if not $has_ms;

        @components = reverse @components;

        push @components, 0 if $#components < 3;    # hours are opt.
        push @components, 0 if $#components < 3;    # minutes are opt.

        # now we should have an array of ms, s, min, h.
        return ( ( $components[3] * 60 + $components[2] ) * 60 + $components[1] ) +
          ".$components[0]";

    #         return (($components[3] * 60 + $components[2]) * 60 + $components[1]) * 1000 + ".$components[0]" * 1000;
    }

    sub date {
        my $a     = shift;
        my $month = substr( $a, 4, 2 );
        my $day   = substr( $a, 6, 2 );
        my $year  = substr( $a, 0, 4 );
        join "/", $day, $month, $year;
    }
    while (1) {
        last if eof STDIN;
        $_ = <STDIN>;
        y/,/./;    # comma is field sep in m3u EXTINF
        $b = <STDIN>;
        $a = date( scalar readline STDIN );
        my $s = to_seconds( scalar readline STDIN );
        print "#EXTINF:$s,YT $a $_";
        system("./yt-dlp_linux -f 22 -g http://www.youtube.com/watch?v=$b");
    }
#    print "#done.\n";
    '
}

getlines () {
#    youtube-dl -i --get-id -e -o '%(upload_date)s' --get-filename --get-duration -- "$1"
     ./yt-dlp_linux -i --get-id -e -o '%(upload_date)s' --get-filename --get-duration -- "$1"
}
main () {
    test "$quiet" && echo -n holdon >&2
    test "$quiet" || echo  holdon >&2
    echo "#EXTM3U"
    echo '#' generated from  "$@"
    echo

    if [ "$rev" ]
    then getlines "$@"|tac|perl3
    else getlines "$@"|perl2
    fi
}

if [ ! "$quiet" ]
then main "$REPLY" |tee "$outfile"
else main "$REPLY" > "$outfile"
fi
test $? != 0 && exit 1
echo -e '\rdone.' $(realpath "$outfile")
