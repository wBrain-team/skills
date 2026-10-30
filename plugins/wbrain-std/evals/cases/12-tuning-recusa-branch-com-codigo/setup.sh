work_branch frete
sed -i "s/R\$ 15,00/R\$ 20,00/" snaps/pedidos/regras.md
sed -i "s/FRETE = 15.00/FRETE = 18.00/" app/pedidos.py
git commit -qam "snap e código na mesma branch"
