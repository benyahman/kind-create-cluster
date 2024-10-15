#!/bin/bash

set -e
echo "kind create cluster"

KIND_VERSION=$(kind version 2>/dev/null)
CLUSTERS=$(kind get clusters)
istio_version=1.13.5
kiali_version=v1.49.0 
#istio_version=1.23.0
#kiali_version=v1.87.0 

FILE_PATH_kind="/userap/hb/kind/kind-c1.yaml"

FILE_PATH_istio="/userap/hb/kind/istio-$istio_version/certs/cluster1.yaml"

FOLDER_PATH_istio="/userap/hb/kind/istio-$istio_version"
FOLDER_PATH_certs="/userap/hb/kind/istio-$istio_version/certs"
FOLDER_PATH_kiali="/userap/hb/kind/kiali/$kiali_version/helm-charts"

#pods_status=$(kubectl --context=$CTX_CLUSTER1 get pods --all-namespaces --field-selector=status.phase!=Running)

# 判断集群列表是否为空
if [ -n "$KIND_VERSION" ] ; then       
   if [ -n "$CLUSTERS" ]; then     
       echo "存在的 Kind 集群如下："
       echo "$CLUSTERS"
       # 如果想删除所有集群，可以使用以下循环：
       for cluster in $CLUSTERS; do
           kind delete cluster --name "$cluster"
           echo "已删除集群: $cluster"
       done
    fi

    # step1 : kind create cluster
    
    echo "开始执行，等待10秒..."
    sleep 10
    echo "继续执行..."
    if [ -f "$FILE_PATH_kind" ]; then
       echo "文件 $FILE_PATH_kind 存在，继续执行操作..."
       kind create cluster --image=kindest/node:v1.24.0 --name=c1 --config=$FILE_PATH_kind
    else
      echo "文件 $FILE_PATH_kind 不存在，脚本终止。"
      exit 1
    fi

    # step2 : istioctl install 1.13.5

    export CTX_CLUSTER1=kind-c1
    if [ -f "$FILE_PATH_istio" ]; then
       echo "开始执行，等待10秒..."
       sleep 10
       echo "继续执行..."
       echo "文件 $FILE_PATH_istio 存在，继续执行操作..."
       export PATH="$PATH:/usr/local/istio-$istio_version/bin"
       pushd $FOLDER_PATH_certs
       kubectl --context=$CTX_CLUSTER1 create namespace istio-system
       kubectl --context=$CTX_CLUSTER1 create secret generic cacerts -n istio-system \
          --from-file=cluster1/ca-cert.pem \
          --from-file=cluster1/ca-key.pem \
          --from-file=cluster1/root-cert.pem \
          --from-file=cluster1/cert-chain.pem
       istioctl install --context="${CTX_CLUSTER1}"  -y -f cluster1.yaml
       popd
    else
      echo "文件 $FILE_PATH_istio 不存在，脚本终止。"
      exit 1
    fi

    # step3 : kiali operator install
    echo "开始执行，等待10秒..."
    sleep 10
    echo "继续执行..."
    kind load docker-image quay.io/kiali/kiali-operator:$kiali_version --name c1
    kind load docker-image quay.io/kiali/kiali:v1.49.0-3 --name c1
    pushd $FOLDER_PATH_kiali
    helm install --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  kiali-operator/
    popd

    # step4 : prometheus install
    echo "开始执行，等待10秒..."
    sleep 10
    echo "继续执行..."
    pushd $FOLDER_PATH_istio
    kubectl --context=$CTX_CLUSTER1 apply  -f samples/addons/prometheus.yaml
    popd

    # step5 : check all pod is running
    echo "开始执行，等待10秒..."
    sleep 10
    echo "继续执行..."
    pods_status=$(kubectl --context=$CTX_CLUSTER1 get pods --all-namespaces --field-selector=status.phase!=Running)
    if [ -z "$pods_status" ]; then
       echo "所有 Pod 都处于 Running 状态。"
    else
       echo "以下 Pod 不在 Running 状态："
       echo "$pods_status"
       exit 1
    fi
else
  # 检查不同情况下的输出提示
    if [ -z "$KIND_VERSION" ]; then
        echo "Kind 未安装或无法获取版本信息。"
    fi
    if [ -z "$CLUSTERS" ]; then
        echo "没有找到任何 Kind 集群。"
    fi
fi
