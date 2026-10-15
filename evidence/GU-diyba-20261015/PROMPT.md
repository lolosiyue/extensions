You are porting generals from /workspace/finaldebug-md-ascii/diyba.md (605 lines, READ ONLY BY LINE RANGE) into this repo (/workspace/ext-gu-jilue, branch qs-claude/gu-diyba-20261015).
Rules: follow /workspace/qsanguosha-task-briefs/templates/gu-staging/INSTRUCTIONS.md and /workspace/qsanguosha-task-briefs/playbooks/token-opt-20261014.md. SkillV2 only, literal skill text, skip mini-game/小程序(xcx)/新服(xinfu)/no-text entries.
Writable ONLY: .staging/<id>/*, extensions/offline.lua, ai/offline-ai.lua, evidence/GU-diyba-20261015/*.
Steps:
1. First check already-done parts: `git -C /workspace/extensions-src stash show -p stash@{0}` (PAUSE GU-diyba-cont drafts) and grep extensions/offline.lua for generals already present; skip them.
2. Split diyba.md into micro-batches (~3-5 generals each) with a script; write evidence/GU-diyba-20261015/batches.json.
3. For EACH batch use the Task tool with a Haiku or Sonnet subagent (never do batches yourself), giving it only that line range excerpt; at most 3 subagents in parallel. Each writes .staging/<id>/{skills.lua,ai.lua,report.md}.
4. Assemble into extensions/offline.lua and ai/offline-ai.lua (use assemble.py template), lua syntax-check (luac -p if available).
5. ONE git commit, author "lolosijyu <a31602603@yahoo.com.hk>". Do NOT push. Do not stage .staging.
6. Write evidence/GU-diyba-20261015/REPORT.md: done count, skipped list with reason, commit hash. Final stdout line: RESULT <hash> <done>/<total>.
