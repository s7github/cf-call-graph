/**
* This file utilizes dependency checker component functions and returns formatted HTML output
*/
<cfscript> 
  objDep = new ss_DependencyAnalysis(); 
  depResults = arrayNew(1); 
  
  // Configure dependency analyzer 
  mainCompList = arrayNew(1); 
  if (structKeyExists(url, "comp")) { 
    arrayAppend(mainCompList, url.comp); 
  } 
  objDep.setMainCompList(mainCompList); 
  mainFuncList = arrayNew(1); 
  if (structKeyExists(url, "func")) { 
    arrayAppend(mainFuncList, url.func); 
  } 
  objDep.setMainFuncList(mainFuncList); 
  objDep.setExcludeFunctions([ 
          "_systemLog" 
        , "flumpStructToLog" 
        , "_logXMLData" 
        , "_alertToliatcher" 
        , "_setErrorDetails" 
        , "_generateOutputXML" 
        ]); 
  objDep.setAllowDump(false); 
  objDep.setShowUniqueRecords(true); 
  objDep.setShowNARecords(true); 
  
  // Initialize search 
  objDep.doSearchRegexp(); 
  
  // Show search results 
  //writeDump(objDep.getSearchResults()); 
  
  // Get dependencies 
  funcDep = objDep.getCompFuncDependency(); 
  //writeDump(funcDep);
  spDep = objDep.getSPDependency(); 
  
  // Add SP call details (TODO: move this section to a function)
  htmlSPText = ""; 
  for (idxSDep=1; idxSDep lte spDep.recordCount; idxSDep++) {
    htmlSPText = htmlSPText & "<div class=""sp"" class=""dependency"><i>#UCase(spDep.DBPackage[idxSDep])#.#spDep.DB_Stored_Procedure[idxSDep]#</i></div>";
  } 
  writeOutput(htmlSPText); 
  
  // Add function call details 
  htmlFText = "<div>No Sub Function</div>"; 
  for (idxFDep=1; idxFDep lte funcDep.recordCount; idxFDep++) { 
    if (idxFDep eq 1) { 
      // Skip getting parent function displayed again as child 
      htmlFText = ""; 
    } 
    subCompPath = funcDep.Sub_Component_Path[idxFDep] & "." & funcDep.Sub_Component[idxFDep]; 
    subFuncPath = subCompPath & "." & funcDep.Sub_Function[idxFDep]; 
    subFuncPathForLink = replace(subCompPath, ".", "/", "all") & ".html##" & funcDep.Sub_Function[idxFDep] & "()";
    subFuncPathForDisp = "<a href=""http://doc_folder/#webAppName#/#subFuncPathForLinke" target=""_blank" class=""aJavadoc"">" & funcDep.Sub_Function[idxFDep] & "</a> (" & subCompPath & ")";
    subFuncPathForlD = replace(subFuncPath, ".", "/", "all") & idxFDep & getTickCount(); 
    htmlFText = htmlFText & "<div id=""div_#subFuncPathForID#"" class=""dependency"">#subFuncPathForDisp# " & 
                            "<a id=""a_#subFuncPathForID#"" class=""aGet"" href=""javascript:getDependency('#subFuncPathForID#', '#subCompPath#', '#funcDep.Sub_Function[idxFDep]#')"">Get Dependency</a>" &
                            "</div>"; 
  }
  writeOutput(htmlFText);
</cfscript> 
