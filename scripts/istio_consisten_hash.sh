#!/bin/bash

set -e
abspath=$(cd "$(dirname "$0")/.."; pwd)
source $abspath/config/config.env

main_task(){    
    echo "context_count="$context_count
    kubectl create --context="${CTX_CLUSTER1}" namespace sample3
    kubectl label --context="${CTX_CLUSTER1}" namespace sample3 \
        istio-injection=enabled
    kubectl apply --context="${CTX_CLUSTER1}" \
        -f $FOLDER_PATH_istio/samples/helloworld/helloworld.yaml \
        -l service=helloworld -n sample3
    kubectl apply --context="${CTX_CLUSTER1}" \
        -f $FOLDER_PATH_istio/samples/helloworld/helloworld.yaml \
        -l version=v1 -n sample3   
    kubectl apply --context="${CTX_CLUSTER1}" \
    -f $FOLDER_PATH_istio/samples/sleep/sleep.yaml -n sample3 

    echo "sleep 60"
    sleep 60

    kubectl get pod --context="${CTX_CLUSTER1}" -n sample3 -l app=helloworld
    kubectl get pod --context="${CTX_CLUSTER1}" -n sample3 -l app=sleep

    # Verifying Cross-Cluster Traffic
    for i in $(seq 1 10); do
    kubectl exec --context="${CTX_CLUSTER1}" -n sample3 -c sleep \
        "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
        app=sleep -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample3:5000/hello
    done  
}

istiod_status=$(kubectl get pod -n istio-system -l app=istiod -o jsonpath='{.items[0].status.phase}')
echo "istiod_status is" $istiod_status
namespace_exists=$(kubectl get ns sample3 --ignore-not-found)

if [[ "$istiod_status" == "Running" && -z "$namespace_exists" ]]; then
    main_task
else
    if [[ "$istiod_status" != "Running" ]]; then
        echo "Waiting for istiod Pod to be Running in the istio-system namespace..."
    fi
    if [[ -n "$namespace_exists" ]]; then
        echo "Namespace 'sample' already exists."
    fi
fi

exit 0

