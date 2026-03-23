#!/usr/bin/env bash
set -euo pipefail

# Call Paradigm API
RESPONSE=$(curl -sf -X POST "${PARADIGM_API_URL}/api/hook/blast-radius" \
  -H "Authorization: Bearer ${PARADIGM_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"project\": \"${PARADIGM_PROJECT}\", \"repo\": \"${REPO}\", \"pr_number\": ${PR_NUMBER}}" \
  2>&1) || {
    echo "::error::Failed to call Paradigm API: ${RESPONSE}"
    exit 1
  }

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
  gh pr comment "${PR_NUMBER}" --body "${COMMENT_BODY}"
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
