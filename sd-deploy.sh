#!/bin/bash -xe

# Default Params
db_host="localhost"
db_port="3306"
db_name="ssc"
db_user="ssc"
db_pass="Password123"
sd_host=$(hostname -f)
sd_vers="17.2"
sd_port="8100"
sd_license_port="8101"
alert_email="root@localhost"
alert_server="localhost"
sources="/var/cache/ssc"
logs="/var/logs/ssc"
usercfg="/root/.sd-config.sh"

# Drop license files into the licenses folder add_licenses <SDVers> <csv>
add_licenses() {
    IFS=, lics=( $2 )
    for (( i=0; i<${#lics[@]} ; i++ ))
    do
        echo "${lics[i]}" > /opt/riverbed_ssc_$1/licenses/lic_${i}.txt
    done
}

# Load user configuration. Exit if they don't exist
if [ -f $usercfg ]
then
    source /root/.sd-config.sh
else
    echo "ERROR - No Configuration found" >&2
    exit 1
fi

certfile=${sources}/cert.pem
keyfile=${sources}/key.pem
mkdir -p $sources
mkdir -p $logs

# Check we have certificates
if [ -f "$certfile" -o -n "$cert" ]
then
    if [ -n "$cert" ]
    then
        echo -e "$cert" > $certfile
    fi
else
    echo "ERROR - No Certificate found in config or on disk" >&2
    exit 1
fi

# Check we have keys
if [ -f "$keyfile" -o -n "$key" ]
then
    if [ -n "$key" ]
    then
        echo -e "$key" > $keyfile
    fi
else
    echo "ERROR - No Private Key found in config or on disk" >&2
    exit 1
fi

cat <<-EOF | debconf-set-selections
    riverbed-ssc ssc/db/host string $db_host
    riverbed-ssc ssc/db/port string $db_port
    riverbed-ssc ssc/db/name string $db_name
    riverbed-ssc ssc/db/user string $db_user
    riverbed-ssc ssc/db/password password $db_pass
    riverbed-ssc ssc/server/name string $sd_host
    riverbed-ssc ssc/server/port string $sd_port
    riverbed-ssc ssc/server/license_port string $sd_license_port
    riverbed-ssc ssc/server/cert_file string $certfile
    riverbed-ssc ssc/server/key_file string $keyfile
    riverbed-ssc ssc/server/numthreads string 20
    riverbed-ssc ssc/server/actionthreads string 5
    riverbed-ssc ssc/server/monitorthreads string 20
    riverbed-ssc ssc/server/meteringthreads string 20
    riverbed-ssc ssc/files/sources string $sources
    riverbed-ssc ssc/files/logs string $logs
    riverbed-ssc ssc/alerts/address string $alert_email
    riverbed-ssc ssc/alerts/smtp_host string $alert_server
    riverbed-ssc ssc/alerts/smtp_port string 25
EOF

DEBIAN_FRONTEND=noninteractive dpkg -i /root/sd-package.deb

# Install SD Licenses
add_licenses "$sd_vers" "$license"

# Setup database

# Start ssc
#service ssc start