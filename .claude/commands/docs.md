Write or improve documentation: $ARGUMENTS

If no specific target given, analyze the project and identify documentation gaps.

## Process
1. Detect the project from $ARGUMENTS or current directory.
2. Read the project's CLAUDE.md if it exists.
3. Inventory existing docs: README.md, docs/, API references, inline comments.
4. Read the source code to understand actual behavior — never guess.
5. Based on the request:
   - **"README"** → write or rewrite the project README
   - **"API docs"** → document all endpoints/functions with examples
   - **"guide"** or **"tutorial"** → write a step-by-step walkthrough
   - **"changelog"** → generate from git history: `git log --oneline --since="last tag or first commit"`
   - **"audit"** or no specific target → list missing/outdated docs with recommendations
6. Write documentation that is accurate to the current code.
7. Show the user what was created or changed.
