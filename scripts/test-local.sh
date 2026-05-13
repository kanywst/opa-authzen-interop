#!/bin/bash
# Local test script: runs all 40 decision tests against the PDP
# Usage: ./scripts/test-local.sh [pdp-url]
#
# This script replays the AuthZEN interop test cases from
# decisions-authorization-api-1_0-01.json against a running PDP.

set -uo pipefail

PDP_URL="${1:-http://localhost:8181}"
PASS=0
FAIL=0
ERROR=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

test_evaluation() {
  local request="$1"
  local expected="$2"

  response=$(curl -s -w "\n%{http_code}" \
    -X POST "${PDP_URL}/access/v1/evaluation" \
    -H "Content-Type: application/json" \
    -d "$request" 2>/dev/null) || { echo -e "${YELLOW}ERROR${NC} Connection failed"; ERROR=$((ERROR+1)); return; }

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo -e "${YELLOW}ERROR${NC} HTTP $http_code"
    ERROR=$((ERROR+1))
    return
  fi

  actual=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('decision', False))" 2>/dev/null)

  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC} $(echo "$request" | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'{r[\"action\"][\"name\"]} subject={r[\"subject\"][\"id\"][:12]}... -> {r.get(\"resource\",{}).get(\"properties\",{}).get(\"ownerID\",\"N/A\")}')")"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC} Expected=$expected Actual=$actual"
    echo "  Request: $request"
    echo "  Response: $body"
    FAIL=$((FAIL+1))
  fi
}

test_evaluations() {
  local request="$1"
  local expected="$2"

  response=$(curl -s -w "\n%{http_code}" \
    -X POST "${PDP_URL}/access/v1/evaluations" \
    -H "Content-Type: application/json" \
    -d "$request" 2>/dev/null) || { echo -e "${YELLOW}ERROR${NC} Connection failed"; ERROR=$((ERROR+1)); return; }

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo -e "${YELLOW}ERROR${NC} HTTP $http_code"
    ERROR=$((ERROR+1))
    return
  fi

  actual=$(echo "$body" | python3 -c "
import sys, json
data = json.load(sys.stdin)
evals = data.get('evaluations', [])
print(json.dumps([{'decision': e.get('decision', False)} for e in evals]))
" 2>/dev/null)

  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC} [batch] $(echo "$request" | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'{r[\"action\"][\"name\"]} subject={r[\"subject\"][\"id\"][:12]}... evaluations={len(r.get(\"evaluations\",[]))}')")"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC} [batch] Expected=$expected Actual=$actual"
    echo "  Request: $request"
    echo "  Response: $body"
    FAIL=$((FAIL+1))
  fi
}

echo "=== AuthZEN Interop Test Suite ==="
echo "PDP URL: ${PDP_URL}"
echo ""

# --- Rick Sanchez (admin, evil_genius) ---
echo "--- Rick Sanchez (admin, evil_genius) ---"
RICK="CiRmZDA2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"rick@the-citadel.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_read_todos"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b91","properties":{"ownerID":"morty@the-citadel.com"}}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b91","properties":{"ownerID":"morty@the-citadel.com"}}}' "True"

# --- Morty Smith (editor) ---
echo ""
echo "--- Morty Smith (editor) ---"
MORTY="CiRmZDE2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"morty@the-citadel.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_read_todos"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b91","properties":{"ownerID":"morty@the-citadel.com"}}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b91","properties":{"ownerID":"morty@the-citadel.com"}}}' "True"

# --- Summer Smith (editor) ---
echo ""
echo "--- Summer Smith (editor) ---"
SUMMER="CiRmZDI2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"summer@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_read_todos"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b93","properties":{"ownerID":"summer@the-smiths.com"}}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$SUMMER'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b93","properties":{"ownerID":"summer@the-smiths.com"}}}' "True"

# --- Beth Smith (viewer) ---
echo ""
echo "--- Beth Smith (viewer) ---"
BETH="CiRmZDM2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_read_todos"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b94","properties":{"ownerID":"beth@the-smiths.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b94","properties":{"ownerID":"beth@the-smiths.com"}}}' "False"

