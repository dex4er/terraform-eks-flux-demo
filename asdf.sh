test -f .asdf/asdf.sh || git clone https://github.com/asdf-vm/asdf.git .asdf --branch v0.11.2
. .asdf/asdf.sh
while read plugin version; do
  asdf plugin add $plugin || test $? = 2
done < .tool-versions
asdf install
