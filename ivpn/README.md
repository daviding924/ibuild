## Server Side as VPN server

strongswan

IPSec

config:

~/.ssh/authorized_keys

https://github.com/daviding924/ibuild/blob/master/etc/strongswan.conf

https://github.com/daviding924/ibuild/blob/master/etc/ipsec.conf

https://github.com/daviding924/ibuild/blob/master/etc/ipsec.secrets

https://github.com/daviding924/ibuild/blob/master/etc/sysctl.conf

https://github.com/daviding924/ibuild/blob/master/etc/iptables/rules.v4

https://github.com/daviding924/ibuild/blob/master/etc/security/limits.conf

https://github.com/daviding924/ibuild/blob/master/etc/rc.local.srv

### Linux Client Side as WiFi AP over VPN

iptables

hostapd

sshuttle

dnsmsaq

config:

https://github.com/daviding924/ibuild/blob/master/etc/dnsmasq.conf

https://github.com/daviding924/ibuild/blob/master/etc/rc.local.pi

https://github.com/daviding924/ibuild/blob/master/etc/hostapd/hostapd.conf

### iOS Client Side
IPSec VPN

### setup strongswan
wget https://download.strongswan.org/strongswan-5.5.0.tar.bz2

tar xfj strongswan-5.5.0.tar.bz2

icd strongswan-5.5.0
#aptitude install arno-iptables-firewall

aptitude install libssl-dev libpam0g-dev

./configure --enable-eap-identity --enable-eap-md5 --enable-eap-mschapv2 --enable-eap-tls --enable-eap-ttls --enable-eap-peap --enable-eap-tnc --enable-eap-dynamic --enable-eap-radius --enable-xauth-eap --enable-xauth-pam --enable-dhcp --enable-openssl --enable-addrblock --enable-unity --enable-certexpire --enable-radattr --enable-tools --enable-openssl --disable-gmp --enable-nat-transport --disable-mysql --disable-ldap --prefix=/usr --sysconfdir=/etc

make

make install

### setup ipsec
sudo cp ipsec.conf ipsec.secrets strongswan.conf sysctl.conf /etc/

change Your_Account and Your_Password in ipsec.secrets

merge rc.local to /etc/rc.local

sysctl -p

### setup CA and key
ipsec pki --gen --outform pem > ca.pem

ipsec pki --self --in ca.pem --dn "C=com, O=dwvpn, CN=dwvpn" --ca --outform pem >ca.cert.pem

ipsec pki --gen --outform pem > server.pem

ipsec pki --pub --in server.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=com, O=dwvpn, CN=dwvpn" --san="dwvpn" --flag serverAuth --flag ikeIntermediate --outform pem > server.cert.pem

ipsec pki --gen --outform pem > client.pem

ipsec pki --pub --in client.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=com, O=dwvpn, CN=dwvpn" --outform pem > client.cert.pem

openssl pkcs12 -export -inkey client.pem -in client.cert.pem -name "client" -certfile ca.cert.pem -caname "dwvpn" -out client.cert.p12

cp -r ca.cert.pem /etc/ipsec.d/cacerts/

cp -r server.cert.pem /etc/ipsec.d/certs/

cp -r server.pem /etc/ipsec.d/private/

cp -r client.cert.pem /etc/ipsec.d/certs/

cp -r client.pem /etc/ipsec.d/private/

### debug mode
ipsec start --nofork










