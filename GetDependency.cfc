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
  property
    name="webAppName"
    hint="Mapping name assigned to root folder of website"
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
  property
    name="excludeCompList"
    hint="Relative path of components to exclude from final search result"
    type="array";
  property
    name="excludeFunctions"
    hint="Name of functions to exclude from final search result"
    type="array";
  property
    name="excludeMatching"
    hint="List of regular expressions to exclude in initial search results (matching regular expressions)"
    type="array";
  /**
  * Display settings for results display
  * showSearchResults     - Should search results be shows? (true/false). Default = false
  * showNARecords         - Should records with NA be shown in search results? (true/false). Default = false
  * showNonNARecords      - Should records other than NA be shown in search results? (true/false). Default = false
  * showUniqueRecords     - Should unique records be shown in final results? (true/false). Default = false
  */
  property
    name="displaySettings"
    type="struct"
    setter="false";
  /**
  * Debugging settings for Dependency Checker
  * allowedDump   - Whether dump for debugging information is allowed or not. Default = false
  * dumpCallsFrom - Starting number of allowed dump calls range. Default = 0
  * dumpCallsTo   - Last number of allowed dump calls range. Specify -1 for no end. Defualt = -1
  */
  property
    name="debugSettings"
    type="struct"
    setter="false";
  // Container for results
  
  /** 
  * Output records type - SP and / or function dependency details
  */
  variables.ORECORD = {
                          NONE              = "NONE"
                      ,   ALL               = "ALL"
                      ,   ASSING_TAG        = "ASSIGN_TAG"
                      ,   ASSIGN_SCRIPT     = "ASSIGN_SCRIPT"
                      ,   INVOKE            = "INVOKE"
                      ,   OTHER_FUNC_CALLS  = "OTHER_FUNC_CALLS"
                      ,   SP_CALLS          = "SP_CALLS"
                      ,   NEW_INSTANCE      = "NEW_INSTANCE"
                      ,   CREATE_OBJ        = "CREATE_OBJ"
                      };
  /**
  * Items with search patterns to search in files
  */
  variables.searchList = [
                              {searchType = variables.ORECORD.ASSIGN_TAG, searchPattern = "[<]cfset.+?\.(component|method|function)="".*?""\s?/?>"}
                          ,   {searchType = variables.ORECORD.ASSING_SCRIPT, searchPattern = "(component|method|function)="".*?"";"}
                          ,   {searchType = variables.ORECORD.INVOKE, searchPattern = "[<]cfinvoke\s.+?>"}
                          ,   {searchType = variables.ORECORD.OTHER_FUNC_CALLS, searchPattern = "(?=[^a-zA-Z0-9])?(#webAppName#\.|application\.|[_a-zA-Z0-9]+)[._a-zA-Z0-9]+?\("}
                          ,   {searchType = variables.ORECORD.SP_CALLS, searchPattern = "[<]cfstoredproc.+?procedure="".*?"""}
                          ,   {searchType = variables.ORECORD.NEW_INSTANCE, searchPattern = "[a-zA-Z][.a-zA-Z0-9]*?=new\s(#webAppName#\.|application\.|[_a-zA-Z0-9]+)[._a-zA-Z0-9]+?\("}
                          ,   {searchType = variables.ORECORD.CREATE_OBJ, searchPattern = "createObject\s?\(.*?,""(#webAppName#\.|application\.|[_a-zA-Z0-9]+)[._a-zA-Z0-9]+?"""}
                          ];
  /**
  * Counter to keep track of currently being executed dump call
  * dumpCallCurrent   - Current dump call number. Default = 0
  */
  variables.dumpCallCurrent = 0;
  
  // Initialize containers for results
  // Container to store CF functions list
  this.cfFunctions = arrayNew(1);
  // Container to store found results for matching search patterns in code
  this.searchResults = queryNew("SNo,Search_Type,Folder,Component,Function,Search_Pattern,Matching_Text,Group_ID,Error",
                                "integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,varchar");
  this.funcFinalResults = queryNew("Folder,Component,Function,Sub_Component_Path,Sub_Component,Sub_Function,Error",
                                    "varchar,varchar,varchar,varchar,varchar,varchar,varchar");
  this.spFinalResults = queryNew("Folder,Component,Function,DB_Package,DB_Stored_Procedure,Error",
                                  "varchar,varchar,varchar,varchar,varchar,varchar");
  
  // Function definitions ////////////////////////////
  
  /**
  * Constructor to initialize component instance
  */
  function init() {
    webRootPath = "C:\cfusion\my_app";
    webAppName = "myapp";
    showSearchResults = false;
    showNARecords = false;
    showNonNARecords = true;
    showUniqueRecords = false;
    searchFor = "NONE"
                & "," & variables.ORECORD.ASSIGN_TAG
                & "," & variables.ORECORD.ASSIGN_SCRIPT
                & "," & variables.ORECORD.INVOKE
                & "," & variables.ORECORD.OTHER_FUNC_CALLS
                & "," & variables.ORECORD.SP_CALLS
                & "," & variables.ORECORD.NEW_INSTANCE
                & "," & variables.ORECORD.CREATE_OBJ
                ;
    mainCompList = arrayNew(1);
    mainFuncList = arrayNew(1);
    excludeMatching = arrayNew(1);
    excludeCompList = arrayNew(1);
    excludeFunctions = arrayNew(1);
    displaySettings = {
                          showSearchResults = false
                      ,   showNARecords     = false
                      ,   showNonNARecords  = false
                      ,   showUniqueRecords = false
                      };
    debugSettings = {
                        allowedDump = false
                    ,   dumpCallsFrom = 0
                    ,   dumpCallsTo = -1
                    };
    // Initialize CF functions list
    this.cfFunctions = getCFFunctions("runtime\", "CFComponent");
    this.cfFunctions.addAll(getCFFUnctions("compiler\", "cfml40"));
    
    return this;
  }
  
  /**
  * Function to search matching text in code files against specified regular expressions.
  * For every match there will be a row added to the query result.
  * This function just performs search and save results locally, does not return anything.
  */
  public void function doSearchRegexp() {
    // Assign same Group ID to group of rows in search results for component and its functions
    var groupID = 0;
    var inclSubFolder = false;
    var exclSubFolder = false;
    var mainCompListLen = arrayLen(mainCompList);
    var mainCompRelPath = "";
    var mainCompFullPath = "";
    var compFilesListLen = 0;
    var idxMainComp = 0;
    var folderFiles = new query();
    
    idxMainComp = 1;
    for (idxMainComp=1; idxMainComp lte mainCompListLen; idxMainComp=idxMainComp+1) {
      mainCompRelPath = mainCompList[idxMainComp];
      // include components / folders
      var compFilesList = arrayNew(1);
      // Double or Single dot in the end of component path indicates it is a folder. 
      // Create another components list with list of components under specified folder
      if (right(mainCompRelPath, 1) eq ".") {
        if (right(mainCompRelPath, 2) eq ".") {
          // Double dot notation indicates inclusion of sub-folders also. So, convert double dot to single dot for code implementation
          
