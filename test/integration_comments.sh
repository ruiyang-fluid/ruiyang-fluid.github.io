#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
tmp_override="${tmp_dir}/comments-test-override.yml"
tmp_site="${tmp_dir}/site"
created_posts=()

cleanup() {
  if ((${#created_posts[@]})); then
    rm -f "${created_posts[@]}"
    rmdir _posts 2>/dev/null || true
  fi
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

cat >"${tmp_override}" <<'YAML'
disqus_shortname: al-folio
giscus:
  repo: alshedivat/al-folio
  repo_id: R_kgDOExample
  category: Comments
  category_id: DIC_kwDOExample
YAML

mkdir -p _posts

giscus_fixture="_posts/2022-12-10-giscus-comments.md"
if [[ ! -f "${giscus_fixture}" ]]; then
  cat >"${giscus_fixture}" <<'MD'
---
layout: post
title: a post with giscus comments
date: 2022-12-10 11:59:00-0400
description: minimal fixture for the comments integration test
tags: comments
categories: sample-posts external-services
giscus_comments: true
related_posts: false
---

This hidden fixture keeps the comments integration test covered.
MD
  created_posts+=("${giscus_fixture}")
fi

disqus_fixture="_posts/2015-10-20-disqus-comments.md"
if [[ ! -f "${disqus_fixture}" ]]; then
  cat >"${disqus_fixture}" <<'MD'
---
layout: post
title: a post with disqus comments
date: 2015-10-20 11:59:00-0400
description: minimal fixture for the comments integration test
tags: comments
categories: sample-posts external-services
disqus_comments: true
related_posts: false
---

This hidden fixture keeps the comments integration test covered.
MD
  created_posts+=("${disqus_fixture}")
fi

bundle exec jekyll build --config "_config.yml,${tmp_override}" -d "${tmp_site}" >/dev/null

giscus_page="${tmp_site}/blog/2022/giscus-comments/index.html"
disqus_page="${tmp_site}/blog/2015/disqus-comments/index.html"

grep -q 'https://giscus.app/client.js' "${giscus_page}"
if grep -q 'giscus comments misconfigured' "${giscus_page}"; then
  echo "unexpected giscus misconfiguration warning in ${giscus_page}" >&2
  exit 1
fi

grep -q 'id="disqus_thread"' "${disqus_page}"
grep -q '.disqus.com/embed.js' "${disqus_page}"

echo "comments integration checks passed"
