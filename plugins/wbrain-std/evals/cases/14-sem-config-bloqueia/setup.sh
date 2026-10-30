work_branch paginacao
sed -i "s/20 itens/25 itens/" snaps/base/data-list.md
git commit -qam "snap: 25 por página"
