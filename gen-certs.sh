#!/bin/bash
# ./gen-certs.sh
# by: Sahal Ansari github@sahal.info
# interactively generate a self signed certificate

openssl="/usr/bin/openssl"
# $DIR is from http://stackoverflow.com/questions/59895/
DIR="$( cd "$( dirname "$0" )" && pwd )"
ssl_dir="$DIR/keys"
#subj_info="/CN=www.example.com/O=OnShore Example, Inc./C=US/ST=New York/L=New York"
conf_file="$DIR/openssl.cfg"

function generate_keys {

if [ -z "$1" ]; then
   echo "WARNING: Something went wrong?"
   exit 1
fi

if [ "$1" -eq "1" ]; then
# Note: -nodes generates an SSL key without a passphrase (i.e. it will be stored unencrypted.)
#+If you do generate an SSL key with a passphrase, you'll have to input it everytime you restart apache
   "$openssl" req -nodes -sha256 -new -x509 -newkey rsa:4096 -days 30 -subj "$subj_info" -keyout private.pem -out public.pem
elif [ "$1" -eq "0" ]; then
   "$openssl" req -new -x509 -config "$conf_file" -keyout private.pem -out public.pem
else
   echo "WARNING: \$subj not set. Are you sure you specified either \$subj_info or \$conf_file?"
   exit 1
fi

}

# http://blog.cloudflare.com/ensuring-randomness-with-linuxs-random-number-generator
echo "Bits of entropy (should be near 4096): ""$(cat /proc/sys/kernel/random/entropy_avail)"

echo "Key Store: ""$ssl_dir"
echo "OpenSSL binary: ""$openssl"
if [ ! -z "$subj_info" ]; then
   subj="1"
   echo "Subject: ""$subj_info"
elif [ ! -z "$conf_file" ] && [ -e "$conf_file" ]; then
   subj="0"
   echo "OpenSSL config: ""$conf_file"
else
   echo "WARNING: \$subj_info or \$conf_file is unset or \$conf_file is set but doesn't exist."
   exit 1
fi
echo "Do you want to continue?"
select yn in "Yes" "No"; do
	case "$yn" in
        Yes ) break;;
        No ) echo "Edit options and launch again!"; exit 1;;
        esac
done

mkdir -p "$ssl_dir"
cd "$ssl_dir"

if [ -e  private.pem ] || [ -e public.pem ]; then
	echo "private.pem and/or public.pem already exist(s). Do you wish to delete and regenerate?"
	select yn in "Yes" "No"; do
	    case "$yn" in
	        Yes ) rm private.pem; rm public.pem; generate_keys "$subj"; break;;
	        No ) break;;
	    esac
	done
else
	generate_keys "$subj"
fi

echo -ne "Would you like to see your certificate? \n"
select yn in "Yes" "No"; do
	case "$yn" in
        Yes ) openssl x509 -in public.pem -text -noout | less;break;;
        No ) break;;
        esac
done

exit 0
