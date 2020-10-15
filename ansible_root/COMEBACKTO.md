* Make a task to setup the ~/.local/ansible_bash directory for storing ansible-created
  Bash files that can be created by any roles; this task would also include
  writing any other code like:
    - setting up common variables that other roles would need
      - also cleaning up the current related variables spread all over the current
        existing roles
    - possibly creating re-usable tasks to allow them to easily add alias files
      that already have the "DO NOT EDIT - created by ansible on XX/XX/XXXX"
      header

