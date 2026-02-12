#!/bin/bash
set -e

cd "$(dirname "$0")"

# Setup test repos
rm -rf upstream work
git init --bare upstream
git clone ./upstream ./work

# Create initial PRD
cat > work/prd.json << 'EOF'
{
  "title": "Hello World Test",
  "branchName": "lucy/hello-world",
  "stories": [
    {
      "id": "1",
      "title": "Create hello.txt",
      "description": "Create a file named hello.txt with the content 'Hello, World!'",
      "acceptanceCriteria": "File hello.txt exists with correct content",
      "passes": false
    }
  ]
}
EOF

cat > work/progress.txt << 'EOF'
# Lucy Progress Log
Started: Test run
---
EOF

export LUCY_IMAGE="fifty-first-contexts:latest"
export LUCY_PROMPT="$(dirname "$0")/../prompt.md"
export WORK_DIR="$(pwd)/work"
export GIT_AUTHOR_NAME="Lucy Whitmore"
export GIT_AUTHOR_EMAIL="lucy@whitmore.local"
export MAX_ITERATIONS=3

../lucy.sh
