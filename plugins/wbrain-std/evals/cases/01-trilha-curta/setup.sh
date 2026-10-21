work_branch paginacao
sed -i "s/- O cliente vê só os próprios pedidos./- O cliente vê só os próprios pedidos.\n- Sobrescreve: a lista mostra 30 pedidos por página./" specs/pedidos/lista.md
git commit -qam "spec: 30 por página"
