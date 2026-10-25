#!/usr/bin/env bash
# Builds and starts the SuperKart backend and frontend containers, then tests the API.
set -e

docker network create superkart-net 2>/dev/null || true
docker rm -f backend frontend 2>/dev/null || true

echo "Building backend..."
docker build -q -t superkart-backend backend_files
docker run -d --name backend --network superkart-net -p 7860:7860 superkart-backend

echo "Building frontend..."
docker build -q -t superkart-frontend frontend_files
docker run -d --name frontend --network superkart-net -p 8501:8501 superkart-frontend

echo "Waiting for the API to start..."
for i in $(seq 1 30); do
  curl -s http://localhost:7860/ > /dev/null && break
  sleep 2
done

echo
echo "===== Running containers ====="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo
echo "===== Health check: GET / ====="
curl -s http://localhost:7860/
echo

echo
echo "===== Single inference: POST /v1/predict ====="
curl -s -X POST http://localhost:7860/v1/predict \
  -H "Content-Type: application/json" \
  -d '{"Product_Weight": 12.66, "Product_Sugar_Content": "Low Sugar", "Product_Allocated_Area": 0.027, "Product_MRP": 117.08, "Store_Size": "Medium", "Store_Location_City_Type": "Tier 2", "Store_Type": "Supermarket Type2", "Product_Id_char": "FD", "Store_Age_Years": 16, "Product_Type_Category": "Non Perishables"}'
echo

echo
echo "===== Batch inference: POST /v1/predictbatch ====="
curl -s -X POST http://localhost:7860/v1/predictbatch -F "file=@Batch_Data_SuperKart.csv"
echo
