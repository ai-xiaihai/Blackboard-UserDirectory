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

<%!
	// Take in some iterable data structure of PortalRoles and see if any of them return roleName from their getRoleName method.
	// If so, return that PortalRole. If not, return null.
	public PortalRole getPortalRoleByName(Iterable<PortalRole> portalRoles, String roleName)
	{
		for(PortalRole portalRole : portalRoles)
		{
			if(portalRole.getRoleName().equals(roleName))
			{
				return portalRole;
			}
		}
		return null;
	}

	// Comparator class for sorting users based on how closely they match the search term.
	// Tiebreakers are included in an attempt to avoid falsely equating users.
	protected static abstract class NameComparator implements Comparator<User>
	{
		// The term we are comparing each name to; this should just be the search term
		// specified through POST data.
		private String term;

		// Which name should we compare to the search term?
		protected abstract String extractComparisonName(User user);
		// Which names should we use for tiebreakers (in order of descending priority)?
		protected abstract String[] extractTiebreakerNames(User user);

		// Don't want to call toLowerCase() on the search time every time it's used.
		public NameComparator(String term)
		{
			this.term = term.toLowerCase();
		}

		public int compare(User userOne, User userTwo)
		{
			// Compare both names to see which (if either) more closely matches the
			// search term. If one is preferable, return it.
			int result = compare(extractComparisonName(userOne), extractComparisonName(userTwo));
			if(result != 0)
			{
				return result;
			}
			// Iterate over each of the tiebreaker names; if any is more preferable,
			// return it. If not, assume the users are identical (really should not happen).
			String[] tiebreakerNamesOne = extractTiebreakerNames(userOne);
			String[] tiebreakerNamesTwo = extractTiebreakerNames(userTwo);
			for(int i = 0; i < tiebreakerNamesOne.length && i < tiebreakerNamesTwo.length; i++)
			{
				result = tiebreakerNamesOne[i].compareTo(tiebreakerNamesTwo[i]);
				if(result != 0)
				{
					return result;
				}
			}
			return 0;
		}

		private int compare(String nameOne, String nameTwo)
		{
			// If one of the names is identical to the search term but not the other,
			// give it priority. Reverse arguments (nameTwo first, nameOne second)
			// to fit with the Boolean class's compare() method.
			int result = Boolean.compare(nameTwo.equalsIgnoreCase(this.term), nameOne.equalsIgnoreCase(this.term));
			if(result != 0)
			{
				return result;
			}
			// If one of the names begins with the search term but not the other,
			// give it priority.
			result = Boolean.compare(nameTwo.toLowerCase().startsWith(this.term), nameOne.toLowerCase().startsWith(this.term));
			if(result != 0)
			{
				return result;
			}
			// Return a lexicographical comparison of the two names.
			return nameOne.compareTo(nameTwo);
		}
	}

	// Compare last names, break ties with first names and then user names.
	private static class LastNameComparator extends NameComparator
	{
		public LastNameComparator(String term)
		{
			super(term);
		}

		protected String extractComparisonName(User user)
		{
			return user.getFamilyName();
		}

		protected String[] extractTiebreakerNames(User user)
		{
			return new String[] { user.getGivenName(), user.getUserName() };
		}
	}
	// Compare first names, break ties with last names and then user names.
	private static class FirstNameComparator extends NameComparator
	{
		public FirstNameComparator(String term)
		{
			super(term);
		}

		protected String extractComparisonName(User user)
		{
			return user.getGivenName();
		}

		protected String[] extractTiebreakerNames(User user)
		{
			return new String[] { user.getFamilyName(), user.getUserName() };
		}
	}
	// Compare user names, break ties with first names and then last names.
	private static class UserNameComparator extends NameComparator
	{
		public UserNameComparator(String term)
		{
			super(term);
		}

		protected String extractComparisonName(User user)
		{
			return user.getUserName();
		}

		protected String[] extractTiebreakerNames(User user)
		{
			return new String[] { user.getGivenName(), user.getFamilyName() };
		}
	}
%>

