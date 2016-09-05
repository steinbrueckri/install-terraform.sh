#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"

# pull in utils
source "${PROGDIR}/utils.sh"

setup() {
  LATEST_TERRAFORM=`curl -s https://releases.hashicorp.com/terraform/ | grep terraform_ | awk -F\" '{print $2}' | head -1`

  if [[ "$LATEST_TERRAFORM" =~ /terraform/([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+) ]]; then
    TERRAFORM_VERSION=${BASH_REMATCH[1]}
    mkdir -p $BASE_INSTALL_DIR/$TERRAFORM_VERSION >/dev/null 2>&1
  else
    echo "Can't get latest version, got '$LATEST_TERRAFORM'"
    exit 1
  fi

  if [ -f "$BASE_INSTALL_DIR/$TERRAFORM_VERSION/terraform" ]; then
    echo "Destination dir $BASE_INSTALL_DIR/$TERRAFORM_VERSION already exists and contains the terraform executable. You can already use terraform."
    exit 1
  fi

  readonly DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  INSTALL_DIR=$BASE_INSTALL_DIR/$TERRAFORM_VERSION
}

# Make sure we have all the right stuff
prerequisites() {
  local curl_cmd=`which curl`
  local unzip_cmd=`which unzip`

  if [ -z "$curl_cmd" ]; then
    error "curl does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  if [ -z "$unzip_cmd" ]; then
    error "unzip does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  # we want to be root to install / uninstall
  if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
    exit 1
  fi
}


# Install Terraform
install_terraform() {
  echo ""
  echo "Downloading Terraform zip'd binary"
  curl -o "$DOWNLOADED_FILE" "$DOWNLOAD_URL"
  if [ $? -ne 0 ]; then
    echo "Error downloading from $DOWNLOAD_URL"
    exit 1
  fi

  echo ""
  echo "Extracting Terraform executable"
  unzip "$DOWNLOADED_FILE" -d "$INSTALL_DIR"

  rm "$DOWNLOADED_FILE"
}

add_helper() {
  echo "Writing $SUPPORT_FILE ..."
  cat >$SUPPORT_FILE <<EOF
function terraform {
  echo -n "Terraform wrapper: "
EOF

  count=0
  for i in `cd $BASE_INSTALL_DIR; ls -d *`
  do
    if [ $count -eq 0 ]; then
      echo "  if [ -f $i ]; then" >>$SUPPORT_FILE
    else
      echo "  elif [ -f $i ]; then" >>$SUPPORT_FILE
    fi
    echo -e "    echo \"found $i\"\n    /opt/terraform/$i/terraform \"\$@\"" >>$SUPPORT_FILE
    let "count = $count + 1"
  done

  cat >>$SUPPORT_FILE <<EOF
  else
    echo "no terraform version file found."
  fi
}
EOF

}

main() {
  # Be unforgiving about errors
  set -euo pipefail
  readonly SELF="$(absolute_path $0)"
  prerequisites
  cd "${PROGDIR}" || exit 1
  setup
  bash uninstall-terraform.sh || exit 1
  install_terraform
  add_helper
}

[[ "$0" == "$BASH_SOURCE" ]] && main
