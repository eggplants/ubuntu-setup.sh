#!/bin/bash

sed -i '/Flow/,$d' README.md

cat << A >> README.md
## Flow

\`\`\`txt
$(
  grep -oP '(FIRST|FINAL): .*?(?=])|(?<=wait_enter).*?(?= &&)' ubuntu-setup.sh | tr -d \'
)
\`\`\`
A
