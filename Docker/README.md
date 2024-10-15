
docker build -t quay.io/kiali/kiali:v1.49.0-2 .
kind load docker-image quay.io/kiali/kiali:v1.49.0-1 --name c1
