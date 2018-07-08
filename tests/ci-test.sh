#!/usr/bin/env bash

if [[ ! -f yaml.sh ]]; then
  echo "Fetching YAML parsing script..."
  wget -q https://raw.githubusercontent.com/jasperes/bash-yaml/master/yaml.sh
fi
. yaml.sh

BLDRED='\033[1;31m'
BLDGRN='\033[1;32m'
BLDBLU='\033[1;34m'
BLDYLW='\033[1;33m' # Yellow
BLDMGT='\033[1;35m' # Magenta
BLDCYN='\033[1;36m' # Cyan 
TXTRST='\033[0m'

pass () {
  printf "%b\n" "${BLDGRN}[PASS]${TXTRST} $1"
}

fail () {
  printf "%b\n" "${BLDRED}[FAIL]${TXTRST} $1"
}

skip() {
  printf "%b\n" "${BLDCYN}[SKIP]${TXTRST} $1"
}

redText() {
  printf "%b\n" "${BLDRED}$1${TXTRST}"
}

vagrantExists() {
  if ! vagrant_loc="$(type -p vagrant)" || [[ -z $vagrant_loc ]]; then
    echo "1"
  fi
  echo "0"
}

vagrantUp() {
  if [[ "$(vagrantExists)" == "0" ]]; then
    vagrant up
    return $?
  else
    redText "[vagrantUp] vagrant not found!"
  fi
}

vagrantDestroy() {
  if [[ "$(vagrantExists)" == "0" ]]; then
    vagrant destroy -f
    return $?
  else
    redText "[vagrantDestroy] vagrant not found!"
  fi
}

vagrantBoxAdd() {
  if [[ "$(vagrantExists)" == "0" ]]; then
    vagrant box add $1
    return $?
  else
    redText "[vagrantBoxAdd] vagrant not found!"
  fi
  return 0
}

LIMIT=$1

echo "Starting tests..."
boxes=$(parse_yaml vagrant_config.yml | grep _box | cut -d= -f2 | sed 's/[\(\"\)]//g' | sed "s/'//g" | sort | uniq)
for box in $boxes; do
  if [[ "$box" != *"$LIMIT"* ]]; then
    skip "Download $box"
    continue
  fi
  vagrantBoxAdd $box
  # A bit unstable downloads and if already downloaded exit code 1 is returned.
  # So ignore exit code for now.
  if [[ "$?" == "0" ]]; then
    pass "Download $box"
  else
    pass "Download $box"
  fi
done

configs=$(parse_yaml vagrant_config.yml | grep _box | awk '{split($0,a,"_box"); $1=a[1]; split($1,b,"configs_"); $2=b[2];  print $2}')
exitCode=0
for config in $configs; do
  CONFIG_KEY=$config
  if [[ "$CONFIG_KEY" != *"$LIMIT"* ]]; then
    skip "$CONFIG_KEY"
    continue
  fi
  vagrantUp
  exitCode=$?
  vagrantDestroy
  if [[ $exitCode == "0" ]]; then
    pass "Test $CONFIG_KEY"
  else
    fail "Test $CONFIG_KEY"
    break
  fi
done
echo "Ended with exit code $exitCode"
exit $exitCode