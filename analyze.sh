#!/usr/bin/env bash
set -euo pipefail

# Call Paradigm API
HTTP_CODE=$(curl -s -o /tmp/paradigm_response.json -w "%{http_code}" \
  -X POST "${PARADIGM_API_URL}/api/hook/blast-radius" \
  -H "Authorization: Bearer ${PARADIGM_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "ngrok-skip-browser-warning: true" \
  -d "{\"project\": \"${PARADIGM_PROJECT}\", \"repo\": \"${REPO}\", \"pr_number\": ${PR_NUMBER}}")

RESPONSE=$(cat /tmp/paradigm_response.json)

if [ "$HTTP_CODE" != "200" ]; then
  DETAIL=$(echo "$RESPONSE" | jq -r '.detail // empty' 2>/dev/null || true)
  echo "::error::Paradigm API returned HTTP ${HTTP_CODE}: ${DETAIL:-$RESPONSE}"
  exit 1
fi

# Parse response
VERDICT=$(echo "$RESPONSE" | jq -r '.verdict')
MARKDOWN=$(echo "$RESPONSE" | jq -r '.markdown')
AFFECTED=$(echo "$RESPONSE" | jq -r '.affected')
CHANGED=$(echo "$RESPONSE" | jq -r '.changed')

# Set outputs
echo "verdict=${VERDICT}" >> "$GITHUB_OUTPUT"
echo "affected=${AFFECTED}" >> "$GITHUB_OUTPUT"

# Post PR comment (sticky — updates existing comment)
COMMENT_MARKER="<!-- paradigm-blast-radius -->"
COMMENT_BODY="${COMMENT_MARKER}
${MARKDOWN}"

# Find existing comment
EXISTING=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
  --jq ".[] | select(.body | contains(\"${COMMENT_MARKER}\")) | .id" \
  2>/dev/null | head -1)

if [ -n "$EXISTING" ]; then
  # Update existing comment
  gh api "repos/${REPO}/issues/comments/${EXISTING}" \
    -X PATCH \
    -f body="${COMMENT_BODY}" > /dev/null
  echo "Updated existing blast radius comment"
else
  # Create new comment
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" -f body="${COMMENT_BODY}" > /dev/null
  echo "Posted new blast radius comment"
fi

# Log summary
echo "## Blast Radius: ${VERDICT}" >> "$GITHUB_STEP_SUMMARY"
echo "Changed: ${CHANGED}, Affected: ${AFFECTED}" >> "$GITHUB_STEP_SUMMARY"

# Exit based on verdict
if [ "$VERDICT" = "FAIL" ]; then
  echo "::error::Blast radius analysis found critical issues (MUST FIX items)"
  exit 1
fi

echo "Blast radius analysis complete: ${VERDICT}"
