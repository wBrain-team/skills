work_branch frete
sed -i "s/R\$ 15,00/R\$ 20,00/" specs/pedidos/regras.md
sed -i "s/FRETE = 15.00/FRETE = 18.00/" app/pedidos.py
git commit -qam "spec e código na mesma branch"
