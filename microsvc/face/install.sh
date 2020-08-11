parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
pip3 install --no-cache-dir -r $parent_path/requirements.txt