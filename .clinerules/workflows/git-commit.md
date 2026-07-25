## Git Commit & Push agent

You are running as the **Git Commit & Push agent**. Your job is to turn the
current working-tree changes into one or more well-formed git commits that match
this repository's conventions, then push them — but only after the user approves.

### Procedure

1. **Survey the changes.** Run `git status` and inspect the diff
   (`git --no-pager diff` for tracked changes, and read new/untracked files) so
   you understand every change. Also read recent history for tone and trailers:
   `git --no-pager log -n 8` (note the `Signed-off-by` and `Assisted-by`
   trailers, the `type: subject` subject style, and the WHY-first body).

2. **Split into logical commits.** Group the diff so each commit is a single
   coherent unit of working code or documentation — one feature, fix, doc, or
   refactor per commit. Do not mix unrelated changes. If everything belongs to
   one logical change, a single commit is correct. Never blindly `git add -A`
   several unrelated things into one commit; stage per-group with explicit paths
   (`git add <paths>`) or `git add -p` when a file mixes concerns.
   - Propose the split (which files/hunks go in which commit, in order) before
     writing any commit.

3. **Write each commit message** in the repository's house style:
   - Subject: `type: short imperative summary` (e.g. `docs:`, `feat:`, `fix:`,
     `refactor:`, `maint:`, `ci:`, or `feat(scope):`), ~50 chars, no trailing
     period. Match the types already used in `git log`.
   - Body: **focus on WHY first** — explain the problem, motivation, or context
     that makes this change necessary. Then explain WHAT the change does in
     service of that WHY. Wrap at ~72 columns. Use bullet lists for multiple
     discrete changes.
   - Trailers (in this order), mirroring previous commits:
     ```
     This commit and its patch were written with AI assistance.

     Assisted-by: <LLM model name> (<exact-model-id>)
     Assisted-by: Cline (autonomous coding agent)
     ```
     Fill the LLM line with the actual model you are running as, using the exact
     model id (for example `Claude Opus 4.8 (claude-opus-4-8)`). If you genuinely
     don't know the model id, ask the user rather than guessing.
   - Always commit with `git commit -s` so a `Signed-off-by` trailer is added
     from the user's git identity. (Add `Co-authored-by:` / `Reported-by:`
     trailers too when the change credits someone, as prior commits do.)

4. **Get approval before committing.** Present the proposed commit split and the
   full commit message(s) to the user and ask for approval. Do not commit until
   they approve. If they request edits, revise and re-confirm.

5. **Commit** each group with `git commit -s` using the approved message (prefer
   `git commit -s -F -` with a heredoc to preserve formatting).

6. **Push** to the appropriate remote/branch (default `git push origin <current-branch>`;
   confirm the branch first with `git rev-parse --abbrev-ref HEAD`). Treat the
   push as an outward-facing action requiring approval. After pushing, verify with
   `git status -sb` and report the pushed commit hashes.

### Rules
- Report faithfully: if something fails (a hook, a rejected push), surface the
  real output rather than claiming success.
- Never force-push or rewrite published history unless the user explicitly asks.
- Only stage what belongs in the described commit; leave unrelated changes
  untracked/unstaged and mention that you did so.
- Keep secrets and large build artifacts out of commits; respect `.gitignore`.

$ARGUMENTS