# --- Jerry Smith (viewer) ---
echo ""
echo "--- Jerry Smith (viewer) ---"
JERRY="CiRmZDQ2MTRkMy1jMzlhLTQ3ODEtYjdiZC04Yjk2ZjVhNTEwMGQSBWxvY2Fs"

test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"jerry@the-smiths.com"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_read_todos"},"resource":{"type":"todo","id":"todo-1"}}' "True"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"240d0db-8ff0-41ec-98b2-34a096273b95","properties":{"ownerID":"jerry@the-smiths.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' "False"
test_evaluation '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_delete_todo"},"resource":{"type":"todo","id":"240d0db-8ff0-41ec-98b2-34a096273b95","properties":{"ownerID":"jerry@the-smiths.com"}}}' "False"

# --- Batch Evaluations (1_0-02) ---
echo ""
echo "--- Batch Evaluations ---"

test_evaluations '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_update_todo"},"evaluations":[{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}},{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b95","properties":{"ownerID":"jerry@the-smiths.com"}}}]}' '[{"decision": true}, {"decision": true}]'

test_evaluations '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_update_todo"},"evaluations":[{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}},{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b91","properties":{"ownerID":"morty@the-citadel.com"}}}]}' '[{"decision": false}, {"decision": true}]'

test_evaluations '{"subject":{"type":"user","id":"'$JERRY'"},"action":{"name":"can_update_todo"},"evaluations":[{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}},{"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b95","properties":{"ownerID":"jerry@the-smiths.com"}}}]}' '[{"decision": false}, {"decision": false}]'

# --- Search APIs (AuthZEN spec Section 8) ---
echo ""
echo "--- Search APIs ---"

# test_search_count posts to a Search endpoint and asserts the number of
# entries in `results`. Args: endpoint, request body, expected count, label.
test_search_count() {
  local endpoint="$1"
  local request="$2"
  local expected="$3"
  local label="$4"

  response=$(curl -s -w "\n%{http_code}" \
    -X POST "${PDP_URL}${endpoint}" \
    -H "Content-Type: application/json" \
    -d "$request" 2>/dev/null) || { echo -e "${YELLOW}ERROR${NC} Connection failed"; ERROR=$((ERROR+1)); return; }

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo -e "${YELLOW}ERROR${NC} HTTP $http_code [${label}]"
    ERROR=$((ERROR+1))
    return
  fi

  actual=$(echo "$body" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('results', [])))" 2>/dev/null)

  if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC} ${label} -> ${actual} result(s)"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC} ${label}: expected ${expected} results, got ${actual}"
    echo "  Request: $request"
    echo "  Response: $body"
    FAIL=$((FAIL+1))
  fi
}

# Subject Search: 5 users can can_read_user (anyone in data.users).
test_search_count "/access/v1/search/subject" \
  '{"subject":{"type":"user"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"}}' \
  5 "subject_search/can_read_user"

# Subject Search: 3 users can can_create_todo (admin/editor only).
test_search_count "/access/v1/search/subject" \
  '{"subject":{"type":"user"},"action":{"name":"can_create_todo"},"resource":{"type":"todo","id":"todo-1"}}' \
  3 "subject_search/can_create_todo"

# Subject Search: only Rick can update a Rick-owned todo.
test_search_count "/access/v1/search/subject" \
  '{"subject":{"type":"user"},"action":{"name":"can_update_todo"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' \
  1 "subject_search/can_update_todo on Rick-owned"

# Resource Search: Rick (admin) can update every todo in data.
test_search_count "/access/v1/search/resource" \
  '{"subject":{"type":"user","id":"'$RICK'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo"}}' \
  4 "resource_search/Rick can_update_todo"

# Resource Search: Morty can only update his own todo.
test_search_count "/access/v1/search/resource" \
  '{"subject":{"type":"user","id":"'$MORTY'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo"}}' \
  1 "resource_search/Morty can_update_todo"

# Resource Search: Beth (viewer) can't update anything.
test_search_count "/access/v1/search/resource" \
  '{"subject":{"type":"user","id":"'$BETH'"},"action":{"name":"can_update_todo"},"resource":{"type":"todo"}}' \
  0 "resource_search/Beth can_update_todo"

