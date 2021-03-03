* Separate out the roles into more finer-grained roles
  * as part of this, separate out the desktop-related code from the server-related
    code; for example, in the common/tasks/packages.yml file, there are tasks to
    install packages we would want on a server as well as tasks to install a Chrome
    browser; these should be separated so that we can install just server tools
    w/o stuff we would want on a server with a desktop graphical environment
* Separate out desktop-related and server-related items into se
* Make a task to setup the ~/.local/ansible_bash directory for storing ansible-created
  Bash files that can be created by any roles; this task would also include
  writing any other code like:
    - setting up common variables that other roles would need
      - also cleaning up the current related variables spread all over the current
        existing roles
    - possibly creating re-usable tasks to allow them to easily add alias files
      that already have the "DO NOT EDIT - created by ansible on XX/XX/XXXX"
      header
* fix roles/mmackey/tasks/ansible_setup.yml so that the public key has the proper
  restricted permissions after creation; it seems I had to manually fix the perms
  on the public key generated so that I don't get this message:

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0620 for '/home/mmackey/.ssh/ansible.pub' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "/home/mmackey/.ssh/ansible.pub": bad permissions

* Run PluginInstall via command-line for Vim plugins (this may be better in
  dotfiles/install.sh than ansible though)
  * SEE: https://github.com/VundleVim/Vundle.vim for 'vim +PluginInstall +qall' info

* figure out way to better templatize dnsmasq variables for domain and wildcard
  domain settings. Currently I don't like the values set in defaults/main.yml,
  however, setting the values to blank values there causes a dnsmasq.conf config
  file error on service startup.  Need to figure out a way to comment out the "domain"
  and "address" variables in dnsmasq.conf if no value is supplied for them.

* Restart docker daemon when resolv.conf is changed on a host
* Extract dns_client tasks and dns_server tasks so dnsmasq is NOT installed on
  the clients (ie - lenovo)
