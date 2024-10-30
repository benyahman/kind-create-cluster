## kiali/prometheus
kubectl --context kind-c1 port-forward svc/kiali -n istio-system 20001:20001
http://localhost:20001/kiali
istioctl  --context kind-c1 dashboard prometheus

## List all prometheuse metrics
http://localhost:9090/api/v1/label/__name__/values

## helm install/upgrade/uninstall
> helm install    --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  kiali-operator/
> helm upgrade    --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  kiali-operator/
> helm uninstall  --kube-context=kind-c1  --namespace istio-system  kiali-operator-1 

## docker build
docker build -t quay.io/kiali/kiali:v1.49.0-2 .

## kind load image to node
kind load docker-image quay.io/kiali/kiali-operator:v1.87.0 --name c1
kind load docker-image quay.io/kiali/kiali:v1.87.0 --name c1

## start vscode
sudo code --no-sandbox --user-data-dir="/path/to/your/directory"

## force delete namespace
k1 get namespace istio-system -o json | jq '.spec.finalizers=[]' | k1 replace --raw "/api/v1/namespaces/istio-system/finalize" -f -

## test/istio consistent hash
k1 -n sample exec -it helloworld-v1-77cb56d4b4-svsnl -- curl -s helloworld.sample3.svc.cluster.local:5000/hello
k1 -n sample exec -it helloworld-v1-77cb56d4b4-svsnl -- curl -s -H "X-User: abc" helloworld.sample3.svc.cluster.local:5000/hello

## metallb 
docker network inspect -f '{{.IPAM.Config}}' kind
curl 172.18.0.100

## others
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "LoadBalancer"}}'