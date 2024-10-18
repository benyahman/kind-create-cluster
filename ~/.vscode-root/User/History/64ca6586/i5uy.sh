#!/bin/bash

set -e
abspath=$(cd "$(dirname "$0")";pwd)
source $abspath/config/config.env

FILE_PATH_kind=$abspath/tools/kind/kind-c1.yaml

echo "kind version = $kind_version"
echo "istio version = $istio_version"
echo "kiali version = $kiali_version"

pretask(){  
    echo "pretask start .."
    cd $abspath/download    
    # istio
    wget "https://github.com/istio/istio/releases/download/$istio_version/istio-$istio_version-linux-amd64.tar.gz" -O - | tar -xz
    
    # kind
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/$kind_version/kind-linux-amd64    
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
}

delete_kind_cluster(){
echo "delete_kind_cluster .."
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
echo "create_kind_cluster .."
    if [ -f "$FILE_PATH_kind" ]; then
        echo "文件 $FILE_PATH_kind 存在，继续执行操作..."
        #kind create cluster --image=kindest/node:v1.24.0 --name=c1 --config=$FILE_PATH_kind
        kind create cluster  --name=c1 --config=$FILE_PATH_kind
    else
        echo "文件 $FILE_PATH_kind 不存在，脚本终止。"
        exit 1
    fi
}


#program start
if [[ -n "$istio_version" && -n "$kiali_version" ]]; then  
  #pretask
  delete_kind_cluster
  #create_kind_cluster
fi
exit 0
