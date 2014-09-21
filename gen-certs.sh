#!/bin/bash
# ./gen-certs.sh
# by: Sahal Ansari github@sahal.info
# interactively generate a self signed certificate

openssl="/usr/bin/openssl"
# $DIR is from http://stackoverflow.com/questions/59895/
DIR="$( cd "$( dirname "$0" )" && pwd )"
ssl_dir="$DIR/keys"
#subj_info="/CN=www.example.com/O=OnShore Example, Inc./C=US/ST=New York/L=New York"
conf_file="$DIR/openssl.cnf"

function die {
#$1 = message
        echo "$1"
        exit 1
}

function noyes { # this time its not pronounced NOISE, baby baby

# nest quotes like so
# noyes "echo 'you said no!';exit" "echo 'you said yes!'" 

#$1 = if no do this
#$2 = if yes do this

if [ -z "$1" ]; then
   die "WARNING: function noyes - no (\$1) not set"
fi

if [ -z "$2" ]; then
   die "WARNING: function noyes - yes (\$2) not set"
fi

select yn in "Yes" "No"; do
        case "$yn" in
        Yes ) eval "$2"; break;;
        No ) eval "$1"; break;;
        esac
done

}

function generate_keys {

if [ -z "$1" ]; then
   die "WARNING: Something went wrong?"
fi

echo "How many days to certify the certificate?"
read days
case "$days" in
    *[a-z]* ) die "Nice try...";;
    *[A-Z]* ) die "Nice try...";;
    *[0-9]* ) echo "Okay.";;
    * ) die "Nice try?..";;
esac

if [ "$1" -eq "1" ]; then
# Note: -nodes generates an SSL key without a passphrase (i.e. it will be stored unencrypted.)
#+If you do generate an SSL key with a passphrase, you'll have to input it everytime you restart apache
   "$openssl" req -nodes -sha256 -new -x509 -newkey rsa:4096 -days "$days" -subj "$subj_info" -keyout private.pem -out public.pem
elif [ "$1" -eq "0" ]; then
   "$openssl" req -new -x509 -days "$days" -config "$conf_file" -keyout private.pem -out public.pem
else
   die "WARNING: \$subj not set. Are you sure you specified either \$subj_info or \$conf_file?"
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
   die "WARNING: \$subj_info or \$conf_file is unset or \$conf_file is set but doesn't exist."
fi
echo "Do you want to continue?"
noyes "die 'Edit Options and Launch again!'" "echo 'Okay.'"

mkdir -p "$ssl_dir"
cd "$ssl_dir"

if [ -e  private.pem ] || [ -e public.pem ]; then
	echo "private.pem and/or public.pem already exist(s). Do you wish to delete and regenerate?"
	noyes "die 'Okay.'" "rm private.pem; rm public.pem;generate_keys '$subj'"
else
	generate_keys "$subj"
fi

echo -ne "Would you like to see your certificate? \n"
noyes "echo 'Okay.'" "openssl x509 -in public.pem -text -noout | less"
