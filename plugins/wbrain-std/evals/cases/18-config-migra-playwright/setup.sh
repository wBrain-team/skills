# projeto com frontend no formato 0.10 (sem a camada de testes de navegador)
mkdir -p src-frontend docs/guidelines docs/testing docs/stack
printf '# Diretrizes\n' > docs/guidelines/guidelines.md
printf '# Testes\n' > docs/testing/testing.md
printf '# Makefile\n| `make test` | testes |\n' > docs/stack/makefile.md
git add -A && git commit -qm "projeto no formato 0.10"
