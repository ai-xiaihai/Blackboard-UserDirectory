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
	Set<String> searchRoles = new HashSet<String>();
	String[] searchRoleNames = request.getParameterValues("searchroles");
	if(searchRoleNames == null)
		searchRoleNames = new String[] { "Student", "Faculty", "Staff" };
	Collections.addAll(searchRoles, searchRoleNames);
	boolean initialSearch = false;
	if(searchTerm != null && searchCriteria != null && !searchRoles.isEmpty())
		initialSearch = true;
	if(searchTerm == null)
		searchTerm = "";
	if(searchCriteria == null || searchCriteria.isEmpty())
		searchCriteria = "user";
%>

<bbUI:docTemplateHead title="OCTET User Directory">
<link rel="stylesheet" type="text/css" href="../css/view.css">
<link rel="stylesheet" type="text/css" href="https://blackboard.oberlin.edu/common/shared.css?v=9.1.201410.160373" id="css_3">
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
	<label><input id="firstname" type="radio" name="searchcriteria" value="first" <% if(searchCriteria.equals("first")) out.print("checked"); %> />First Name</label>
	<label><input id="lastname"  type="radio" name="searchcriteria" value="last"  <% if(searchCriteria.equals("last"))  out.print("checked"); %> />Last Name</label>
	<label><input id="username"  type="radio" name="searchcriteria" value="user"  <% if(searchCriteria.equals("user"))  out.print("checked"); %> />Username</label>
</div>
<div class="style1">Search for:
	<label><input id="studentrole" type="checkbox" name="searchroles" value="Student" <% if(searchRoles.contains("Student")) out.print("checked"); %> />Students</label>
	<label><input id="facultyrole" type="checkbox" name="searchroles" value="Faculty" <% if(searchRoles.contains("Faculty")) out.print("checked"); %> />Faculty</label>
	<label><input id="staffrole"   type="checkbox" name="searchroles" value="Staff"   <% if(searchRoles.contains("Staff"))   out.print("checked"); %> />Staff</label>
</div>
<br />
<div id="loadingmessage">Loading...<br /></div>
<br />
<div id="searchresults"></div>
