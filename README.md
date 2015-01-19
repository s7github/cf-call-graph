# cf-call-graph
Tool to generate call graph for coldfusion code. 

How it works:
This tool looks into coldfusion code files for some defined search patterns and matching code information (in coldfusion query format) is used by qryDependency.cfm file. It generates dependency information in graph/text format and sends back to html tool (drawDependency.html). This tool was developed to find dependencies in a particular project so it's not generic yet. I have plans to make this code more generic, clean and feature rich.

Requirements:
* Coldfusion component path and function name whose dependency is to be found.
* Coldfusion's core cfusion.jar file to exclude coldfusion default functions and keywords from displayed results.

v0.1 features:
* Search dependency in single file, multiple files or whole folder (recursively or non-recursively).
* Displays dependency information of sub-function and stored procedures used within specified function.
* Display dependency information in text format.
* Can link this dependency information to javadoc (generated separately by colddoc).

Future releases:
* Store CSS & JS in separate folder/files.
* Use graphviz to display relationships using graphical shapes.
* Make this tool more generic to be compatible with different code models. 
* Dependency graph of components
* Dependency graph of functions
* Dependency in different formats: graph, text
* Ability to export graph to other formats
