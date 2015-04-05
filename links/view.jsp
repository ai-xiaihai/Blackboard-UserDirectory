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
<bbData:context id="ctx">
<bbUI:docTemplate title="OCTET User Directory">
<bbUI:breadcrumbBar environment="PORTAL">
	<bbUI:breadcrumb href="https://blackboard.oberlin.edu/">Click here to return to Blackboard</bbUI:breadcrumb>
	<bbUI:breadcrumb>OCTET User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>
<bbUI:titleBar iconUrl="/images/ci/icons/user_u.gif">OCTET User Directory</bbUI:titleBar>
<%
// Debugging flag for simulating the view of faculty/staff
final boolean DEBUG = false;
// Appointment tool
final boolean APPOINTMENTS = false;

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
// Find the guest portal role.
PortalRole guestPortalRole = getPortalRoleByName(portalRoles, "Guest");

// Find out who the user is.
User currentUser = ctx.getUser();
// Find the current user's portal role.
Id currentUserPortalRoleId = currentUser.getPortalRoleId();
// Should we show them potentially sensitive information?
boolean displayPrivilegedInformation = DEBUG;
if(!ctx.getSession().isAuthenticated() ||
	currentUserPortalRoleId.equals(guestPortalRole.getId()))
{ %>
	<div>You must be logged in to use this tool.</div>
<% return;
}
// If they are a member of faculty or staff, we do
else if(currentUserPortalRoleId.equals(facultyPortalRole.getId()) ||
		currentUserPortalRoleId.equals(staffPortalRole.getId()))
{
	displayPrivilegedInformation = true;
}
// If they are not a student, alumnus, or faculty/emeriti, block access
else if(!(currentUserPortalRoleId.equals(studentPortalRole.getId()) ||
		  currentUserPortalRoleId.equals(emeritiPortalRole.getId()) ||
		  currentUserPortalRoleId.equals(alumniPortalRole.getId())))
{ %>
	<div>In order to use this tool, you must be a student, alumnus, staff member, emeritus, or faculty member.</div>
<% return;
}
%>
<head>
<link rel="stylesheet" type="text/css" href="../css/view.css">
<script>
	var xmlhttp = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
	window.onload = function()
					{
						document.getElementById("searchterm").focus();
						document.onkeypress= function() { searchOnEnter(event); };
					}
	function imageError(image)
	{
		image.src = "http://octet1.csr.oberlin.edu/octet/Bb/Faculty/img/noimage.jpg";
		image.onError = null;
	}
	function mouseOverImage(image, newImage)
	{
		var height = image.clientHeight;
		image.src = newImage;
		image.style.height = height;
	}
	function mouseOutImage(image, newImage) { image.src = newImage; }
	function mouseOverAudio(user) { document.getElementById(user + '_audio').play(); }
	function mouseOutAudio(user) { document.getElementById(user + '_audio').pause(); }
	function mouseOverBoth(image, newImage, user)
	{
		mouseOverImage(image, newImage);
		mouseOverAudio(user);
	}
	function mouseOutBoth(image, newImage, user)
	{
		mouseOutImage(image, newImage);
		mouseOutAudio(user);
	}
	function loadAJAX(fileLocation, updateFunction, postData)
	{
		xmlhttp.onreadystatechange = updateFunction;
		xmlhttp.open("POST", fileLocation, true);
		xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
		xmlhttp.send(postData);
	}
	function searchOnEnter(event)
	{
		if(event.keyCode == 13)
		{
			loadAJAX('search.jsp', searchUpdate, getSearchData());
			document.activeElement.blur();
		}
	}
	function searchUpdate()
	{
		if(xmlhttp.status == 404)
		{
			document.getElementById("loadingsearch").innerHTML = "";
			alert("Something went wrong! We couldn't communicate with our server. Please let the OCTET office know if this was unexpected.");
		}
		else if(xmlhttp.readyState < 4)
		{
			document.getElementById("loadingsearch").innerHTML = '<span class="style7">Loading...</span>';
		}
		else
		{
			document.getElementById("loadingsearch").innerHTML = "";
			document.getElementById("searchresults").innerHTML = xmlhttp.responseText;
		}
	}
	function getSearchData()
	{
		var result = "";

		result += "searchterm=" + document.getElementById("searchterm").value;

		result += "&searchcriteria=";
		if(document.getElementById("firstname").checked)
			result += document.getElementById("firstname").value;
		else if(document.getElementById("lastname").checked)
			result += document.getElementById("lastname").value;
		else if(document.getElementById("username").checked)
			result += document.getElementById("username").value;

		result += "&searchrole=";
		if(document.getElementById("studentrole").checked)
			result += document.getElementById("studentrole").value;
		else if(document.getElementById("facultystaffrole").checked)
			result += document.getElementById("facultystaffrole").value;

		return result;
	}
</script>
</head>

<%!
	// Take in some iterable data structure of PortalRoles and see if any of them return roleName from their getRoleName method.
	// If so, return that PortalRole. If not, return null.
	public static PortalRole getPortalRoleByName(Iterable<PortalRole> portalRoles, String roleName)
	{
		for(PortalRole portalRole : portalRoles)
			if(portalRole.getRoleName().equals(roleName)) return portalRole;
		return null;
	}
%>

<%
/* This is the entry point for the user directory.
 * The user directory allows users in blackboard to search for students, faculty, and staff by last name, first name, and user name.
 * If a student searches for other students, only names, emails, and photos are displayed.
 */

// What text did they ask to search for?
String searchTerm = request.getParameter("searchterm");
if(searchTerm == null) searchTerm = "";

// How do they want to search--first name, last name, or user name? Defaults to last name.
String searchCriteria = request.getParameter("searchcriteria");
if(searchCriteria == null) searchCriteria = "last";

// What kind of user are they searching for--student or faculty/staff? Defaults to student.
String searchRole = request.getParameter("searchrole");
if(searchRole == null) searchRole = "student";
%>

<input id="searchterm" type="text" name="searchterm" size="40" autocomplete="on" placeholder="Enter your search here..." autofocus/>
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
<div id="loadingsearch" class="loadingmessage"></div>
<br />
<div id="searchresults"></div>
</bbUI:docTemplate>
</bbData:context>
