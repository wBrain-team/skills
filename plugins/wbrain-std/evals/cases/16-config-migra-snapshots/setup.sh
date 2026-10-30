# projeto no formato antigo (0.7): pasta snapshots/, marcador # snapshot:, referências no conteúdo
git mv snaps snapshots
git mv snapshots/snaps.md snapshots/snapshots.md
sed -i 's/# snap:/# snapshot:/' tests/test_pedidos.py
sed -i 's/snaps\//snapshots\//g; s/`snaps`/`snapshots`/g' AGENTS.md docs/docs.md snapshots/snapshots.md
sed -i 's/# snap:/# snapshot:/; s/^# Snaps/# Snapshots/' docs/docs.md snapshots/snapshots.md
sed -i 's/\.\.\/base/..\/base/' snapshots/pedidos/*.md
git add -A && git commit -qm "projeto no formato 0.7 (snapshots)"
