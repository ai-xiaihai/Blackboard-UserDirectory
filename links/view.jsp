<%@ page import="java.util.*,
				 java.text.SimpleDateFormat,
				 blackboard.admin.data.user.*,
				 blackboard.admin.data.IAdminObject,
				 blackboard.admin.persist.user.*,
				 blackboard.base.*,
				 blackboard.data.*,
                 blackboard.data.user.*,
				 blackboard.data.course.*,
				 blackboard.data.role.*,
                 blackboard.persist.*,
                 blackboard.persist.user.*,
				 blackboard.persist.role.*,
				 blackboard.persist.course.*,
                 blackboard.platform.*,
                 blackboard.platform.persistence.*,
				 blackboard.platform.plugin.PlugInUtil"
        errorPage="/error.jsp"
%>

<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>

<%	String searchTerm = request.getParameter("searchterm");
	String searchCriteria = request.getParameter("searchcriteria");
	String searchRole = request.getParameter("searchrole");
	boolean initialSearch = false;
	if(searchTerm != null && searchCriteria != null && searchRole != null)
		initialSearch = true;
	searchTerm = searchTerm == null ? "" : searchTerm;
	searchCriteria = searchCriteria == null || searchCriteria.isEmpty() ? "user" : searchCriteria;
	searchRole = searchRole == null || searchRole.isEmpty() ? "student" : searchRole;
%>

<bbUI:docTemplateHead title="OCTET User Directory">
<link rel="stylesheet" type="text/css" href="../css/view.css">
<script src="../js/view.js"></script>
<script>
window.onload = function()
				{
					window.onkeydown = globalKeyHandler;
					document.getElementById("searchterm").focus();
					<%=initialSearch ? "newSearch();" : ""%>
				};
</script>
</bbUI:docTemplateHead>

<bbUI:breadcrumbBar environment="PORTAL">
	<bbUI:breadcrumb href="https://blackboard.oberlin.edu/">Click here to return to Blackboard</bbUI:breadcrumb>
	<bbUI:breadcrumb>OCTET User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>
<bbUI:titleBar iconUrl="/images/ci/icons/user_u.gif">OCTET User Directory</bbUI:titleBar>

<input id="searchterm" type="text" name="searchterm" size="40" autocomplete="on" placeholder="Enter your search here..." value="<%=searchTerm%>" autofocus/>
<input type="button" onclick="newSearch();" value="Search" />
<br />
<div class="style1">Search by:
	<label><input id="firstname" type="radio" name="searchcriteria" value="first" <%=searchCriteria.equals("first") ? "checked" : ""%> />First Name</label>
	<label><input id="lastname" type="radio" name="searchcriteria" value="last" <%=searchCriteria.equals("last") ? "checked" : ""%> />Last Name</label>
	<label><input id="username" type="radio" name="searchcriteria" value="user" <%=searchCriteria.equals("user") ? "checked" : ""%> />Username</label>
</div>
<div class="style1">Search for:
	<label><input id="studentrole" type="radio" name="searchrole" value="student" <%=searchRole.equals("student") ? "checked" : ""%> />Students</label>
	<label><input id="facultyrole" type="radio" name="searchrole" value="faculty" <%=searchRole.equals("faculty") ? "checked" : ""%> />Faculty</label>
	<label><input id="staffrole" type="radio" name="searchrole" value="staff" <%=searchRole.equals("staff") ? "checked" : ""%> />Staff</label>
</div>

<div id="loadingsearch" class="loadingmessage">Loading...<br /></div>
<div id="searchresults"></div>