<bbData:context id="ctx">
<bbUI:docTemplate title="OCTET User Directory">
<bbUI:breadcrumbBar environment="PORTAL">
 <bbUI:breadcrumb href="https://blackboard.oberlin.edu/">Click here to return to Blackboard</bbUI:breadcrumb>
 <bbUI:breadcrumb>OCTET User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>

<%
/* This is the entry point for the user directory.
 * The user directory allows users in blackboard to search for students, faculty, and staff by last name, first name, and user name.
 * It displays only name, username, email and a photo.
 */

// What text did they ask to search for?
String searchTerm = request.getParameter("searchterm");
if(searchTerm == null)
{
	searchTerm = "";
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

<bbUI:titleBar iconUrl="/images/ci/icons/user_u.gif">OCTET User Directory</bbUI:titleBar>
<form action="userDir.jsp" method="post" id="searchusers">
<span class="style2">
<input name="searchterm" type="text" size="40" value="<%=searchTerm%>">
<bbUI:button type="INLINE" name="search" alt="Search" action="SUBMIT_FORM"></bbUI:button>
<input name="process" type="hidden" id="process" value="1">
<br>
<span class="style1">Search by:
  <label>
  <input type="radio" name="searchcriteria" value="first" <% if(searchCriteria.equals("first")) { out.println("checked"); } %> >
  First Name</label>
  <label>
  <input type="radio" name="searchcriteria" value="last" <% if(searchCriteria.equals("last")) { out.println("checked"); } %> >
  Last Name</label>
  <label>
  <input type="radio" name="searchcriteria" value="user" <% if(searchCriteria.equals("user")) { out.println("checked"); } %> >
  Username</label><br>
</span>
<span class="style1">Search for:
  <label>
  <input type="radio" name="searchrole" value="student" <% if(searchRole.equals("student")) { out.println("checked"); } %> >
  Students</label>
  <label>
  <input type="radio" name="searchrole" value="facultystaff" <% if(searchRole.equals("facultystaff")) { out.println("checked"); } %> >
  Faculty/Staff</label><br>
</span>
</form>
<%
// Determine whether or not they actually specified a search with another variable, since a blank search term is valid.
if(request.getParameter("process") != null)
{
	// Debugging flag.
	final boolean DEBUG = false;

	// Create a persistence manager - needed if we want to use loaders or persisters in blackboard.
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	// Create a portal role loader, for locating and indentifying the portal roles of users.
	PortalRoleDbLoader portalRoleLoader = (PortalRoleDbLoader)bbPm.getLoader(PortalRoleDbLoader.TYPE);
	// Create a user loader, for loading users from the database.
	UserDbLoader userLoader = (UserDbLoader)bbPm.getLoader(UserDbLoader.TYPE);
	// Create a course loader, for loading all the courses a given user is enrolled in.
	CourseDbLoader courseLoader = (CourseDbLoader)bbPm.getLoader(CourseDbLoader.TYPE);

	// Load all portal roles once to avoid redundancy with calls to getPortalRoleByName().
	List<PortalRole> portalRoles = portalRoleLoader.loadAll();
	// Find the student portal role.
	PortalRole studentPortalRole = getPortalRoleByName(portalRoles, "Student");
	// Find the faculty portal role.
	PortalRole facultyPortalRole = getPortalRoleByName(portalRoles, "Faculty");
	// Find the staff portal role.
	PortalRole staffPortalRole = getPortalRoleByName(portalRoles, "Staff");

	// Find out who the user is.
	User currentUser = ctx.getUser();
	// Find the current user's portal role.
	Id currentUserPortalRoleId = currentUser.getPortalRoleId();
	// Should we show them potentially sensitive information?
	// (Only if the current user is a member of staff/faculty.)
	boolean displayPrivilegedInformation = DEBUG || currentUserPortalRoleId.equals(facultyPortalRole.getId()) || currentUserPortalRoleId.equals(staffPortalRole.getId());

	// Guess what the current term is, and store its string representation.
	// The format is <year> + ("09" if the term is fall, "02" if the term is spring).
	Calendar calendar = Calendar.getInstance();
	String year = Integer.toString(calendar.get(Calendar.YEAR));
	String month = calendar.get(Calendar.MONTH) <= 6 ? "02" : "09";
	String currentTermString = year + month;

	// Which portal roles does the user want to see?
	Id validPortalRoleIdOne = null;
	Id validPortalRoleIdTwo = null;
	if(searchRole.equals("student"))
	{
		validPortalRoleIdOne = studentPortalRole.getId();
	}
	else if(searchRole.equals("facultystaff"))
	{
		validPortalRoleIdOne = facultyPortalRole.getId();
		validPortalRoleIdTwo = staffPortalRole.getId();
	}

	// We want a list of unique entries, sorted by how closely they resemble the search term.
	TreeSet<User> userSet;

	// Create a UserSearch object, for use with the UserDbLoader's loadByUserSearch() method.
	UserSearch userSearch = new UserSearch();
	// Don't show disabled users.
	userSearch.setOnlyShowEnabled(true);
	// Instantiate the set of users with the appropriate comparator, set up the parameters
	// for the search, and then load users based on the search into our set.
	if(searchCriteria.equals("first"))
	{
		userSet = new TreeSet(new FirstNameComparator(searchTerm));
		userSearch.setNameParameter(UserSearch.SearchKey.GivenName, SearchOperator.Contains, searchTerm);
		userSet.addAll(userLoader.loadByUserSearch(userSearch));
	}
	else if(searchCriteria.equals("last"))
	{
		userSet = new TreeSet(new LastNameComparator(searchTerm));
		userSearch.setNameParameter(UserSearch.SearchKey.FamilyName, SearchOperator.Contains, searchTerm);
		userSet.addAll(userLoader.loadByUserSearch(userSearch));
	}
	else if(searchCriteria.equals("user"))
	{
		userSet = new TreeSet(new UserNameComparator(searchTerm));
		userSearch.setNameParameter(UserSearch.SearchKey.UserName, SearchOperator.Contains, searchTerm);
		userSet.addAll(userLoader.loadByUserSearch(userSearch));
	}
	else
	{
		// Make the compiler happy.
		userSet = null;
	}
	// Create a BbList to interact with BlackBoard's HTML framework.
	BbList<User> userList = new BbList<User>();

	String userName;
	// Iterate over every user we've found.
	for(User user : userSet)
	{
		// Skip them if they're unavailable.
		if(user.getIsAvailable())
		{
			// Find out what kind of user (student, faculty, administrator, etc.) they are.
			Id userPortalRoleId = portalRoleLoader.loadPrimaryRoleByUserId(user.getId()).getId();
			// Skip them if they aren't what the user has asked for.
			if(userPortalRoleId.equals(validPortalRoleIdOne) || userPortalRoleId.equals(validPortalRoleIdTwo))
			{
				// Unless a member of faculty/staff is performing the search, filter out
				// name matches based on legal names instead of preferred names.
				if(searchCriteria.equals("first") && !displayPrivilegedInformation && (userName = user.getGivenName()).contains("("))
				{
					String preferredName = userName.substring(0, userName.indexOf('(') - 1).toLowerCase();
					if(!preferredName.contains(searchTerm.toLowerCase()))
					{
						continue;
					}
				}
				// Add the user to our BbList!
				userList.add(userLoader.loadById(user.getId()));
			}
		}
	}

	// Not sure this is relevant anymore... if so, it can probably be re-implemented in the body
	// of the for-loop above.
	// // Remove users that have opted out
	// personList = personList.getFilteredSubList(new GenericFieldFilter("getBusinessFax", User.class, "No", GenericFieldFilter.Comparison.NOT_EQUALS));
	%>
	<span class="style7">
	<%
	out.println(userList.size());
	if(searchRole.equals("student"))
	{
		out.println("student(s)");
	}
	else if(searchRole.equals("facultystaff"))
	{
		out.println("faculty/staff");
	}
	%> located.<br>
	</span>	<bbUI:list collection="<%=userList%>"
				collectionLabel="Users"
				objectId="user"
				className="User"
				sortUrl="">

		<bbUI:listElement
                width=""
                label="User Information"
                href="">
					<table>
				 	 <tr><td width="70" valign="middle">
						<img src="http://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/<%=user.getUserName()%>/profileImage" name="facPhoto" width="70" onError="imageError(this)">
					</td>
					<td width="200" valign="middle"><span class="style3">
					<%
						out.println(user.getFamilyName() + ", ");
						String userFirstName = user.getGivenName();
						if(!displayPrivilegedInformation && searchRole.equals("student") && userFirstName.contains("("))
						{
							out.print(userFirstName.substring(0, userFirstName.indexOf('(') - 1));
						}
						else
						{
							out.print(userFirstName);
						}
						String userUserName = user.getUserName();
					%>
					<br><br></span>
					Email: <%=userUserName%>@oberlin.edu <br><br>
					Username: <%=userUserName%>
					</td>
					<td width="200" valign="middle">
					<% String userDepartment = user.getDepartment();
					// If the user is a student, this should be their major.
					// If not, it should be their department.
					if(searchRole.equals("student") && displayPrivilegedInformation)
					{
						if(!userDepartment.isEmpty())
						{
							if(userDepartment.charAt(0) == '"')
							{
								userDepartment = userDepartment.substring(1);
							}
							if(userDepartment.length() > 8)
							{
								userDepartment = userDepartment.substring(8);
							}
						}
						else
						{
							userDepartment = "None listed";
						}
						out.print("Major(s): " + userDepartment);
					}
					else if(searchRole.equals("facultystaff"))
					{
						if(userDepartment.isEmpty())
						{
							userDepartment = "None listed";
						}
						out.println("Department: " + userDepartment);
					}
					out.println("<br><br>");

					if(DEBUG && searchRole.equals("facultystaff"))
					{ %>
						<form action="https://conevals.csr.oberlin.edu/view.php" method="post" id="appointment_form<%=user.getUserName()%>">
							<input type="hidden" name="username" value="<%=currentUser.getUserName()%>">
							<input type="hidden" name="instructor" value="<%=user.getUserName()%>">
							<input type="hidden" name="name" value="">
							<input type="hidden" name="email" value="">
							<input type="hidden" name="course_id" value="">
							<input type="hidden" name="course_cid" value="">
							<input type="hidden" name="course_name" value="">
							<a href="javascript:{}" onclick="document.getElementById('appointment_form<%=user.getUserName()%>').submit();">Click here</a> to schedule an appointment with this instructor.
						</form>
					<% }
					else if(searchRole.equals("student") && displayPrivilegedInformation)
					{
						String userDean = user.getStudentId();
						out.println("Class dean:");
						if(!userDean.isEmpty())
						{
							out.println(userDean.substring(3));
						}
						else
						{
							out.println("None listed");
						}
						out.println("<br><br>");

						List<Course> userOrganizations = courseLoader.loadByUserId(user.getId());
						List<String> userCourses = new ArrayList<String>();
						List<String> userAdvisors = new ArrayList<String>();
						if(!userOrganizations.isEmpty())
						{
							for(Course organization : userOrganizations)
							{
								String organizationTitle = organization.getTitle();
								if(organizationTitle.length() >= 7 && organizationTitle.substring(0, 7).equals(currentTermString + " "))
								{
									userCourses.add(organizationTitle.substring(7));
								}
								else if(organizationTitle.length() >= 11 && organizationTitle.substring(0, 11).equals("Advising - "))
								{
									userAdvisors.add(organizationTitle.substring(11));
								}
							}
						}

						out.println("Advisor(s):");
						if(!userAdvisors.isEmpty())
						{
							for(int i = 0; i < userAdvisors.size() - 1; i++)
							{
								out.println(userAdvisors.get(i) + ", ");
							}
							out.println(userAdvisors.get(userAdvisors.size() - 1));
						}
						else
						{
							out.println("None listed");
						}

						%> <td valign="top"> <%

						out.println("<br>Course(s):");
						if(!userCourses.isEmpty())
						{
							for(String courseName : userCourses)
							{
								out.println("<br>&emsp;&emsp;" + courseName);
							}
						}
						else
						{
							out.println("None listed");
						}
					} %>
</td></tr></table>
</bbUI:listElement></bbUI:list>
<%
}
%>

<script language="JavaScript">
document.getElementById("searchusers").searchterm.focus();
</script>

</bbUI:docTemplate>
</bbData:context>
