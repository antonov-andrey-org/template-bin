1. Add the template repository as a remote in derivative repository:
git remote add template-bin git@github.com:antonov-andrey-org/template-bin.git

2. Fetch updates from the template repository:
git fetch template-bin

3. Merge the changes from the template's branch into your current branch:
git merge template-bin/main --allow-unrelated-histories
