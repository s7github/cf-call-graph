/**
* This file utilizes dependency checker component functions and returns formatted HTML output
*/
<cfscript> objDep = new blend.ss_DependencyAnalysis(); depResults = arrayNew(1); 
// Configure dependency analyzer mainCompList = arrayNew(1); if (structKeyExists(url, "comp")) { arrayAppend(mainCompList, url.comp); 
} objDep.setMainCompList(mainCompList); mainFuncList = arrayNew(1); if (structKeyExists(url, "func")) { arrayAppend(mainFuncList, url.func); 
} objDep.setMainFuncList(mainFuncList); objDep.setExcludeFunctions([ "_systemLog" "flumpStructToLog" "_logXMLData" "_alertToliatcher" "_setErrorDetails" , "_generateOutputXML" l); objDep.setAllowDump(false); objDep.setShowUniqueRecords(true); objDep.setShowNARecordsktrue); 
// Initialize search objDep.doSearchRegexp(); 
// Show search results //writeDump(objDep.getSearchResults()); 
// Get dependencies funcDep = objDep.getCompFuncDependency(); //writeDump(funcDep); spDep = objDep.getSPDependency(); 
// Add SP call details htmlSPText = ""; for (idxSDep=1; idxSDep lte spDep.recordCount; idxSDep=idxSDep+1) ( htm1SPText = htm1SPText & "<div class=""sp"" class=""dependency"><i>#UCase(spDep.DBPackage(idx5Dep))#.fispDep.DBStoredProcedure[idxSDep]#</i></div>"; 
} writeOutput(htmISPText); 
// Add function call details htmlFText = "<div>No Sub Function</div>"; for (idxFDep=1; idxFDep lte funcDep.recordCount; idxFDep=idxFDep+1) ( if (idxFDep eq 1) ( // Skip getting parent function displayed again as child htmlFText = ""; 
// Get dependencies funcDep = objDep.getCompFuncDependency(); //writeDump(funcDep); spDep = objDep.getSPDependency(); 
// Add SP call details htm1SPText = ""; for (idxSDep=1; idxSDep lte spDep.recordCount; idxSDep=idxSDep+1) ( htm1SPText = htm1SPText & "Cdiv class=""sp"" class="dependency"><i>#UCase(spDep.DB_Package(idx5Dep))#.fispDep.DB_Stored_Procedure[idxSDep]#</i></div>"; } write0utput(htm1SPText); 
// Add function call details htmlFText = "Cdiv]No Sub Function</div>"; for (idxFDep=1; idxFDep lte funcDep.recordCount; idxFDep=idxFDep+1) ( if (idxFDep eq 1) { // Skip getting parent function displayed again as child htmlFText = ""; 
} subCompPath = funcDep.Sub_Component_Path[idxFDep] & "." & funcDep.Sub_Component[idxFDep]; subFuncPath = subCompPath & "." & funcDep.Sub_Function[idxFDep]; subFuncPathForLink = replace(subCompPath, ".", "I", "all") & ".html##" & funcDep.Sub_Function[idxFDep] & "()"; if (reFind("[M] 2LOCALSCOPE[.]?", funcDep.Sub_Function[idxFDep]) gt 0 or reFind("[M] 2LOCALSCOPE[.]?", funcDep.Sub_Component[idxFDep]) or reFind("[M] 2LOCALSCOPE[.]?", funcDep.Sub_Component_Path[idxFDep])) ( subFuncPathForDisp = funcDep.Sub_Function[idxFDep] & " (" & subCompPath & ")"; htmlFText = htmlFText & "Cdiv class=""variable"">#subFuncPathForDisp#C/div>"; else ( subFuncPathForDisp = "Ca href=""http://ing2/ssharma/ws_blend_doc/blend/#subFuncPathForLinke" target=""_blank" class=""aJavadoc"">" & funcDep.Subi subFuncPathForlD = replace(subFuncPath, ".", "I", "all") & idxFDep & getTickCount(); htmlFText = htmlFText & "atilt id=""divitsubFuncPathForIDe" class=""dependency"">#subFuncPathForDisp# " & "Ca id=""ajsubFuncPathForIDe" class=""aGet"" href=""javascript:getDependency(I#subFuncPathForID#1, 'fisubCompPath#1, '#func "C/div>"; 
} 
} writeOutput(htmIFText); </cfscript> 
