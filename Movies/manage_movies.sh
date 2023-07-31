#!/bin/bash

filelocation=/Movies

while getopts a:n:u:s: flag
do
    case "${flag}" in
        a) appedn=${OPTARG};;
        n) moviename=${OPTARG};;
        u) movieurl=${OPTARG};;
        s) moviesrt=${OPTARG};;
    esac
done

if [[ -z $moviename || -z $movieurl || -z $appedn ]]; then
  echo "One or more variables are undefined"
  echo "Sample usage: ./manage_movies.sh -a[ppend] 'yes/no' -n[ame] 'Movie name' -u[rl] 'http://example.com/movie.file' -s[ubtitle] 'http://example.com/srt.file'"
  echo "Good Bye!"
  exit 1
fi

if [ $appedn = "yes"  ]
 then
  wget -O "$filelocation/$moviename.m3u8" "$movieurl"
  if [[ -z $moviesrt ]]; then
   echo"">/dev/null
   else
    wget -O "$filelocation/$moviename.srt" "$moviesrt"
  fi
 else
  rm -f $filelocation/*
  wget -O "$filelocation/$moviename.m3u8" "$movieurl"
  wget -O "$filelocation/$moviename.srt" "$moviesrt"
fi
