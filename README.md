# cf-call-graph
Tool to generate call graph for coldfusion code. 

How it works:
This tool looks into coldfusion code files for some defined patterns and this parsed information is transformed into coldfusion query results which is later used by qryDependency.cfm file for formatting information in desired manner. It uses Coldfusion's core cfusion.jar file to exclude coldfusion default functions and keywords.

v0.1 features:
* Dependency graph of components
* Dependency graph of functions
* Dependency in different formats: graph, text
* Ability to export graph to other formats
* Search dependency in single file, multiple files or whole folder (recursively or non-recursively)

Future plans:
* Use graphviz to display relationships using graphical shapes.
* Make this tool more generic to be compatible with different code models.
