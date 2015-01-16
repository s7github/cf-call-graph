/**
* This component has functions to get dependency of a component / function
* @author Saurabh Sharma
*/
component accessors="true" output="false" {
  // Properties ////////////////////
  property
    name="webRootPath"
    hint="Path of web root folder"
    type="string";
  /**
  * Comma separated search type names to be performed in code for final result.
  * Allowed search types:
  *   NONE              - Do not search anything
  *   ALL               - Search all available search types
  *   ASSIGN_TAG        - Search components / functions assigned to variables for container function call within cfset tag
  *   ASSIGN_SCRIPT     - Search components / functions assigned to variables for container function call within cfscript
  *   INVOKE            - Search cfinvoke components / functions
  *   OTHER_FUNC_CALLS  - Search components / functions invoked using parentheses. Example a.b.c()
  *   SP_CALLS          - Search stored procedure calls
  */
  property
    name="searchFor"
    type="string";
  // List of text / components / function to include / exclude for search
  /**
  * In list, provide component names as relative path
  * e.g. root > folder > file.cfc should be written as "folder.file"
  * No need to use component extention ".cfc"
  * If all components under a folder have to be used then use dot notation after folder path
  * * To include / exclude components under all subfolder use double dot notation eg. "folder.."
  * * To include / exclude components immediately under specified folder just use single dot notation eg. "folder."
  */
  property
    name="mainCompList"
    hint="Relative path of components to include in search"
    type="array";
  property
    name="mainFuncList"
    hint="Name of function to include in search"
    type="array";
