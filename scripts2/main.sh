#!/bin/bash

set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR=$(dirname "${SCRIPTPATH}")
source ${ROOTDIR}/config/config2.env

main_task(){
  bash $ROOTDIR/scripts2/create_cluster.sh
  bash $ROOTDIR/scripts2/istio_create_sample.sh
  bash $ROOTDIR/scripts2/istio_consistent_hash.sh
  bash $ROOTDIR/scripts2/metallb.sh
}

clear(){
    echo "start clear() .."
    rm -rf $FOLDER_PATH_download/*    
    echo "end clear() .."
}

if [[ -n "$istio_version" && -n "$kiali_version" ]]; then    
    main_task
    clear
else
    echo "Error: istio_version and kiali_version must be set."
fi

exit 0