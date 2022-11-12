#!/bin/bash

### SUDO
## Cmnd_Alias OPENCONNECT = /usr/bin/openconnect
## Cmnd_Alias IP_CMD = /usr/bin/ip
## %wheel ALL=(ALL) NOPASSWD: OPENCONNECT, IP_CMD

OC="/usr/bin/openconnect"
OC_PROTO="anyconnect"
KPBIN="/usr/bin/keepassxc-cli"
KEEPASS_DB="/path/to/my.kdbx"
KEEPASS_ITEM="My/My VPN"
KEEPASS_FILE="n"
KEEPASS_FILE_PATH="/path/to/kp.file"
KEEPASS_YUBI="n"
KEEPASS_YUBI_SLOT="2"

if [ "$KEEPASS_FILE" == "y" ]; then
  KFILE="-k ${KEEPASS_FILE_PATH}"
fi
if [ "$KEEPASS_YUBI" == "y" ]; then
  YUBI="-y${KEEPASS_YUBI_SLOT:-2}"
fi
echo "Enter KeePassXC Password"
KP_ATTR=($($KPBIN show -q $KEEPASS_DB "$KEEPASS_ITEM" $YUBI $KFILE -a Username -a Password -a URL))
if [ ${#KP_ATTR[@]} -lt 3 ]; then
  echo "KeePassXC ERROR !"
  exit 1
fi

function ctrl_c() {
  echo "Remove VPN routes.."
  ROUTE=$(ip r | grep $(dig +short ${KP_ATTR[2]}) | head -n1)
  while [[ ! -z "$ROUTE" ]]; do
    sudo ip r del $ROUTE
    ROUTE=$(ip r | grep $(dig +short ${KP_ATTR[2]}) | head -n1)
  done
}
trap ctrl_c INT

echo "${KP_ATTR[1]}" | sudo $OC --protocol=$OC_PROTO -u ${KP_ATTR[0]} --server=${KP_ATTR[2]} --passwd-on-stdin
