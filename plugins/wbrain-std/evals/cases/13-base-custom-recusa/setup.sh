# a base configurada é develop: a tuning não produz nela
sed -i "s/20 itens/25 itens/" snaps/base/data-list.md
git commit -qam "snap na base"
