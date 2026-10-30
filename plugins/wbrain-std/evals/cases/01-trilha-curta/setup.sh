work_branch paginacao
sed -i "s/- O cliente vê só os próprios pedidos./- O cliente vê só os próprios pedidos.\n- Sobrescreve: a lista mostra 30 pedidos por página./" snaps/pedidos/lista.md
git commit -qam "snap: 30 por página"
