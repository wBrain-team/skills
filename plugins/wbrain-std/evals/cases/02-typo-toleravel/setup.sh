work_branch vazio
sed -i "s/- O cliente vê só os próprios pedidos./- O cliente vê só os próprios pedidos.\n- Sem pedidos: o clinte vê \"Você ainda não fez pedidos\"./" snapshots/pedidos/lista.md
git commit -qam "snapshot: lista vazia"
