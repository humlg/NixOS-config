{ pkgs, ... }:
{
  home.packages = with pkgs; [ gocryptfs zenity xfce.thunar ];

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <name>Mount Vault</name>
        <command>sh -c 'gocryptfs -extpass "zenity --password --title=Vault" /mnt/data1/.vault ~/Vault &amp;&amp; thunar ~/Vault'</command>
        <description>Unlock encrypted vault</description>
        <icon>folder-locked</icon>
        <unique-id>vault-mount</unique-id>
        <patterns>*</patterns>
        <directories/>
      </action>
      <action>
        <name>Unmount Vault</name>
        <command>fusermount -u ~/Vault</command>
        <description>Lock encrypted vault</description>
        <icon>folder</icon>
        <unique-id>vault-umount</unique-id>
        <patterns>*</patterns>
        <directories/>
      </action>
    </actions>
'';
}
