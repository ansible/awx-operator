# Building the Ansible AWX Operator Docs

To build the AWX Operator docs locally:

1. Clone the AWX operator repository.
1. Preferrably, create a virtual environment for installing the dependencies.  
   a. `python3 -m venv venv`  
   b. `source venv/bin/activate`
1. From the root directory:  
   a. `pip install -r docs/requirements.txt`  
   b. `mkdocs build`
1. View the docs in your browser:  
   a. `mkdocs serve`  
   b. Open your browser and navigate to `http://127.0.0.1:8000/`

This will create a new directory called `site/` in the root of your clone containing the index.html and static files.
