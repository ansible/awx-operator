# Building the Ansible AWX Operator Docs

To build the AWX Operator docs locally:

1. Clone the AWX operator repository. 
2. From the root directory:
    a.  pip install --user -r docs/requirements.txt
    b.  mkdocs build

This will create a new directory called `site/` in the root of your clone containing the index.html and static files. To view the docs in your browser, navigate there in your file explorer and double-click on the `index.html` file. This should open the docs site in your browser.