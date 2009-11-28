
if ($Jsh.IsTestMachine ) {
    return;
}

echo "Loading Favorites"
. script "favorites"
Load-Favorites
