<%@page import="java.util.*,
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
                blackboard.platform.persistence.*"
        errorPage="/error.jsp"
%>
<script>
function imageError(theImage)
{
theImage.src="http://octet1.csr.oberlin.edu/octet/Bb/Faculty/img/noimage.jpg";
theImage.onError = null;
}
</script>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<style type="text/css">
<!--
.style1 {
	font-weight: normal;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 11px;
}
.style3 {
	font-family: Georgia, "Times New Roman", Times, serif;
	font-weight: bold;
}
.style4 {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-weight: bold;
	font-size: 12px;
}
.style7 {
	font-size: 16px;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-weight: bold;
}
-->
</style>


<bbData:context id="ctx">
<bbUI:docTemplate title="User Directory">
<bbUI:breadcrumbBar environment="PORTAL">
 <bbUI:breadcrumb>User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>

<%
/* This is the entry point for the student directory.
 * The student directory allows users in blackboard to seatch for students by username or last name.
 * It displays only name, email and a photo. The students have to opt in to have their photo displayed in the directory.
 */

// What text did they ask to search for?
String uid = request.getParameter("uid");
if(uid == null)
{
	uid = "";
}

// How do they want to search--first name, last name, or user name? Defaults to last name.
String searchCriteria = request.getParameter("searchcriteria");
if(searchCriteria == null)
{
	searchCriteria = "last";
}

// What kind of user are they searching for--student or faculty/staff? Defaults to student.
String searchRole = request.getParameter("searchrole");
if(searchRole == null)
{
	searchRole = "student";
}
%>

<bbUI:titleBar 	iconUrl="/images/ci/icons/user_u.gif">Student Directory</bbUI:titleBar>
<form action="userDir.jsp" method="post" id="searchusers">
<span class="style2">
<input name="uid" type="text" size="40" value="<%=uid%>">
<bbUI:button type="INLINE" name="search" alt="Search" action="SUBMIT_FORM"></bbUI:button>
<input name="process" type="hidden" id="process" value="1">
<br>
<span class="style1">Search by:
  <label>
  <input type="radio" name="searchcriteria" value="first" <% if(searchCriteria.equals("first")){out.println("checked");} %> >
  First Name</label>
  <label>
  <input type="radio" name="searchcriteria" value="last" <% if(searchCriteria.equals("last")){out.println("checked");} %> >
  Last Name</label>
  <label>
  <input type="radio" name="searchcriteria" value="user" <% if(searchCriteria.equals("user")){out.println("checked");} %> >
  Username</label><br>
</span>
<span class="style1">Search for:
  <label>
  <input type="radio" name="searchrole" value="student" <% if(searchRole.equals("student")){out.println("checked");} %> >
  Students</label>
  <label>
  <input type="radio" name="searchrole" value="facultystaff" <% if(searchRole.equals("facultystaff")){out.println("checked");} %> >
  Faculty/Staff</label><br>
