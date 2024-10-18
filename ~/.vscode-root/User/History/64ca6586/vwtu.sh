#!/bin/bash

set -e
abspath=$(cd "$(dirname "$0")";pwd)
source $abspath/config/config.env


FILE_PATH_kind=$abspath/tools/kind/kind-c1.yaml
FILE_PATH_istio=$abspath/tools/istio/certs/cluster1.yaml
FOLDER_PATH_download=$abspath/download
FOLDER_PATH_certs="$abspath/tools/istio/certs"

echo "kind version = $kind_version"
echo "istio version = $istio_version"
echo "kiali version = $kiali_version"

pretask(){  
    echo "start pretask() .."
    cd $FOLDER_PATH_download    
    # istio
    wget "https://github.com/istio/istio/releases/download/$istio_version/istio-$istio_version-linux-amd64.tar.gz" -O - | tar -xz
    
    # kind
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/$kind_version/kind-linux-amd64    
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
}

delete_kind_cluster(){
    echo "start delete_kind_cluster() .."
    CLUSTERS=$(kind get clusters)
        if [ -n "$kind_version" ] ; then       
            if [ -n "$CLUSTERS" ]; then     
            echo "存在的 Kind 集群如下："
            echo "$CLUSTERS"
            # 如果想删除所有集群，可以使用以下循环：
            for cluster in $CLUSTERS; do
                kind delete cluster --name "$cluster"
                echo "已删除集群: $cluster"
            done
            fi
        fi
}

create_kind_cluster(){
    echo "start create_kind_cluster() .."
    if [ -f "$FILE_PATH_kind" ]; then
        echo "文件 $FILE_PATH_kind 存在，继续..."
        kind create cluster  --name=c1 --config=$FILE_PATH_kind
    else
        echo "文件 $FILE_PATH_kind 不存在，终止。"
        exit 1
    fi
}

istio(){
    echo "start istio() .."
    export CTX_CLUSTER1=kind-c1
    if [ -f "$FILE_PATH_istio" ]; then 
       echo "文件 $FILE_PATH_istio 存在..."
       cd $FOLDER_PATH_download/istio-$istio_version
       export PATH=$abspath/download/istio-$istio_version/bin:$PATH
       pushd $FOLDER_PATH_certs
       kubectl --context=$CTX_CLUSTER1 create namespace istio-system
       kubectl --context=$CTX_CLUSTER1 create secret generic cacerts -n istio-system \
          --from-file=cluster1/ca-cert.pem \
          --from-file=cluster1/ca-key.pem \
          --from-file=cluster1/root-cert.pem \
          --from-file=cluster1/cert-chain.pem
       istioctl install --context="${CTX_CLUSTER1}"  -y -f $FILE_PATH_istio
       popd
    else
      echo "文件 $FILE_PATH_istio 不存在，终止。"
      exit 1
    fi
}

clear(){
    echo "start clear() .."
    rm -rf $FOLDER_PATH_download/*
}

# main() start
if [[ -n "$istio_version" && -n "$kiali_version" ]]; then  
  pretask
  delete_kind_cluster
  create_kind_cluster
  istio
  clear
fi
exit 0