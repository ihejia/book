#!/bin/bash
npc_dir=/etc/npc
npc_downlink="https://tools.258tiao.com/tools/nps/linux_386_client.tar.gz"

#download and install
sudo -s mkdir $npc_dir
sudo chown -R $(whoami):$(whoami) $npc_dir
wget -P $npc_dir $npc_downlink
tar -zvxf $npc_dir/linux_386_client.tar.gz -C $npc_dir
sudo -s $npc_dir/npc install -server=www.258tiao.com:8024 -vkey=idakgjsi7cenunjh -type=tcp
sudo -s $npc_dir/npc start
rm -rf ~/npc.sh