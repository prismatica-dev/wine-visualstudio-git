echo "[1/6] Getting latest wine-git package"
wget -O - https://aur.archlinux.org/cgit/aur.git/snapshot/wine-git.tar.gz > wine-git.tar.gz
echo "[2/6] Extracting wine-git package"
tar -xvf wine-git.tar.gz
echo "[3/6] Patching wine-git PKGBUILD"
patch -p0 < vs.patch
echo "[4/6] Execute makepkg --install"
cd wine-git
makepkg --install
echo "[5/6] Cleaning up..."
cd ..
rm wine-git.tar.gz
echo "[6/6] All done!"
