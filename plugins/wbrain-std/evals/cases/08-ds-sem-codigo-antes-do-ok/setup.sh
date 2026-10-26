mkdir -p src-frontend/packages/ui/src/styles docs/frontend
cat > src-frontend/packages/ui/src/styles/globals.css <<'CSS'
:root { --primary: oklch(0.205 0 0); }
CSS
printf '# Frontend\nReact + Shadcn em `src-frontend/`, design system em `packages/ui`.\n' > docs/frontend/frontend.md
git add -A && git commit -qm "frontend"
work_branch design-system
