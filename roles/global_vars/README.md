Role: `global_vars`
===================

This role can be used to share variables between roles.  The variables defined
here are different from `group_vars/all` because we need to share variables that
don't make sense to put in `group_vars` b/c they would be the same for any
Ansible inventory setup.


How to Use (Best Option): `dependencies`
----------------------------------------

The best way to use this role is to just include it as a role's dependencies.
This way the variables will be included for all tasks in all of that role's
task files no matter what tags are specified during an Ansible run.

It is better than the method in the section below on `import_role` vs.
`include_role` because it will:

  1. Allow the variables to be loaded for all task files in a role, which is
     needed for roles that have multiple task files that sometimes get
     independently run from other roles or plays.
  2. Keep the `main.yml` task file cleaner by not needing the `import_role` task

You can use this method via:

```
dependencies:
  - name: global_vars
```


How to Use: `import_role` vs. `include_role` (DEPRECATED)
---------------------------------------------------------

We should use `import_role` to include these vars in other roles vs.
`include_role` becuase an import will always cause the variables from
the role to be loaded no matter what tags are being used in the Ansible run.

If you conversely use `include_role` then you need to add an `apply:tags` dictionary
to the `include_role` task for every applicable tag you want the variables loaded for.
This is a pain when you have many tasks with many different tags that need these variables.

I think the best practice is to just make an `import_role` task at the very
beginning of `tasks/main.yml` for any roles that need access to the global vars
anywhere within that role.

You can do this via:

```
- name: <ROLE_NAME> | source global_vars to get X-related vars
  import_role:
    name: global_vars
```
