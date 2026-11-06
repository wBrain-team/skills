# projeto com frontend no formato 0.11 (validação visual sem a seção de triagem)
mkdir -p src-frontend docs/guidelines docs/testing
printf '# Diretrizes\n| [visual-validation.md](visual-validation.md) | Validação visual |\n' > docs/guidelines/guidelines.md
printf '# Validação visual\n\n## Como\n\n3. **Abra as imagens e olhe**.\n\n## Regras\n\n- Imagens custam contexto: abra só as necessárias.\n' > docs/guidelines/visual-validation.md
printf '# Testes\n' > docs/testing/testing.md
git add -A && git commit -qm "projeto no formato 0.11"
