#!/bin/bash

set -e
abspath=$(cd "$(dirname "$0")";pwd)
source $abspath/config/config.env

FILE_PATH_kind=$abspath/tools/kind/kind-c1.yaml
FILE_PATH_istio=$abspath/tools/istio/certs/cluster1-$istio_version.yaml
FILE_PATH_kiali="$abspath/tools/kiali/$kiali_version/helm-charts/kiali-operator/values.yaml"
FILE_PATH_prometheus="$abspath/download/istio-$istio_version/samples/addons/prometheus.yaml"
FOLDER_PATH_download=$abspath/download
FOLDER_PATH_certs="$abspath/tools/istio/certs"
FOLDER_PATH_kiali="$abspath/tools/kiali/$kiali_version/helm-charts/kiali-operator"

print_kind_version=v$(kind --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
available_processes=("main" "pretask" "delete_kind_cluster" "create_kind_cluster" "istio" "prometheus" "kiali" "clear")

pretask(){
    echo "start pretask() .."
    echo "kind version  = $kind_version"
    echo "istio version = $istio_version"
    echo "kiali version = $kiali_version"
    # download istio
    if [ -z "$(ls -A "$FOLDER_PATH_download" 2>/dev/null)" ]; then
        echo "start istio download"
        cd $FOLDER_PATH_download        
        wget "https://github.com/istio/istio/releases/download/$istio_version/istio-$istio_version-linux-amd64.tar.gz" -O - | tar -xz
    fi 

    # download kind
    if [ "$print_kind_version" != "$kind_version" ]; then
        echo "start kind download"
        [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/$kind_version/kind-linux-amd64    
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    echo "end pretask() .."
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
    echo "end delete_kind_cluster() .."
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
    echo "end create_kind_cluster() .."
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
    echo "end istio() .."
}

prometheus(){
    echo "start prometheus() .."
    if [ -f "$FILE_PATH_prometheus" ]; then 
       echo "文件 $FILE_PATH_prometheus 存在..."
       kubectl --context=$CTX_CLUSTER1 apply  -f $FILE_PATH_prometheus
    else
      echo "文件 $FILE_PATH_prometheus 不存在，终止。"
    fi
    echo "end prometheus() .."
}

kiali(){
    echo "start kiali() .."
    if [ -f "$FILE_PATH_kiali" ]; then
      docker pull quay.io/kiali/kiali:$kiali_version
      kind load docker-image quay.io/kiali/kiali-operator:$kiali_version --name c1
      kind load docker-image quay.io/kiali/kiali:$kiali_version --name c1
      echo "start sleep 10 .."
      sleep 10
      echo "end sleep 10.."
      helm install --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  $FOLDER_PATH_kiali
    else
      echo "文件 $FILE_PATH_kiali 不存在，终止。"
    fi
    echo "end kiali() .."
}

clear(){
    echo "start clear() .."
    rm -rf $FOLDER_PATH_download/*
    echo "end clear() .."
}

main(){
  pretask
  delete_kind_cluster
  create_kind_cluster
  istio
  prometheus
  kiali    
  clear
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <process_name>"
    echo "Available processes: ${available_processes[*]}"
    exit 1
fi

input_process="$1"
echo "Available processes: ${available_processes[*]}"
echo $input_process

if [[ " ${available_processes[*]} " == *" $input_process "* ]]; then
    if [[ -n "$istio_version" && -n "$kiali_version" ]]; then
        "$input_process"
    else
        echo "Error: istio_version and kiali_version must be set."
    fi
else
    echo "Error: Invalid process name '$input_process'."
    echo "Available processes: ${available_processes[*]}"
    exit 1
fi
exit 0