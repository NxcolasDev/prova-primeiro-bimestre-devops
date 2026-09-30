#!/bin/bash
# Script para gerar evidencias de CRUD completo
# Uso: bash evidencias/gerar-evidencias.sh > evidencias/curl-crud-tests.txt

BASE="http://localhost:3000"

echo "=== POST /reservas (Create) ==="
RESPONSE=$(curl -s -X POST "$BASE/reservas" \
  -H "Content-Type: application/json" \
  -d '{"cliente":"Nicolas Silva","data":"2026-10-15","status":"CONFIRMADA"}')
echo "$RESPONSE"

# Extrai o id criado para usar nas proximas chamadas
ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')

echo -e "\n\n=== GET /reservas (Read All) ==="
curl -s "$BASE/reservas"

echo -e "\n\n=== GET /reservas/$ID (Read One) ==="
curl -s "$BASE/reservas/$ID"

echo -e "\n\n=== PUT /reservas/$ID (Update) ==="
curl -s -X PUT "$BASE/reservas/$ID" \
  -H "Content-Type: application/json" \
  -d '{"cliente":"Nicolas Silva","data":"2026-10-16","status":"FINALIZADA"}'

echo -e "\n\n=== GET /reservas/$ID (Confirma Update) ==="
curl -s "$BASE/reservas/$ID"

echo -e "\n\n=== DELETE /reservas/$ID (Delete) ==="
curl -s -X DELETE "$BASE/reservas/$ID" -w "HTTP Status: %{http_code}"

echo -e "\n\n=== GET /reservas/$ID apos DELETE (deve retornar 404) ==="
curl -s "$BASE/reservas/$ID"

echo -e "\n\n=== GET /health ==="
curl -s "$BASE/health"
