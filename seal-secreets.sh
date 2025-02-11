#!/bin/bash

echo "Sealing secrets..."
for i in $(ls secrets/unsealed); do
  echo "Sealing /secrets/unsealed/$i to /secrets/sealed/$i"
  kubeseal --format yaml --cert ~/.kube/kubeseal.pem < secrets/unsealed/$i > secrets/sealed/$i
done
echo "Done"