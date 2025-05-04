#!/bin/bash

# Public domain notice for all NCBI EDirect scripts is located at:
# https://www.ncbi.nlm.nih.gov/books/NBK179288/#chapter6.Public_Domain_Notice

base="ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect"

version=""

# process optional command-line arguments
while [ "$#" -ne 0 ]
do
  case "$1" in
    -version )
      shift
      if [ $# -gt 0 ]
      then
        version="$1"
        shift
      else
        echo "Missing version number, will not download EDirect archive" >&2
        exit 1
      fi
      ;;
    * )
      # unrecognized option, break out of loop
      break
      ;;
  esac
done

if [ -n "$version" ] && [ "$version" != "current" ]
then
  # find directory for explicit version (e.g., "15.6")
  dir=$(
    curl -s "$base/versions/" |
    grep -v current |
    tr -s ' ' |
    tr ' ' '\t' |
    cut -f 9 |
    grep "${version}\." |
    tail -n 1
  )
  if [ -n "$dir" ]
  then
    # set base to specific version
    base=$( echo "$base/versions/${dir}" )
  else
    echo "Unable to find EDirect version ${version} archive" >&2
    exit 1
  fi
fi

# function to fetch a single file, passed as an argument
FetchFile() {

  fl="$1"

  if [ -x $(command -v curl) ]
  then
    curl -s "${base}/${fl}" -o "${fl}"
  elif [ -x $(command -v wget) ]
  then
    wget "${base}/${fl}"
  else
    echo "Missing curl and wget commands, unable to download EDirect archive" >&2
    exit 1
  fi
}

# edirect folder to be installed in home directory
cd ~

# download and extract edirect archive
FetchFile "edirect.tar.gz"
if [ -s "edirect.tar.gz" ]
then
  gunzip -c edirect.tar.gz | tar xf -
  rm edirect.tar.gz
fi
if [ ! -d "edirect" ]
then
  echo "Unable to download EDirect archive" >&2
  exit 1
fi

# remaining executables to be installed within edirect folder
cd edirect

# determine current computer platform
osname=$(uname -s)
cputype=$(uname -m)
case "$osname-$cputype" in
  Linux-x86_64 )           plt=Linux ;;
  Darwin-x86_64 )          plt=Darwin ;;
  Darwin-*arm* )           plt=Silicon ;;
  CYGWIN_NT-* | MINGW*-* ) plt=CYGWIN_NT ;;
  Linux-*arm* )            plt=ARM ;;
esac

# fetch appropriate precompiled versions of xtract, rchive, and transmute
if [ -n "$plt" ]
then
  for exc in xtract rchive transmute
  do
    FetchFile "$exc.$plt.gz"
    gunzip -f "$exc.$plt.gz"
    chmod +x "$exc.$plt"
  done
fi

case ":$PATH:" in
  *:$HOME/edirect:*)
    ;;
  *)
    echo ""
    echo "To activate EDirect for this terminal session, please execute the following:"
    echo ""
    printf "export PATH=\${PATH}:\${HOME}/edirect\n"
    echo ""
    ;;
esac
