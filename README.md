# py-ccflex
This project is an implementation of machine learning for classyfing lines of code. It can be used to count lines of code given by an example, find violations of coding guidelines or mimic other metrics (e.g. McCabe complexity). 

The whole idea is build around the pipes-and-filters architecture model, where we use a number of components that process data and can be exchanged. The _bin_ folder contains these scripts. 

Since this project is modular, we can use R to make some more advanced classifications, which are not available in Python. 

* bin - components, each component is a script

* basic-manual-feature - extracting features like number of brackets, for, etc.
* create-storage - creates a folder where each component can store sub-results
* extract-linces2csv - extracts all kinds of information from the file


The idea is described in the following paper:
* Ochodek, M., Staron, M., Bargowski, D., Meding, W., & Hebig, R. (2017, February). Using machine learning to design a flexible LOC counter. In Machine Learning Techniques for Software Quality Evaluation (MaLTeSQuE), IEEE Workshop on (pp. 14-20). IEEE.

* available at: [IEEE Xplore](http://ieeexplore.ieee.org/abstract/document/7882011/)
