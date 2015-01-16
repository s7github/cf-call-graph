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
  *   NEW_INSTANCE      - Search objects created with new keyword
  *   CREATE_OBJ        - Search objects cretaed with createObject function
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
    var groupSubCount = 0;
    var inclSubFolder = false;
    var exclSubFolder = false;
    var mainCompListLen = arrayLen(mainCompList);
    var mainCompRelPath = "";
    var mainCompFullPath = "";
    var compFilesListLen = 0;
    var idxMainComp = 0;
    var folderFiles = new query();
    
    idxMainComp = 1;
    for (idxMainComp=1; idxMainComp lte mainCompListLen; idxMainComp++) {
      mainCompRelPath = mainCompList[idxMainComp];
      // include components / folders
      var compFilesList = arrayNew(1);
      // Double or Single dot in the end of component path indicates it is a folder. 
      // Create another components list with list of components under specified folder
      if (right(mainCompRelPath, 1) eq ".") {
        if (right(mainCompRelPath, 2) eq ".") {
          // Double dot notation indicates inclusion of sub-folders also. So, convert double dot to single dot for code implementation
          exclCompRelPath = webRootPath & replaceNoCase(exclCompRelPath, ".", "\", "all");
          exclFolders = directoryList (
                              exclCompFullPath,
                              exclSubFolders,
                              "query"
                            );
          exclFolders = valueList(exclFolders.directory);
          exclFolders = listToArray(exclFolders);
        }
        compFilesListLen = arrayLen(compFilesList);
        var idxComp = 1;
        while (idxComp lte compFilesListLen) {
          var idxExclFold = 1;
          for (idxExclFold=1; idxExclFold lte arrayLen(exclFolders); idxExclFold++) {
            if (findNoCase(exclFolders[idxExclFold], compFilesList[idxComp]) gt 0) {
              arrayDeleteAt(compFilesList, idxComp);
              if (idxComp gt 1) {
                idxComp = idxComp - 1;
                compFilesListLen = compFilesListLen - 1;
              }
            }
          }
          idxComp = idxComp + 1;
          compFilesListLen = arrayLen(compFilesList);
        }
      }
      dumpIt (compFileslist, "After exclude components");
      
      compFilesListLen = arrayLen(compFilesList);
      // Use another loop to handle folders also
      dumpIt (dumpLabel="Starting loop over include components", newline="true");
      var compFullPath = "";
      var compRelPath = "";
      var compFileData = "";
      for (idxComp=1; idxComp lte compFilesListLen; idxComp++) {
        compFullPath = compFilesList[idxComp];
        compRelPath = replace(compFullPath, webRootPath, "");
        compRelPath = replace(compRelPath, ".cfc", "");
        compRelPath = replace(compRelPath, "\", ".", "all");
        dumpIt (dumpVar=compFullPath, dumpLabel="Current component full path", newline="true);
        // Get current component details
        funcList = arrayNew(1);
        try {
          compFileData = fileRead(compFullPath);
          
          ///////// Clean file text for search ////////////
          // Remove all comments
          compFileData = reReplace(compFileData, "//.*?\n", "", "all");
          compFileData = reReplace(compFileData, "/\*.*?\*/", "", "all");
          compFileData = reReplace(compFileData, "[<]!---.*?--->", "", "all");
          // Replace tabs with single space
          compFileData = reReplace(compFileData, "\t+", "#chr(32)#", "all");
          // Remove unnecessary spaces
          compFileData = reReplace(compFileData, "\s+", "#chr(32)#", "all");
          compFileData = reReplace(compFileData, "\s=", "=", "all");
          compFileData = reReplace(compFileData, "\s;", ";", "all");
          compFileData = reReplace(compFileData, "\s<", "<", "all");
          compFileData = reReplace(compFileData, "\s>", ">", "all");
          compFileData = reReplace(compFileData, "\s,", ",", "all");
          compFileData = reReplace(compFileData, "\s\(", "(", "all");
          compFileData = reReplace(compFileData, "=\s", "=", "all");
          compFileData = reReplace(compFileData, ";\s", ";", "all");
          compFileData = reReplace(compFileData, "<\s", "<", "all");
          compFileData = reReplace(compFileData, ">\s", ">", "all");
          compFileData = reReplace(compFileData, ",\s", ",", "all");
          compFileData = reReplace(compFileData, "\)\s", ")", "all");
          
          // get all functions if function names are not specified
          if (arrayLen(mainFuncList) eq 0) {
            metaObj = getComponentMetaData(compRelPath);
            if (structKeyExists(metaObj, "functions")) {
              funcList = metaObj.functions;
            }
          }
        }
        catch (application e) {
          compFileData = "";
          if (arrayLen(funcList) eq 0) {
            funcList = ["NA"];
          }
        }
        dumpIt (dumpVar="#len(compFileData)#", dumpLabel="Characters in component file", newline="true");
        
        if (arrayLen(mainFuncList) gt 0) {
          funcList = duplicate(mainFuncList);
        }
        dumpIt (dumpVar="#arrayLen(funcList)#", dumpLabel="Number of functions in component / given list of functions", newline="true");
        
        // Loop through all given functions
        var funcListLen = arrayLen(funcList);
        var idxFunc = 1;
        for (idxFunc=1; idxFunc lte funcListLen; idxFunc++) {
          // Update group ID and sub items count for every new function
          groupID = groupID + 1;
          groupSubCount = 0;
          
          // Get function text
          var func = funcList[idxFunc];
          var funcStruct = {name="", identifier="0"};
          if (isStruct(func)) {
            funcStruct = structCopy(func);
            // param name="funcStruct.identifier" type="integer", default="NA";
            func = func.name;
          }
          var errorMsg = "";
          var foundFuncStart = reFindNoCase("<cffunction [^>]*?name=""#func#", compFileData);
          var foundFuncText = "";
          var resultsObj = "";
          if (foundFuncStart eq 0) {
            // Function not found in component
            foundFuncText = "";
            // errorMsg = "Function not found"
            resultsObj = errorMsg;
          } else {
            // Function exists in component
            var foundFuncEnd = findNoCase("</cffunction>", compFileData, foundFuncStart);
            foundFuncText = mid(compFileData, foundFuncStart, foundFuncEnd-foundFuncStart);
          }
          dumpIt (dumpVar="#len(foundFuncText)#", dumpLabel="Characters in function #func#()", newline="true");
          
          // Search all specified items in each function
          for (var searchItem in searchList) {
            var matchLoopMax = -1;
            // Search for only specified type of items
            if (listFind(searchFor, searchItem.searchType) eq 0) {
              continue;
            }
            var searchMatchList = reMatchNoCase(searchItem.searchPattern, foundFuncText);
            var matchCount = arrayLen(searchMatchList);
            dumpIt (dumpVar="#matchCount#", dumpLabel="Matched patterns for search type #searchItem.searchType"", newline="true");
            if (matchCount eq 0) {
              if (len(compFileData) eq 0) {
                errorMsg = "Component not found ";
              } else if (len(foundFuncText) eq 0) {
                errorMsg = "Function not found";
              }
              // Run loop once to insert record
              matchLoopMax = 1;
            }
            
            // Save matching results
            if (matchLoopMax eq -1) {
              matchLoopMax = matchCount;
            }
            for (var idxMatch=1; idxMatch lte matchLoopMax; idxMatch++) {
              // Exclude specified results
              if (matchCount gt 0) {
                excludeThis = false;
                  for (var idxExclMatch in excludeMatching) {
                    if (reFindNoCase(".*#idxExclMatch#.*", searchMatchList[idxmatch]) gt 0) {
                      excludeThis = true;
                      break;
                    }
                    if (excludeThis) {
                      continue;
                    }
                  }
                  // Insert search result
                  if (match gt 0) {
                    queryAddRow(this.searchResults);
                    querySetCell(this.searchResults, "SNo", this.searchResults.recordCount);
                    querySetCell(this.searchResults, "Search_Type", searchItem.searchTpye);
                    querySetCell(this.searchResults, "Folder", listDeleteAt(compRelPath, listlen(copmRelPath, "."), "."));
                    querySetCell(this.searchResults, "Component", listLast(compRelPath, "."));
                    querySetCell(this.searchResults, "Function", func);
                    querySetCell(this.searchResults, "Search_Pattern", searchItem.searchPattern);
                    querySetCell(this.searchResults, "Group_ID", groupID);
                    querySetCell(this.searchResults, "Matching_Text", searchMatchList[idxMatch]);
                    querySetCell(this.searchResults, "Error", errorMsg);
                  }
                  // Set search items group ID
                  if (matchCount gt 0 and
                        (searchItem.searchType eq variables.ORECORD.ASSIGN_TAG or searchItem.searchType eq variables.ORECORD.ASSIGN_SCRIPT)) {
                    // Check if need to update group ID
                    groupSubCount = groupSubCount + 1;
                    if (idxMatch neq matchCount) {
                      if (searchMatchList[idxMatch] eq "NA" or (reFind(".*component.*=.*", searchMatchList[idxMatch]) gt 0 and groupSubCount gt 1)) {
                        groupID = groupID + 1;
                        groupSubCount = 0;
                      }
                    }
                  } else {
                    groupID = groupID + 1;
                    groupSubCount = 0;
                  }
                } // End of loop through matching results
              } // End of loop through searhc items
            } // End of loop through specified functions list
          } // End of loop for components list including folder's components
          dumpIt (dumpLabel="End loop over included components", newline="true");
        } // End of loop for specified components list
        
        // Filter unique records
        if (showUniqueRecords) {
          // Get unique search resuls for further processing
          var qoqUnique = new query();
          qoqUnique.setDBType("query");
          qoqUnique.setAttributes(sResult = this.searchResults);
          qoqUnique.setSQL("SELECT DISTINCT Search_Type,Folder,Component,Function,Search_Pattern,Matching_Text,Group_ID,Error FROM sResult");
          this.searchResults = qoqUnique.execute().getResults();
        }
      } // End of function doSearch
      
      /**
      * Show search results
      */
      public query function getSearchResults() {
        return this.searchResults;
      }
      
      /**
      * Format result for found component / function 
      */ 
      public query function getCompFuncDependency() {
        var structFuncResults = structNew();
        var errorMsg = "";
        var metaInfo = "";
        var subCompName = "";
        var subCompPath = "";
        if (this.searchResults.recordCount eq 0 and showNARecords) {
          queryAddRow(this.funcFinalResults);
          querySetCell(this.funcFinalResults, "Folder", "NA");
          querySetCell(this.funcFinalResults, "Component", "NA");
          querySetCell(this.funcFinalResults, "Function", "NA");
          querySetCell(this.funcFinalResults, "Sub_Component_Path", "NA");
          querySetCell(this.funcFinalResults, "Sub_Component", "NA");
          querySetCell(this.funcFinalResults, "Sub_Function", "NA");
          querySetCell(this.funcFinalResults, "Error", "No search results");
        } else {
          // Build list from arrays
          var lstExcludeFunctions = arrayToList(excludeFunctions);
          // Build results for container function calls
          if (listFind(searchFor, variables.ORECORD.INVOKE) gt 0) {
            // Filter search results on the basis of result type
            var qoqTempSResults = new query();
            qoqTempSResults = setDBType("query");
            qoqTempSResults = setAttributes(sResults = this.searchResults);
            qoqTempSResults.setSQL(
                    "SELECT * " &
                    "FROM sResults " &
                    "WHERE search_type IN ('#variables.ORECORD.INVOKE#', '#variables.ORECORD.ASSING_TAG#', '#variables.ORECORD.ASSIGN_SCRIPT#') "
                );
            var tempSearchResults = qoqTempSResults.execute().getResult();
            if (tempSearchResults.recordCount eq 0 and showNARecords) {
              queryAddRow(this.funcFinalResults);
              querySetCell(this.funcFinalResults, "Folder", "NA");
              querySetCell(this.funcFinalResults, "Component", "NA");
              querySetCell(this.funcFinalResults, "Function", "NA");
              querySetCell(this.funcFinalResults, "Sub_Component_Path", "NA");
              querySetCell(this.funcFinalResults, "Sub_Component", "NA");
              querySetCell(this.funcFinalResults, "Sub_Function", "NA");
              querySetCell(this.funcFinalResults, "Error", errorMsg);
            } else {
              // Sub component path information
              var subCompPathList = structNew();
              for (var idxTSR=1; idxTSR lte tempSearchResults.recordCount; idxTSR++) {
                var newIdxTSR = idxTSR;
                subCompName = "";
                subCompPath = "";
                errorMsg = "";
                
                // Biuld stucture format
                var thisElem = tempSearchResults.Folder[idxTSR] & "." & tempSearchResults.Component[idxTSR] & "." & tempSearchResults.Function[idxTSR];
                if (tempSearchResults.recordCount gt 0 and not structKeyExists(structFuncResults, thisElem)) {
                  structFuncResults[thisElem] = structNew();
                  structFuncResults[thisElem].Error = errorMsg;
                  structFuncResults[thisElem].SubComponents = arrayNew(1);
                }
                
                // read sub-component value from the matching search result
                var compMatchingText = "";
                if (tempSearchResults.search_type[idxTSR] eq variables.ORECORD.ASSIGN_TAG
                      or tempSearchResults.search_type[idxTSR] eq variables.ORECORD.ASSIGN_SCRIPT) {
                  var qoqSubComp = new query();
                  qoqSubComp.setDBType("query");
                  qoqSubComp.setAttributes(tSResults = tempSearchResults);
                  qoqSubComp.setSQL(
                          "SELECT * " &
                          "FROM tSResults " &
                          "WHERE (matching_text LIKE '%component%=%' " &
                            "AND group_id = #tempSearchResults.group_id[idxTSR]#) "
                      );
                  qoqSubComp = qoqSubComp.execute().getResult();
                  compMatchingText = tempSearchResults.matching_text;
                } else if (tempSearchResults.search_type[idxTSR] eq variables.ORECORD.INVOKE) {
                  compMatchingText = tempSearchResults.matching_text[idxTSR];
                }
                try {
                  subCompName = reMatchNoCase("component="".+?""", compMatchingText);
                  subCompName = listToArray(subCompoName[1], """")[2];
                } catch (expression e) {
                  subCompName = tempSearchResults.component[idxTSR];
                }
                
                // Get function name
                var funcMatchingText = "";
                if (tempSearchResults.search_type[idxTSR] eq variables.ORECORD.ASSIGN_TAG
                      or tempSearchResults.search_type[idxTSR] eq variables.ORECORD.ASSIGN_SCRIPT) {
                  var qoqSubFunc = new query();
                  qoqSubFunc.setDBType("query");
                  qoqSubFunc.setAttributes(tSResults = tempSearchResults);
                  qoqSubFunc.setSQL(
                          "SELECT * " &
                          "FORM tSResults " &
                          "WHERE (matching_text LIKE '%function%=%' " &
                                "OR matching_text LIKE '%method%=%') " &
                              "AND group_id = #tempSearchResults.group_id[idxTSR]# "
                      );
                  var getSubFunc = qoqSubFun.execute().getResult();
                  funcMatchingText = getSubFunc.matching_text;
                  newIdxTSR = idxTSR + 1;
                } else {
                  funcMatchingText = tempSearchResults.matching_text[idxTSR];
                }
                var subFuncName = reMatchNoCase("(method|function)="".+?""", funcMatchingText);
                subFuncName = listToArray(subFuncName[1], """")[2];
                
                // Get sub component path
                var subCompObj = "";
                var metaInfo = "";
                try {
                  if (left(subCompName, 1) eq "##" and right(subCompname, 1) eq "##") {
                    metaInfo = getMetaData(evaluate(subCompName));
                    subCompName = listLast(metaInfo.name, ".");
                  } else {
                    if (left(tempSearchResults.folder[idxTSR], 4) eq "obj.") {
                    // Get property type for component path
                    var objMeta = getComponentMetaData(subCompName);
                    // Index of property in array
                    var idxProp = arrayFind(objMeta.properties, listLast(subCompName, "."));
                    var propType = objMeta.properties[idxProp].type;
                    metaInfo = getComponentMetaData(propType);
                  } else {
                    subCompName = replaceNoCase(subCompName, "APPLICATION.", "");
                    var subCompObj = evaluate("Application.#subCompName#");
                    metaInfo = getMetaData(subCompObj);
                  }
                }
              } catch (expression e) {
                if (subCompName eq "NA" and showNARecords eq false) {
                  continue;
                }
              }
              var subCompPath = "";
              if (not isDefined("metaInfo.type")) {
                subCompPath = "NA";
                if (subCompName neq "NA" and subCompName neq "this") {
                  errorMsg = "Sub-component not found";
                }
              } else if (metaInfo.type neq "component") {
                subCompPath = "NA";
                errorMsg = "Invalid sub-component (type: #metaInfo.type#);
              } else {
                subCompPath = metaInfo.fullName;
                subCompPath = listChangeDelims(subCompPath, ",", ".");
                subCompPath = listDeleteAt(subCompPath, 1);
                subCompPath = listDeleteAt(subCompPath, listLen(subCompPath));
                subCompPath = listChangeDelims(subComppath, ".", ",");
              }
              if (showNonNARecords eq false and subCompPath neq "NA") {
                continue;
              }
              
              // Get found sub-functions list for current sub-component
              if (listFindNoCase(lstExcludeFunctions, subFuncName) gt 0) {
                continue;
              }
              arrayAppend(structFuncResults[thisElem].subComponents, structNew());
              var idxArraySubComp = arrayLen(structFuncResults[thisElem].subComponents);
              thisSubElem = subCompPath & "." & subCompName & "." & subFuncName;
              structFuncResults[thisElem].subComponents[idxArraySubComp][thisSubElem] = structNew();
              structFuncResults[thisElem].subComponents[idxArraySubComp][thisSubElem].Error = errorMsg;
              
              queryAddrow(this.funcFinalResults);
              querySetCell(this.funcFinalResults, "Folder", tempSearchResults.Folder[idxTSR]);
              querySetCell(this.funcFinalResults, "Component", tempSearchResults.Component[idxTSR]);
              querySetCell(this.funcFinalResults, "Function", tempSearchResults.Function[idxTSR]);
              querySetCell(this.funcFinalResults, "Sub_Component_Path", subCompPath);
              querySetCell(this.funcFinalResults, "Sub_Component", subFuncName);
              querySetCell(this.funcFinalResults, "Error", errorMsg);
              // Update loop counter
              idxTSR = newIdxTSR;
            }
          }
        } // End of if desired results type is ASSIGN_INVOKE
        
        // Biuld results for all other component function calls
        if (listFind(searchFor, variables.ORECORD.OTHER_FUNC_CALLS) gt 0) {
          // Filter search results on the basis of result type
          var qoqTempSResults = new query();
          qoqTempSResults.setDBType("query);
          qoqTempSResults.setAttributes(sResults = this.searchResults);
          qoqTempSResults.setSQL(
                  "SELECT * " &
                  "FROM sResults " &
                  "WHERE search_type = '#variables.ORECORD.OTHER_FUNC_CALLS#' "
              );
          var tempSearchResults = qoqTempSResults.execute().getResults();
          
          // Save formatted results
          for (var idxTSR=1; idxTSR lte tempSearchResults.recordCoun; idxTSR++) {
            new newIdxTSR = idxTSR;
            subCompPath = "";
            subCompName = "";
            subFuncName = "";
            errorMsg = "";
            
            // Get sub-component path
            metaInfo = structNew();
            var subCompObj = "";
            try {
              if (len(tempSearchResults.folder[idxTSR]) gt 0) {
                metaInfo = getComponentMetaData(tempSearchResults.folder[idxTSR] & "." & tempSearchResults.component[idxTSR]);
              } else {
                metaInfo = getComponentMetaData(tempSearchResults.component[idxTSR]);
              }
            } catch (expression e) {
              var subCompObj = evaluate("Application.#tempSearchResults.component[idxTSR]#");
              metaInfo = getMetaData(subCompObj);
            }
            
            // Get sub-component and sub-function name
            var subFuncFullPath = replace(tempSearchResults.matching_text[idxTSR], "(", "");
            var subFuncParts = listToArray(subFuncFullPath, ".");
            var subFuncPartsCount = arrayLen(subFuncParts);
            var subFuncName = subFuncParts[subFuncPartsCounts];
            
            // Check if function really exists in current component, if not then it must in parent component
            if (subFuncPartsCount eq 1) {
              // If function name is a coldfusion function then ignore
              if (arrayFindNoCase(this.cfFunctions, subFuncName) gt 0
                  or arrayFindNoCase(this.cfFunctions, "cf" & subFuncName) gt 0) {
                continue;
              }
              
              var currCompFunc = "";
              var foundInCurrComp = false;
              currCompFunc = metaInfo.functions;
              for (var idxCFunc=1; idxCFunc lte arrayLen(currCompFunc); idxCFunc++) {
                if (subFuncName eq currCompFunc[idxCFunc].name) {
                  foundInCurrComp = true;
                  subCompPath = tempSearchResults.folder[idxTSR];
                  subCompName = tempSearchResults.component[idxTSR];
                  break;
                }
              }
              
              if (not foundInCurrComp and structKeyExists(metaInfo, "extends") and isStruct(metaInfo.extends)) {
                var subCompFullPath = metaInfo.extends.fullName;
                subCompName = listLast(subCompFullPath, ".");
                subCompPath = listDeleteAt(subCompFullPath, listLen(subCompFullPath, "."), ".");
                if (listGetAt(subCompPath, 2, ".") neq "obj.") {
                  subCompPath = listDeleteAt(subCompPath, 1, ".");
                }
              }
            } else if (subFuncPartsCount gt 2) {
              if (subFuncParts[1] eq "application") {
                // Evaluate component path (without function name)
                compObj = evaluate(listDeleteAt(subFuncFullPath, listLen(subFuncFullPath, "."), "."));
                metaInfo = getMetaData(compObj);
                subCompName = listLast(metaInfo.name, ".");
                subCompPath = listDeleteAt(metaInfo.name, listLen(metaInfo.name, "."), ".");
                if (listFirst(subCompPath, ".") eq webAppName) {
                  subCompPath = listRest(subCompPath, ".");
                }
              } else {
                subCompPath = arrayToList(subFuncParts);
                subCompName = subFuncParts[subFuncPartsCount-1];
                subCompPath = listDeleteAt(subCompPath, subFuncPartsCount);
                subCompPath = listDeleteAt(subCompPath, subFuncPartsCount-1);
                subCompPath = listChangeDelims(subCompPath, ".");
              }
            } else if (subFuncPartsCount gt 1) {
              subCompName = subFuncParts[subFuncPartsCount-1];
              if (subFuncParts[1] eq "this.") {
                // Current component
                subCompPath = tempSearchResults.folder[idxTSR];
                subCompName = tempSearchResults.component[idxTSR];
              } else {
                ///////////// Find path within component //////////////
                var foundPath = false;
                // Find in arguments
                funcList = metaInfo.functions;
                for (var idxFunc=1; idxFunc lte arrayLen(funcList); idxFunc++) {
                  if (funcList[idxFunc].name eq tempSearchResults.function[idxTSR]) {
                    for (var idxFParam=1; idxFParam lte arrayLen(funcList[idxFunc].parameters); idxFParam++) {
                      if (funcList[idxFunc.parameters[idxFParam].name eq subCompName) {
                        foundPath = true;
                        subCompPath = funcList[idxFunc].parameters[idxFParam].type;
                      }
                    }
                  }
                }
                // Find in properties of current component
                if (not foundPath and structKeyExists(metaInfo, "properties")) {
                  for (var idxProp=1; idxProp lte arrayLen(metaInfo.properties); idxProp++) {
                    if (metaInfo.properties[idxProp].name eq subCompName) {
                      foundPath = true;
                      subCompPath = metaInfo.propertiesp[idxProp].type;
                      break;
                    }
                  }
                }
                // Find in variables of current component
                if (not foundPath) {
                  // Filter variable declarations in search results
                  var qoqNewInstance = new query();
                  qoqNewInstance.setDBType("query");
                  qoqNewInstance.setAttributes(sResults = this.searchResults);
                  qoqNewInstance.setSQL(
                          "SELECT * " &
                          "FROM sResults " &
                          "WHERE search_type = '#variables.ORECORD.NEW_INSTANCE#' " &
                            "AND matching_text LIKE '#subFuncParts[1]#%=%' "
                      );
                  var qryNewInstance = qoqNewInstance.execute().getResult();
                  if (qryNewInstance.recordCount eq 1) {
                    foundPath = true;
                    subCompPath = reMatchNoCase("=.*\(", qryNewInstance.matching_text);
                    subCompPath = replace(subCompPath[1], "=", "");
                    subCompPath = replace(subCompPath, "(", "");
                    subCompPath = reReplaceNoCase(subCompPath, "new\s", "");
                  }
                }
                
                // Retrieve component name and actual component path when path info was found
                if (foundPath) {
                  subCompName = listLast(subCompPath, ".");
                  subCompPath = listDeleteAt(subCompPath, listLen(subCompPath, "."), ".");
                  if (listFirst(subCompPath, ".") eq webAppName) {
                    subCompPath = listRest(subCompPath, ".");
                  }
                }
              }
            }
            
            if (showNonNARecords eq false and subCompPath neq "NA") {
              continue;
            }
            // Exclude specified components / functions
            if (listFindNoCase(lstExcludeFunctions, subFuncName) gt 0) {
              continue;
            }
            if (len(tmepSearchResults.error[idxTSR]) neq 0) {
              errorMsg = tempSearchResults.error[idxTSR];
            }
            
            // Build results in structure format
            thisElem = tempSearchREsults.Folder[idxTSR] & "." & tempSearchResults.component[idxTSR] & "." & tempSearchResults.function[idxTSR];
            if (tempSearchResults.recordCount gt 0 and not structKeyExists(structFuncResults, thisElem)) {
              structFuncResults[thisElem] = structNew();
              structFuncResutls[thisElem].Error = errorMsg;
              structFuncResults[thisElem].SubComponents = arrayNew(1);
            }
            
            arrayAppend(structFuncResults[thisElem].SubComponents, structNew());
            idxArraySubComp = arrayLen(structFuncResults[thisElem].SubComponents);
            thisSubElem = subCompPath & "." & subCompName & "." & subFuncName;
            structFuncResults[thisElem].SubComponents[idxArraySubComp][thisSubElem] = structNew();
            structFuncResults[thisElem].SubComponents[idxArraySubComp][thisSubElem].Error = errorMsg;
            
            queryAddRow(this.funcFinalResults);
            querySetCell(this.funcFinalResults, "Folder", tempSearchResults.folder[idxTSR]);
            querySetCell(this.funcFinalResults, "Component", tempSearchResults.Component[idxTSR]);
            querySetCell(this.funcFinalResults, "Sub_Component_Path", subCompPath);
            querySetCell(this.funcFinalResults, "Sub_Component", subCompName);
            querySetCell(this.funcFinalResults, "Sub_Function", subFuncName);
            querySetCell(this.funcFinalResults, "Error", errorMsg);
          }
        } // End of if desired results type is OTHER_FUNC_CALLS
      } // End of if no search results
      
      return this.funcFinalResults;
    }