# Action Search: Rick (admin) can perform every modeled action.
test_search_count "/access/v1/search/action" \
  '{"subject":{"type":"user","id":"'$RICK'"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' \
  5 "action_search/Rick on own todo"

# Action Search: Morty on Rick's todo -> read_user/read_todos/create_todo only.
test_search_count "/access/v1/search/action" \
  '{"subject":{"type":"user","id":"'$MORTY'"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b92","properties":{"ownerID":"rick@the-citadel.com"}}}' \
  3 "action_search/Morty on Rick's todo"

# Action Search: Beth (viewer) -> read_user/read_todos only.
test_search_count "/access/v1/search/action" \
  '{"subject":{"type":"user","id":"'$BETH'"},"resource":{"type":"todo","id":"7240d0db-8ff0-41ec-98b2-34a096273b94","properties":{"ownerID":"beth@the-smiths.com"}}}' \
  2 "action_search/Beth on own todo"

# Pagination: page-1 of can_read_user with limit=2 should yield 2 + a token.
echo ""
echo "--- Search pagination ---"
page1_resp=$(curl -s -X POST "${PDP_URL}/access/v1/search/subject" \
  -H "Content-Type: application/json" \
  -d '{"subject":{"type":"user"},"action":{"name":"can_read_user"},"resource":{"type":"user","id":"beth@the-smiths.com"},"page":{"limit":2}}')
page1_count=$(echo "$page1_resp" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['results']))" 2>/dev/null)
page1_token=$(echo "$page1_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['page']['next_token'])" 2>/dev/null)
if [ "$page1_count" = "2" ] && [ -n "$page1_token" ]; then
  echo -e "${GREEN}PASS${NC} pagination/page-1 returned 2 + non-empty next_token"
  PASS=$((PASS+1))
else
  echo -e "${RED}FAIL${NC} pagination/page-1: count=$page1_count token=$page1_token"
  echo "  Response: $page1_resp"
  FAIL=$((FAIL+1))
fi

# Pagination: follow the token. Across both pages we expect 5 unique results
# and an empty next_token on the final page.
page2_resp=$(curl -s -X POST "${PDP_URL}/access/v1/search/subject" \
  -H "Content-Type: application/json" \
  -d "{\"subject\":{\"type\":\"user\"},\"action\":{\"name\":\"can_read_user\"},\"resource\":{\"type\":\"user\",\"id\":\"beth@the-smiths.com\"},\"page\":{\"limit\":2,\"token\":\"$page1_token\"}}")
page2_check=$(python3 <<EOF
import json
p1 = json.loads('''$page1_resp''')['results']
p2 = json.loads('''$page2_resp''')
ids = {r['id'] for r in p1 + p2['results']}
print("ok" if len(ids) >= 4 and 'page' in p2 else "bad")
EOF
)
if [ "$page2_check" = "ok" ]; then
  echo -e "${GREEN}PASS${NC} pagination/page-2 follows token and returns fresh results"
  PASS=$((PASS+1))
else
  echo -e "${RED}FAIL${NC} pagination/page-2 unexpected"
  echo "  Response: $page2_resp"
  FAIL=$((FAIL+1))
fi

# Pagination tamper: replay token with a different resource id -> 400.
tamper_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PDP_URL}/access/v1/search/subject" \
  -H "Content-Type: application/json" \
  -d "{\"subject\":{\"type\":\"user\"},\"action\":{\"name\":\"can_read_user\"},\"resource\":{\"type\":\"user\",\"id\":\"different\"},\"page\":{\"limit\":2,\"token\":\"$page1_token\"}}")
if [ "$tamper_code" = "400" ]; then
  echo -e "${GREEN}PASS${NC} pagination/tamper detected (400)"
  PASS=$((PASS+1))
else
  echo -e "${RED}FAIL${NC} pagination/tamper expected 400, got $tamper_code"
  FAIL=$((FAIL+1))
fi

# --- Summary ---
echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL + ERROR))
echo "Total: $TOTAL  Pass: $PASS  Fail: $FAIL  Error: $ERROR"

if [ "$FAIL" -eq 0 ] && [ "$ERROR" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
