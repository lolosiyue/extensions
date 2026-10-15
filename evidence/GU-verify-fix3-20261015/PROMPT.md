Fix the real FAIL items from the verify report on the current branch (do not switch branches): 極略 (jilue) 12 items and 怒焰 (nuyan) 7 items. List: /workspace/qsanguosha-task-briefs/evidence/GU-verify-20261015/qs-command-code-REPORT.md (read only the FAIL rows / fix lists via a Haiku subagent first, produce a small JSON list).
Rules:
- Fix only to match the original skill text literally. Original text: grep the repo / /workspace materials md for each general (subagents read excerpts only).
- Do NOT touch the 13 generals whose original text is only a Bilibili summary (marked in the report).
- Edit only extensions/offline.lua, extensions/nuyan.lua and their AI files for these generals. Do not touch /workspace/Qsanguosha-sijyu or .staging dirs.
- Split work into batches; use Haiku/Sonnet subagents via Task, max 3 parallel. Subagents return patched code blocks; you apply them.
- If an item cannot be matched literally, leave the code and list it as skipped with a reason.
Write evidence/GU-verify-fix3-20261015/REPORT.md (each item: fixed/skipped + reason). ONE commit including PROMPT.md and REPORT.md (not run.log), with --author="lolosijyu <a31602603@yahoo.com.hk>" and -c user.name=lolosijyu -c user.email=a31602603@yahoo.com.hk. No push.
Last line printed: RESULT <hash> fixed=<n> skipped=<m>
