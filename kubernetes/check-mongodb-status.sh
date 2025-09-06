#!/bin/bash

echo "MongoDB Kubernetes Troubleshooting Script"
echo "---------------------------------------"

# Define namespace
NAMESPACE="healthcare"
echo "Using namespace: $NAMESPACE"

# Check if MongoDB StatefulSet exists
echo -e "\nChecking MongoDB StatefulSet..."
kubectl get statefulset mongodb -n $NAMESPACE

# Check MongoDB pods
echo -e "\nChecking MongoDB pods..."
kubectl get pods -n $NAMESPACE | grep mongodb

# Get detailed information about the MongoDB pod
echo -e "\nDetailed information about the MongoDB pod..."
kubectl describe pod mongodb-0 -n $NAMESPACE

# Check MongoDB logs
echo -e "\nChecking MongoDB container logs..."
kubectl logs mongodb-0 -n $NAMESPACE

# Check MongoDB events
echo -e "\nChecking Kubernetes events related to MongoDB..."
kubectl get events -n $NAMESPACE | grep mongodb

# Check Persistent Volume Claims
echo -e "\nChecking Persistent Volume Claims..."
kubectl get pvc -n $NAMESPACE | grep mongodb

# Check Storage Classes
echo -e "\nChecking Storage Classes available in the cluster..."
kubectl get storageclass

# Check if MongoDB service is running
echo -e "\nChecking MongoDB service..."
kubectl get service mongodb -n $NAMESPACE

# Check network connectivity to MongoDB
echo -e "\nChecking network connectivity to MongoDB service..."
kubectl run -i --rm --tty mongodb-test --image=mongo:6.0 --restart=Never -n $NAMESPACE -- bash -c "for i in {1..5}; do mongosh --host mongodb --eval 'db.adminCommand(\"ping\")' && echo 'Connection successful!' && exit 0; echo 'Retrying in 2s...'; sleep 2; done; echo 'Connection failed!'; exit 1"

echo -e "\nTroubleshooting complete. Check the output above for issues."
echo "If you need to restart the MongoDB pod, run: kubectl delete pod mongodb-0 -n $NAMESPACE"
echo "To apply the StatefulSet again, run: kubectl apply -f kubernetes/mongodb-statefulset.yaml -n $NAMESPACE"