</span>
</form>
<%
// Determine whether or not they actually specified a search with another variable, since a blank search term is valid.
if(request.getParameter("process") != null)
{
	// create a persistence manager - needed if we want to use loaders or persisters in blakcboard
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();

	// sort by last name, first name
	GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
	comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
	//create a treeset (alphabetized, unique entries) to store user objects
	TreeSet<Person> personSet = new TreeSet<Person>(comparator);

	//create a database loder for person objects
	PersonLoader personLoader = (PersonLoader)bbPm.getLoader(PersonLoader.TYPE);

	//create a database loader for portal role objects
	PortalRoleDbLoader roleLoader = (PortalRoleDbLoader)bbPm.getLoader(PortalRoleDbLoader.TYPE);

	// BRUTE FORCE METHOD FOR FINDING STUDENT (and faculty and staff) PORTAL ROLE(s):
	PortalRole studentPortalRole = null;
	PortalRole facultyPortalRole = null;
	PortalRole staffPortalRole = null;
	for(PortalRole portalRole : roleLoader.loadAll())
	{
		switch(portalRole.getRoleName())
		{
			case "Student":
				studentPortalRole = portalRole;
				break;
			case "Faculty":
				facultyPortalRole = portalRole;
				break;
			case "Staff":
				staffPortalRole = portalRole;
				break;
		}
		// We've found every role we need to and can exit the loop.
		if(staffPortalRole != null && facultyPortalRole != null && studentPortalRole != null)
		{
			break;
		}
	}

	Id currentUserPortalRoleId = ctx.getUser().getPortalRoleId();
	if(ctx.getUser().getUserName().equals("cegerton"))
	{
		currentUserPortalRoleId = facultyPortalRole.getId();
	}

	Id[] portalRoleIds = null;
	if(searchRole.equals("student"))
	{
		portalRoleIds = new Id[] {studentPortalRole.getId()};
	}
	else if(searchRole.equals("facultystaff"))
	{
		portalRoleIds = new Id[] {facultyPortalRole.getId(), staffPortalRole.getId()};
	}

	// // CODE THAT SHOULD WORK BUT DOES NOT (bug report has been submitted):
	// PortalRole studentPortalRole = roleLoader.loadByRoleName("Student");

	// CODE FOR TESTING THE ABOVE:
	%><%--
	Set<PortalRole> portalRoles = new HashSet<PortalRole>(roleLoader.loadAll());

	PortalRole test;
	String portalRoleName;
	for(PortalRole portalRole : portalRoles)
	{
		portalRoleName = portalRole.getRoleName();
		try
		{
			test = roleLoader.loadByRoleName(portalRoleName);
			%>
			<div>
			Test succeeded for Portal Role <%=test.getRoleName()%>.
			</div>
			<%
		}
		catch(KeyNotFoundException exception)
		{ %>
			<div>
			Test failed for Portal Role <%=portalRoleName%>.
			</div>
		<% }
	} --%><%

	// Create a Person object to use as a template for searching with the PersonLoader's load() method
	Person searchTemplate = new Person();
	// We only want to load enabled users.
	searchTemplate.setRowStatus(IAdminObject.RowStatus.ENABLED);
	// We only want to load available users.
	searchTemplate.setIsAvailable(true);

	// Can't let users search for names with wildcards in them.
	if(!uid.contains("%"))
	{
		// Iterate over possible Portal Role IDs (have to accomodate possibility of multiple IDs if faculty/staff are being searched for).
		for(Id id : portalRoleIds)
		{
			searchTemplate.setPortalRoleId(id);
			// The user did not specify a search string, so load all students.
			if(uid.equals(""))
			{
				personSet.addAll(personLoader.load(searchTemplate));
			}
			// The user has specified a search string.
			else
			{
				if(searchCriteria.equals("first")) //searching by first name
				{
					// Search with user-specified capitalization.
					searchTemplate.setGivenName("%" + uid + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with user-specified capitalization and first character capitalized.
					searchTemplate.setGivenName("%" + uid.substring(0, 1).toUpperCase() + uid.substring(1) + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with all lowercase.
					searchTemplate.setGivenName("%" + uid.toLowerCase() + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with first character capitalized and the rest lowercase.
					searchTemplate.setGivenName("%" + uid.substring(0, 1).toUpperCase() + uid.substring(1).toLowerCase() + "%");
					personSet.addAll(personLoader.load(searchTemplate));
				}
				if(searchCriteria.equals("last")) //searching by last name
				{
					// Search with user-specified capitalization.
					searchTemplate.setFamilyName("%" + uid + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with user-specified capitalization and first character capitalized.
					searchTemplate.setFamilyName("%" + uid.substring(0, 1).toUpperCase() + uid.substring(1) + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with all lowercase.
					searchTemplate.setFamilyName("%" + uid.toLowerCase() + "%");
					personSet.addAll(personLoader.load(searchTemplate));
					// Search with first character capitalized and the rest lowercase.
					searchTemplate.setFamilyName("%" + uid.substring(0, 1).toUpperCase() + uid.substring(1).toLowerCase() + "%");
					personSet.addAll(personLoader.load(searchTemplate));
				}
				else if(searchCriteria.equals("user")) //search by user name
				{
					// Usernames never have capital letters; make all lowercase.
					searchTemplate.setUserName("%" + uid.toLowerCase() + "%");
					personSet.addAll(personLoader.load(searchTemplate));
				}
			}
		}
	}
	// Create a BbList to work with the set of user objects within the blackboard html framework.
	BbList<User> personList = new BbList<User>();
	personList.addAll(personSet);

	// // remove unavailable accounts from the list
	// personList = personList.getFilteredSubList(new AvailabilityFilter(AvailabilityFilter.AVAILABLE_ONLY));
	// // remove the default Mellon Accounts from the list
	// personList = personList.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Faculty Member", GenericFieldFilter.Comparison.NOT_EQUALS));
	// personList = personList.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Blackboard", GenericFieldFilter.Comparison.NOT_EQUALS));

	//remove users that have opted out
	personList = personList.getFilteredSubList(new GenericFieldFilter("getBusinessFax", User.class, "No", GenericFieldFilter.Comparison.NOT_EQUALS));

	 %>
	<span class="style7"><%=personSet.size()%>
	<%
	 	out.print(" student(s) located.");
	 %><br>
	</span>	<bbUI:list collection="<%=personList%>"
				collectionLabel="Users"
				objectId="user"
				className="User"
				sortUrl="">

		<bbUI:listElement
                width=""
                label="User Information"
                href="">
					<table>
				 	 <tr><td width="70">
						<img src="http://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/<%=user.getUserName()%>/profileImage" name="facPhoto" width="70" onError="imageError(this)">
					</td>
					<td width="200"><span class="style3">
							<%=user.getFamilyName()%>,
							<%	String usersFirstName = user.getGivenName();
							 	if(currentUserPortalRoleId.equals(studentPortalRole.getId()) && searchRole.equals("student") && usersFirstName.contains("("))
								{
									out.print(usersFirstName.substring(0, usersFirstName.indexOf('(') - 1));
								}
								else
								{
									out.print(usersFirstName);
								} %>
					<br><br></span>
					<% if(!user.getUserName().equals(""))
					{
						out.print("Email: " + user.getUserName() + "@oberlin.edu <br><br>");
						out.print("Username: " + user.getUserName());
					} %><br><br>
					<% if((currentUserPortalRoleId.equals(facultyPortalRole.getId()) || currentUserPortalRoleId.equals(staffPortalRole.getId())) && !user.getDepartment().equals("")) //major
					{
						out.print(user.getDepartment());
					} %><br><br>
					</td>
					<td width="200" valign="top">
<%
	if(currentUserPortalRoleId.equals(facultyPortalRole.getId()) || currentUserPortalRoleId.equals(staffPortalRole.getId()))
	{
		for (Course course : CourseDbLoader.Default.getInstance().loadByUserId(user.getId()))
		{ %>
			<%=course.getTitle()%>
			<br>
		<% }
	}
%>


					</td></tr></table>
</bbUI:listElement></bbUI:list>
	<%
}
%>

<script language="JavaScript">
document.getElementById("searchusers").uid.focus();
</script>

</bbUI:docTemplate>
</bbData:context>
