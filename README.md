# Generate strings using printf like construct

# Todo

# Done
* Wait for a bugfix of perl6 to generate proper ranges involving characters. Must do this using .succ() to get the next in range.

# Changelog

* 0.2.4
  * Symplification in retrieving the command name from the plugin.
* 0.2.3
  * Changes forced by perl6 changes
  * Dropped File::HomeDir in favor of $*HOME
* 0.2.2
  * Config file change in tests modifications
* 0.2.1
  * Change of options and addition of program control like workdir
* 0.2.0
  * Change of options module. Now uses TOML.
* 0.1.2
  * Bugfixes
*.0.1.0
  * Added $.ignore-errors attribute to Genpath class. Attribute is writable
  * Added option -ie to program to ignore errors.
* 0.0.4
  * Bugfix generating commandline. empty spaces must be filtered out
* 0.0.3
  * Add author field
  * Small bugfix in here-doc
* 0.0.2
  * Bugfix handling negative numbers. Used regexes to remedy this.
* 0.0.1
  * Rewrite of original genpath program written in perl 5
