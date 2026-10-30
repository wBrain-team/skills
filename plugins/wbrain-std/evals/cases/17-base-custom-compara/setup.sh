# main diverge da base (tem código extra); contra a develop o diff da branch é só de snaps/
git branch main
git checkout -q main
echo "EXTRA = 1" >> app/pedidos.py
git commit -qam "código só na main"
git checkout -q develop
work_branch paginacao
sed -i "s/- O cliente vê só os próprios pedidos./- O cliente vê só os próprios pedidos.\n- Sobrescreve: a lista mostra 30 pedidos por página./" snaps/pedidos/lista.md
git commit -qam "snap: 30 por página"
