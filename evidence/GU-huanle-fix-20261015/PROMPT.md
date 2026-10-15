Fix exactly 2 generals in this repo so their skills match the original text literally: hlxg_simayi and hlxg_jiangwei3.
Verify-report differences (from /workspace/evidence/GU-verify-20261015/qs-antigravity-REPORT.md):
- hlxg_simayi (完杀、忍戒、放逐、极略、连破、集智、鬼才): currently 完杀/放逐/集智/鬼才 are given as initial skills and trigger without discarding 忍; 极略 becomes a second trigger. Original: those skills are obtained/used only by discarding 忍 via 极略.
- hlxg_jiangwei3 (困奋、燃己、诈降、逐日): currently 困奋 and 诈降 are granted at start. Original: obtained only after limited skill 燃己 conditions are met.
Steps: grep the repo (and /workspace/evidence, materials md) for the original skill text of these 2 generals; read only the relevant excerpts. Use a Sonnet subagent for the search/read chores. Edit only these 2 generals' code in offline.lua / offline-ai.lua (and translations if needed). Do NOT touch any .staging dirs or other generals. Check Lua syntax with luac -p if available.
Write evidence/GU-huanle-fix-20261015/REPORT.md (original text, what changed, what is unverified). If something truly cannot match literally, say so in REPORT.
Make ONE commit with: git -c user.name=lolosijyu -c user.email=a31602603@yahoo.com.hk commit --author="lolosijyu <a31602603@yahoo.com.hk>". Do not push.
Last line printed: RESULT <hash> <short summary>
