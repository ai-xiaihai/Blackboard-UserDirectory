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

<%!
	// Take in some iterable data structure of PortalRoles and see if any of them return roleName from their getRoleName method.
	// If so, return that PortalRole. If not, return null.
	public static PortalRole getPortalRoleByName(Iterable<PortalRole> portalRoles, String roleName)
	{
		for(PortalRole portalRole : portalRoles)
			if(portalRole.getRoleName().equals(roleName)) return portalRole;
		return null;
	}
	public static String escape(String string) { return string.replace("'", "\\'"); }
%>

<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<bbData:context id="ctx">
<bbUI:breadcrumbBar environment="PORTAL">
	<bbUI:breadcrumb href="https://blackboard.oberlin.edu/">Click here to return to Blackboard</bbUI:breadcrumb>
	<bbUI:breadcrumb>OCTET User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>
<bbUI:titleBar iconUrl="/images/ci/icons/user_u.gif">OCTET User Directory</bbUI:titleBar>
<%
	// Create a persistence manager - needed if we want to use loaders or persisters in blackboard.
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	// Create a portal role loader, for locating and indentifying the portal roles of users.
	PortalRoleDbLoader portalRoleLoader = (PortalRoleDbLoader)bbPm.getLoader(PortalRoleDbLoader.TYPE);

	// Load all portal roles once to avoid redundancy with calls to getPortalRoleByName().
	List<PortalRole> portalRoles = portalRoleLoader.loadAll();
	// Find the student portal role.
	PortalRole studentPortalRole = getPortalRoleByName(portalRoles, "Student");
	// Find the faculty portal role.
	PortalRole facultyPortalRole = getPortalRoleByName(portalRoles, "Faculty");
	// Find the staff portal role.
	PortalRole staffPortalRole = getPortalRoleByName(portalRoles, "Staff");
	// Find the emeriti portal role.
	PortalRole emeritiPortalRole = getPortalRoleByName(portalRoles, "Emeriti");
	// Find the alumni portal role.
	PortalRole alumniPortalRole = getPortalRoleByName(portalRoles, "Alumni");
	// Find the non-Obie portal role.
	PortalRole nonObiePortalRole = getPortalRoleByName(portalRoles, "Non Obie");
	// Find the guest portal role.
	PortalRole guestPortalRole = getPortalRoleByName(portalRoles, "Guest");

	// Find out who the user is.
	User currentUser = ctx.getUser();
	// Find the current user's portal role.
	Id currentUserPortalRoleId = currentUser.getPortalRoleId();
	// Make sure they're logged in.
	if(!ctx.getSession().isAuthenticated() ||
		currentUserPortalRoleId.equals(guestPortalRole.getId()))
	{
		out.print("<div>You must be logged in to use this tool.</div>");
		return;
	}
	// If they are not a student, alumnus, or faculty/emeriti, block access.
	else if(!(currentUserPortalRoleId.equals(studentPortalRole.getId()) ||
			  currentUserPortalRoleId.equals(emeritiPortalRole.getId()) ||
			  currentUserPortalRoleId.equals(alumniPortalRole.getId())  ||
			  currentUserPortalRoleId.equals(nonObiePortalRole.getId())))
	{
		out.println("<div>In order to use this tool, you must be a student, alumnus, staff member, emeritus, or faculty member.</div>");
		return;
	}
	String searchTerm = request.getParameter("searchterm");
	String searchCriteria = request.getParameter("searchcriteria");
	String searchRole = request.getParameter("searchrole");
%>

<bbUI:docTemplateHead title="OCTET User Directory">
<link rel="stylesheet" type="text/css" href="../css/view.css">
<script src="../js/view.js"></script>
</bbUI:docTemplateHead>

<input id="searchterm" type="text" name="searchterm" size="40" autocomplete="on" placeholder="Enter your search here..." <%if(searchTerm != null) out.print("value=\"" + searchTerm + "\"");%> autofocus/>
<input type="button" onclick="loadAJAX('search.jsp', searchUpdate, getSearchData());" value="Search" />
<br />
<span class="style1">Search by:
	<label><input id="firstname" type="radio" name="searchcriteria" value="first" />First Name</label>
	<label><input id="lastname" type="radio" name="searchcriteria" value="last" />Last Name</label>
	<label><input id="username" type="radio" name="searchcriteria" value="user" checked />Username</label>
	<br />
</span>
<span class="style1">Search for:
	<label><input id="studentrole" type="radio" name="searchrole" value="student" checked />Students</label>
	<label><input id="facultystaffrole" type="radio" name="searchrole" value="facultystaff" />Faculty/Staff</label>
	<br />
</span>
<br />
<div id="loadingsearch" class="loadingmessage"><br /></div>
<br />
<div id="searchresults"></div>
<%
	if(searchTerm != null && searchCriteria != null && searchRole != null)
	{
		String initialSearchData = "searchterm=" + searchTerm +
								   "&searchcriteria=" + searchCriteria +
								   "&searchrole=" + searchRole;
		out.println("<script>loadAJAX('search.jsp', searchUpdate, '" + escape(initialSearchData) + "');</script>");
	} %>
</bbData:context>
