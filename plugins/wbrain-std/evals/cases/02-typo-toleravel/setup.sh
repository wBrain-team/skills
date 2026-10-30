work_branch vazio
sed -i "s/- O cliente vê só os próprios pedidos./- O cliente vê só os próprios pedidos.\n- Sem pedidos: o clinte vê \"Você ainda não fez pedidos\"./" snaps/pedidos/lista.md
git commit -qam "snap: lista vazia"
