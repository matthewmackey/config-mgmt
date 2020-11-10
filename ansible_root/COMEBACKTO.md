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

