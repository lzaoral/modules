.. _CONTRIBUTING:

Contributing
============

Thank you for considering contributing to Modules!

Support questions
-----------------

Please use the `modules-interest mailing list`_ for questions. Do not use the
issue tracker for this.

.. _modules-interest mailing list: https://sourceforge.net/projects/modules/lists/modules-interest

Asking for new features
-----------------------

Please submit your new feature wishes first to the `modules-interest mailing
list`_. Discussion will help to clarify your needs and sometimes the wanted
feature may already be available.

Reporting issues
----------------

* Describe what you expected to happen.
* If possible, include a `minimal, complete, and verifiable example`_ to help
  us identify the issue.
* Describe what actually happened. Run the ``module`` command in ``--debug``
  mode and include all the debug output obtained in your report.
* Provide the current configuration and state of your Modules installation by
  running the ``module config --dump-state`` command.
* Provide the name and content of the modulefiles you try to manipulate.

.. _minimal, complete, and verifiable example: https://stackoverflow.com/help/mcve

.. _submitting-patches:

Submitting patches
------------------

* Whether your patch is supposed to solve a bug or add a new feature, please
  include tests. In case of a bug, explain clearly under which circumstances
  it happens and make sure the test fails without your patch.
* If you are not yet familiar with the ``git`` command and `GitHub`_, please
  read the `don't be afraid to commit`_ tutorial.

.. _GitHub: https://github.com/
.. _don't be afraid to commit: https://dont-be-afraid-to-commit.readthedocs.io/en/latest/index.html

Start coding
~~~~~~~~~~~~

* Create a branch to identify the issue or feature you would like to work on
* Using your favorite editor, make your changes, `committing as you go`_.
* Comply to the `coding conventions of this project <coding-conventions_>`_.
* Your Tcl code has to be compatible with Tcl version 8.5 and above (see
  `Tcl 8.5 commands reference`_)
* Include tests that cover any code changes you make. Make sure the test fails
  without your patch.
* `Run the tests <running-the-tests_>`_ and `verify coverage <running-test-coverage_>`_.
* Push your commits to GitHub and `create a pull request`_.

.. _committing as you go: https://dont-be-afraid-to-commit.readthedocs.io/en/latest/git/commandlinegit.html#commit-your-changes
.. _create a pull request: https://help.github.com/articles/creating-a-pull-request/
.. _Tcl 8.5 commands reference: https://www.tcl.tk/man/tcl8.5/TclCmd/contents.htm

.. _running-the-tests:

Design notes
~~~~~~~~~~~~

See the :ref:`design` for recent feature specifications. You may also find
there some development howtos:

* :ref:`add-new-sub-command`
* :ref:`add-new-config-option`

Running the tests
~~~~~~~~~~~~~~~~~

Run the basic test suite with::

   make test

This only runs the tests for the current environment. `GitHub Actions`_ and
`Cirrus CI`_ will run the full suite when you submit your pull request.

.. _GitHub Actions: https://github.com/cea-hpc/modules/actions
.. _Cirrus CI: https://cirrus-ci.com/github/cea-hpc/modules

.. _running-test-coverage:

Running test coverage
~~~~~~~~~~~~~~~~~~~~~

Generating a report of lines that do not have test coverage can indicate where
to start contributing or what your tests should cover for the code changes you
submit.

Run ``make test COVERAGE=y`` which will automatically setup the `Nagelfar`_
Tcl code coverage tool in your ``modules`` development directory and
instrument the source Tcl scripts. Then the full testsuite will be run in
coverage mode and an annotated script will be produced for each Tcl script in
``tcl`` source directory (``tcl/*.tcl_m``)::

   make test COVERAGE=y
   # then open tcl/*.tcl_m files and look for ';# Not covered' lines

.. _Nagelfar: http://nagelfar.sourceforge.net/

Building the docs
~~~~~~~~~~~~~~~~~

Build the docs in the ``doc`` directory using Sphinx::

   cd doc
   make html

Open ``_build/html/index.html`` in your browser to view the docs.

Read more about `Sphinx`_.

.. _Sphinx: https://www.sphinx-doc.org

.. _coding-conventions:

Coding conventions
~~~~~~~~~~~~~~~~~~

* Maximum line length is 78 characters
* Use 3 spaces to indent code (do not use tab character)
* Adopt `Tcl minimal escaping style`_
* Procedure names: ``lowerCameCase``
* Variable names: ``nocaseatall``
* Curly brace and square bracket placement::

   if {![isStateDefined already_report]} {
      setState already_report 1
   }

* `No trailing space nor misspelling <commit-hooks_>`_

.. _Tcl minimal escaping style: https://wiki.tcl-lang.org/page/Tcl+Minimal+Escaping+Style

.. _commit-hooks:

Commit hooks
~~~~~~~~~~~~

A :command:`pre-commit` hook script is provided in the :file:`script`
directory of the project to help you check that the contribution made is free
of misspellings and trailing spaces. It requires the `codespell`_ utility that
checks for typos in any kind of files and the `Aspell`_ utility that spell
checks documentation files. The :command:`pre-commit` could be enabled in your
local repository with following command::

   ln -s ../../script/pre-commit .git/hooks/pre-commit

A :command:`commit-msg` hook script is also provided in the :file:`script`
directory of the project to help you check that your commit messages are free
of misspellings. It requires the `Aspell`_ utility and could be enabled in
your local repository with following command::

   ln -s ../../script/commit-msg .git/hooks/commit-msg

.. _codespell: https://github.com/codespell-project/codespell
.. _Aspell: http://aspell.net/

Emacs settings for coding conventions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is an example Emacs configuration that adheres to the first two
coding conventions.  You may wish to add this to your ``.emacs`` or
``.emacs.d/`` to modify your tcl-mode::

   (add-hook 'tcl-mode-hook
      (lambda ()
        (setq indent-tabs-mode nil)
        (setq tcl-indent-level 3)
        (setq tcl-continued-indent-level 3)
        (font-lock-add-keywords nil '(("^[^\n]\\{79\\}\\(.*\\)$" 1
                                       font-lock-warning-face prepend)))))

Submitting installation recipes
-------------------------------

* If you want to share your installation tips and tricks, efficient ways you
  have to write or organize your modulefiles or some extension you made to the
  ``module`` command please add a recipe to the cookbook section of the
  documentation.
* Create a directory under ``doc/example`` and put there the extension code
  or example modulefiles your recipe is about.
* Describe this recipe through a `reStructuredText`_ document in
  ``doc/source/cookbook``. It is suggested to have an *Implementation*,
  an *Installation* and an *Usage example* sections in that document to get
  as much as possible the same document layout across recipes.
* `Submit a patch <submitting-patches_>`_ with all the above content.

.. _reStructuredText: http://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html

