kubectl --context kind-c1 port-forward svc/kiali -n istio-system 20001:20001
http://localhost:20001/kiali

istioctl  --context kind-c1 dashboard prometheus

列出所有抓的metrics
http://localhost:9090/api/v1/label/__name__/values

helm install    --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  kiali-operator/
helm upgrade    --kube-context=kind-c1  --namespace=istio-system --create-namespace kiali-operator-1  kiali-operator/
helm uninstall  --kube-context=kind-c1  --namespace istio-system  kiali-operator-1 

docker build -t quay.io/kiali/kiali:v1.49.0-2 .
kind load docker-image quay.io/kiali/kiali-operator:v1.87.0 --name c1
kind load docker-image quay.io/kiali/kiali:v1.87.0 --name c1

sudo code --no-sandbox --user-data-dir="/path/to/your/directory"

istioctl  --context kind-c1 dashboard prometheus
kubectl --context kind-c1  port-forward svc/kiali -n istio-system 20001:20001
http://localhost:20001/kiali
