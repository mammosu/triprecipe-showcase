# TripRecipe — public release gate

**Status: NOT APPROVED FOR PUBLIC VISIBILITY.** This is a review checklist, not an assertion that the repository is safe to publish. Keep the GitHub repository private until every required gate is completed.

## 1. Current-tree inventory (reviewed 2026-11-20)

The repository's `develop` tree was inspected through the GitHub connector.

- [x] No tracked `config/master.key`, plaintext `.env` file, production `.sqlite3` database, or obvious key file appeared in the **current file list**.
- [x] Encrypted Rails `config/credentials.yml.enc` is present; this is normally safe only if its decryption key has never been exposed.
- [x] `.gitignore` excludes environment files, Rails master keys, database storage, temporary files, and logs.
- [x] `.kamal/secrets` references a local key with command substitution rather than storing a plaintext key in the checked content.
- [x] Deployment settings refer to environment variables / GitHub secrets for confidential integrations.
- [ ] Full content of every tracked file has undergone a dedicated secret scanner (not done).
- [ ] **Complete Git history** (all branches and tags) has been checked for accidentally committed credentials, tokens, personal data, and removed files (not done).
- [ ] Investigate a **128-character token-like value** previously present in a commented Devise initializer line. It was removed from the current PR, but older commits may still contain it. Determine whether it was ever used as a real secret; rotate/revoke if it was.

**Critical:** A clean current tree does not imply clean Git history. Search the full repository history with an up-to-date scanner such as [Gitleaks](https://github.com/gitleaks/gitleaks), after cloning **all branches and tags**, and examine its findings. For a local audit, the scanner's current `git` mode and an all-history scope are appropriate. Check the syntax against the installed version.

```bash
git fetch --all --tags --prune
git log --all --name-only --format= | sort -u > /tmp/triprecipe-history-paths.txt
# Run an up-to-date Git-history secret scanner against all refs.
# Investigate every finding, including any credentials that were later deleted.
```

If a real credential was ever committed, **revoke/rotate it first**. Removing a file in the latest commit is insufficient. Plan history rewriting, force-push, and clone coordination separately, after backup and impact review. Do not publish until resolved.

## 2. Code quality / CI

- [x] The default branch is `develop`.
- [x] `.github/workflows/ci.yml` previously ran Rails' `test` / `test:system` tasks rather than the repository's RSpec suite; the accompanying draft PR changes this.
- [ ] CI (RSpec, system tests, lint, Brakeman, Bundler Audit, importmap audit) must be **green on the eventual merge commit**.
- [ ] **BLOCKER — resolve the gem security advisories tracked in [Issue #225](https://github.com/mammosu/triprecipe/issues/225)**. The 2026-11-20 Bundler Audit run found a Critical Active Storage advisory on Rails 8.1.3.1 (fixed version >= 8.1.4.1) and multiple additional findings. Verify the running production dependencies separately; do not suppress high/critical warnings without a reviewed reason.
- [ ] Validate deployment separately. Making a repository public must **not** deploy or alter production automatically.
- [ ] Review admin authorization, link-token access, file-upload restrictions, and PII in audit/event logs.

## 3. Copyright, branding, and privacy

- [ ] Identify the origin/usage rights of `app/assets/images/hero_bg.jpg`, logos, icons, fonts, and any sample travel photos.
- [ ] Ensure third-party code and templates are credited, and license obligations are satisfied.
- [ ] Inspect documentation, fixtures, tests, development seed data, Git history, Issues, and attachments for real people's names, emails, passwords, private URLs, or customer/client material.
- [ ] Confirm that seed accounts use fictitious details and are created **only in development/test**, never in production.
- [ ] Check that no private operational details (access instructions, live infrastructure identifiers, account-specific configuration) need moving into private documentation.
- [ ] Decide whether to add `LICENSE` (MIT, Apache-2.0, another license, or no open-source license). **Do not select a license automatically.**

## 4. Portfolio quality

- [x] README describes the product and its business-relevant engineering capabilities in English, with short Japanese and Spanish descriptions.
- [ ] Add authentic desktop/mobile screenshots with personal data removed; do not use stock or unrelated screenshots.
- [ ] Verify live-site availability and all links.
- [ ] Confirm listed features against production and note any incomplete features.
- [ ] Document one or two concrete engineering decisions, trade-offs, and tests in a short case study (without disclosing confidential information).
- [ ] Add a vulnerability disclosure route if the repository will accept external reports.

## 5. Publication approval

- [ ] Git history secret scan reviewed and findings resolved.
- [ ] All rights/third-party asset questions resolved.
- [ ] Tests/security scans confirmed green.
- [ ] README, screenshots, documentation, attribution, and license choice approved by the owner.
- [ ] Explicit final approval to change GitHub visibility from Private to Public.

Changing visibility must be a **separate, intentional action** after approval. No checklist, PR, or CI change should automatically make this repository public.
