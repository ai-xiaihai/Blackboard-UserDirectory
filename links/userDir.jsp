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
<head>
<script>
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
	function mouseOutImage(image, newImage)
	{
		image.src = newImage;
	}

	function mouseOverAudio(user)
	{
		document.getElementById(user + '_audio').play();
	}
	function mouseOutAudio(user)
	{
		document.getElementById(user + '_audio').pause();
	}

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
</script>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<link rel="stylesheet" type="text/css" href="dept_css.css">
</head>

<%!
	// Take in some iterable data structure of PortalRoles and see if any of them return roleName from their getRoleName method.
	// If so, return that PortalRole. If not, return null.
	public static PortalRole getPortalRoleByName(Iterable<PortalRole> portalRoles, String roleName)
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

	// Take in some string, and remove leading and trailing double-quote characters.
	public static String trimQuotes(String string)
	{
		int begin = 0;
		while(begin < string.length() && string.charAt(begin) == '"')
			begin++;
		string = string.substring(begin);

		int end = string.length() - 1;
		if(end >= 0 && string.charAt(end) == '"')
		{
			while(end >= 0 && string.charAt(end) == '"')
			{
				end--;
			}
			string = string.substring(0, end + 1);
		}

		return string;
	}

	// Take in some string, surround it with double quotes, and return it.
	// Useful for improving readability with html attributes.
	public static String doubleQuote(String string)
	{
		return "\"" + string + "\"";
	}

	// Take in some string, surround it with single quotes, and return it.
	// Useful for improving readability with JS code.
	public static String singleQuote(String string)
	{
		return "'" + string + "'";
	}

	// Marginally better than hard-coding.
	public static String getUserPicture(String userName)
	{
		return "http://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/" + userName + "/profileImage";
	}

	// If the user has a preferred name, their first (given) name will be in the format
	// "preferred (given)".
	// Take in some first name, and if there is a preferred and given name in there,
	// return only the preferred name. If there is not, return the name unchanged.
	public static String getPreferredName(String firstName)
	{
		int parenthesisIndex = firstName.indexOf('(');
		if(parenthesisIndex != -1)
		{
			return firstName.substring(0, parenthesisIndex - 1);
		}
		else
		{
			return firstName;
		}
	}

	// For the lulz.
	// Mappings are username : image URL.
	public static HashMap<String, String> getImageEasterEggs(long pokemon)
	{
		HashMap<String, String> result = new HashMap<String, String>();
		String imageFolder = "https://oberlintest.blackboard.com" + PlugInUtil.getUri("octt", "octetuserd", "images/");

		if(Math.random() >= 0.99)
			pokemon += 151;

		result.put("cegerton",	imageFolder + "eduard.jpg");
		result.put("mkrislov",	imageFolder + "marvin.jpg");
		result.put("cmohler",	imageFolder + "batman.jpg");
		result.put("bkuperma",	imageFolder + "superman.jpg");
		result.put("mcohn2",	imageFolder + "maury.gif");
		result.put("ayang",		imageFolder + "Pokemon/" + String.valueOf(pokemon) + ".png");

		return result;
	}

	// Mappings are username : audio easter egg
	public static HashMap<String, AudioEasterEgg> getAudioEasterEggs(long pokemon)
	{
		HashMap<String, AudioEasterEgg> result = new HashMap<String, AudioEasterEgg>();
		String audioFolder = "https://oberlintest.blackboard.com" + PlugInUtil.getUri("octt", "octetuserd", "audio/");

		result.put("cegerton",	new AudioEasterEgg("cegerton", audioFolder + "trololololol", true, true));
		result.put("ldaligau",	new AudioEasterEgg("ldaligau", audioFolder + "rickroll", true, true));
		result.put("cmohler",	new AudioEasterEgg("cmohler", audioFolder + "batman", true, true));
		result.put("bkuperma",	new AudioEasterEgg("bkuperma", audioFolder + "superman", true, true));
		result.put("ayang",		new AudioEasterEgg("ayang", audioFolder + "Pokemon/" + String.valueOf(pokemon), false, false));

		return result;
	}

	public static class AudioEasterEgg
	{
		private String username;
		private String filename;
		private boolean loop;
		private boolean stopOnMouseExit;

		public AudioEasterEgg(String username, String filename, boolean loop, boolean stopOnMouseExit)
		{
			this.username = username;
			this.filename = filename;
			this.loop = loop;
			this.stopOnMouseExit = stopOnMouseExit;
		}

		public String getAnchorCode()
		{
			String result = "<audio id=" + doubleQuote(username + "_audio") + " preload=" + doubleQuote("auto");
			if(loop)
				result += " loop";
			result += " >\n";
			result += "\t<source src=" + doubleQuote(filename + ".mp3") + " type=" + doubleQuote("audio/mpeg") + " />\n";
			result += "\t<source src=" + doubleQuote(filename + ".ogg") + " type=" + doubleQuote("audio/ogg") + " />\n";
			result += "</audio>";
			return result;
		}

		public boolean stopOnMouseExit()
		{
			return stopOnMouseExit;
		}
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
		private boolean useBothNames;
		public FirstNameComparator(String term, boolean useBothNames)
		{
			super(term);
			this.useBothNames = useBothNames;
		}

		protected String extractComparisonName(User user)
		{
			if(useBothNames)
			{
				return user.getGivenName();
			}
			else
			{
				return getPreferredName(user.getGivenName());
			}
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

	public static String imageEasterEggCode(String imageEasterEgg)
	{
		String result = "<div class=" + doubleQuote("preload") + ">\n";
		result += "\t<img src=" + doubleQuote(imageEasterEgg) + " />\n";
		result += "</div>";
		return result;
	}

	// The body of the <bbUI:list> tag became rather messy. The next few functions should help mitigate that.

	public static String userImageCode(User user, HashMap<String, String> imageEasterEggs, HashMap<String, AudioEasterEgg> audioEasterEggs)
	{
		String userName = user.getUserName();
		String userPicture = getUserPicture(userName);
		String result = "<td width=" + doubleQuote("100") + " valign=" + doubleQuote("middle") + ">\n";
		result += "\t<img src=" + doubleQuote(userPicture) + " width=" + doubleQuote("100");
		String imageEasterEgg = imageEasterEggs.get(userName);
		AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
		if(imageEasterEgg != null && audioEasterEgg != null)
		{
			result += " onMouseOver=" + doubleQuote("mouseOverBoth(this, " + singleQuote(imageEasterEgg) + ", " + singleQuote(userName) + ")");
			if(audioEasterEgg.stopOnMouseExit())
				result += " onMouseOut=" + doubleQuote("mouseOutBoth(this, " + singleQuote(userPicture) + ", " + singleQuote(userName) + ")");
			else
				result += " onMouseOut=" + doubleQuote("mouseOutImage(this, " + singleQuote(userPicture) + ")");
		}
		else if(imageEasterEgg != null)
		{
			result += " onMouseOver=" + doubleQuote("mouseOverImage(this, " + singleQuote(imageEasterEgg) + ")");
			result += " onMouseOut=" + doubleQuote("mouseOutImage(this, " + singleQuote(userPicture) + ")");
		}
		else if(audioEasterEgg != null)
		{
			result += " onMouseOver=" + doubleQuote("mouseOverAudio(" + singleQuote(userName) + ")");
			if(audioEasterEgg.stopOnMouseExit())
				result += " onMouseOut=" + doubleQuote("mouseOutAudio(" + singleQuote(userName) + ")");
		}
		result += " />\n";
		result += "</td>";
		return result;
	}

	// public static String userFirstColumnCode(User user, String searchRole, boolean displayPrivilegedInformation)
	// {
	// 	String result = "<td width=" + doubleQuote("200") + " valign=" + doubleQuote("middle") + ">\n";
	// 	String userLastName = user.getFamilyName();
	// 	String userFirstName = displayPrivilegedInformation ? user.getGivenName() : getPreferredName(user.getGivenName());
	// 	result += "\t" + userLastName + ", " + userFirstName +
	// 	result += "</td>";
	// 	return result;
	// }
%>

<%-- <span class="style3">
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
%></span>
<%	if(searchRole.equals("facultystaff"))
	{
		String userTitle = user.getCompany();
		if(!userTitle.isEmpty())
		{
			out.println("<br>" + trimQuotes(userTitle));
		}
	}
	String userUserName = user.getUserName();
%>
<br><br>
Email: <%=userUserName%>@oberlin.edu
<br><br>
<%
	String userWebPage = user.getWebPage();
	out.print("Website: ");
	if(userWebPage.isEmpty())
	{
		out.println("None listed");
	}
	else
	{ %>
		<a href="<%=userWebPage%>"><%=userWebPage%></a>
	<% }
%> --%>

<bbData:context id="ctx">
<bbUI:docTemplate title="OCTET User Directory">
<bbUI:breadcrumbBar environment="PORTAL">
 <bbUI:breadcrumb href="https://blackboard.oberlin.edu/">Click here to return to Blackboard</bbUI:breadcrumb>
 <bbUI:breadcrumb>OCTET User Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>

<%
/* This is the entry point for the user directory.
 * The user directory allows users in blackboard to search for students, faculty, and staff by last name, first name, and user name.
 * If a student searches for other students, only names, emails, and photos are displayed.
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
	// Debugging flag for simulating the view of faculty/staff
	final boolean DEBUG = true;
	// Appointment tool
	final boolean APPOINTMENTS = false;

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
	TreeSet<User> userSet = null;

	// Create a UserSearch object, for use with the UserDbLoader's loadByUserSearch() method.
	UserSearch userSearch = new UserSearch();
	// Don't show disabled users.
	userSearch.setOnlyShowEnabled(true);
	// Instantiate the set of users with the appropriate comparator, set up the parameters
	// for the search, and then load users based on the search into our set.
	if(searchCriteria.equals("first"))
	{
		userSet = new TreeSet(new FirstNameComparator(searchTerm, displayPrivilegedInformation));
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
		if(searchTerm.length() > 8)
		{
			searchTerm = searchTerm.substring(0, 8);
		}
		userSet = new TreeSet(new UserNameComparator(searchTerm));
		userSearch.setNameParameter(UserSearch.SearchKey.UserName, SearchOperator.Contains, searchTerm);
		userSet.addAll(userLoader.loadByUserSearch(userSearch));
	}

	// Teehee
	long pokemon = (System.currentTimeMillis() % 151) + 1;
	HashMap<String, String> imageEasterEggs = getImageEasterEggs(pokemon);
	HashMap<String, AudioEasterEgg> audioEasterEggs = getAudioEasterEggs(pokemon);
	boolean easterEggs = false;

	if(userSet.isEmpty() && searchTerm.equals("8D"))
	{
		// This will find more than one kind of user; best to keep things simple and display the least information.
		searchRole = "student";
		displayPrivilegedInformation = false;
		easterEggs = true;
		Set<String> easterEggNames = new HashSet<String>();
		easterEggNames.addAll(imageEasterEggs.keySet());
		easterEggNames.addAll(audioEasterEggs.keySet());
		for(String name : easterEggNames)
		{
			userSet.add(userLoader.loadByUserName(name));
		}
	}

	// Create a BbList to interact with BlackBoard's HTML framework.
	BbList<User> userList = new BbList<User>();

	// Iterate over every user we've found.
	for(User user : userSet)
	{
		String userName = user.getUserName();
		// Skip them if they're a preview user or unavailable.
		if(user.getIsAvailable() && !userName.contains("previewuser"))
		{
			// Find out what kind of user (student, faculty, administrator, etc.) they are.
			Id userPortalRoleId = portalRoleLoader.loadPrimaryRoleByUserId(user.getId()).getId();
			// Skip them if they aren't what the user has asked for.
			if(easterEggs || userPortalRoleId.equals(validPortalRoleIdOne) || userPortalRoleId.equals(validPortalRoleIdTwo))
			{
				// Unless a member of faculty/staff is performing the search, filter out
				// name matches based on legal names instead of preferred names.
				if(!easterEggs && searchCriteria.equals("first") && !displayPrivilegedInformation && !getPreferredName(user.getGivenName()).toLowerCase().contains(searchTerm.toLowerCase()))
				{
					continue;
				}
				// Add the user to our BbList!
				userList.add(userLoader.loadById(user.getId()));
				// Create the hidden audio elements for anyone who gets one.
				AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
				if(audioEasterEgg != null)
				{
					out.println(audioEasterEgg.getAnchorCode());
				}
				// Preload alternate images so there's no delay on the first mouseover.
				String imageEasterEgg = imageEasterEggs.get(userName);
				if(imageEasterEgg != null)
				{
					out.println(imageEasterEggCode(imageEasterEgg));
				}
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
	if(easterEggs)
	{
		out.println("user(s)");
	}
	else if(searchRole.equals("student"))
	{
		out.println("student(s)");
	}
	else if(searchRole.equals("facultystaff"))
	{
		out.println("faculty/staff");
	}
	%> located.<br>
	</span>
	<bbUI:list collection="<%=userList%>" collectionLabel="Users" objectId="user" className="User" sortUrl="">
		<bbUI:listElement width="" label="User Information" href="">
			<table><tr>
				<%=userImageCode(user, imageEasterEggs, audioEasterEggs)%>
				<td width="200" valign="middle">
				<span class="style3">
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
				%></span>
				<%	if(searchRole.equals("facultystaff"))
					{
						String userTitle = user.getCompany();
						if(!userTitle.isEmpty())
						{
							out.println("<br>" + trimQuotes(userTitle));
						}
					}
					String userUserName = user.getUserName();
				%>
				<br><br>
				Email: <%=userUserName%>@oberlin.edu
				<br><br>
				<%
					String userWebPage = user.getWebPage();
					out.print("Website: ");
					if(userWebPage.isEmpty())
					{
						out.println("None listed");
					}
					else
					{ %>
						<a href="<%=userWebPage%>"><%=userWebPage%></a>
					<% }
				%>
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
					out.print("Major(s): " + trimQuotes(userDepartment));
				}
				else if(searchRole.equals("facultystaff"))
				{
					if(userDepartment.length() > 5 && userDepartment.substring(0, 5).equals("DEPT-"))
					{
						userDepartment = userDepartment.substring(5);
					}
					if(userDepartment.isEmpty())
					{
						userDepartment = "None listed";
					}
					out.println("Department: " + trimQuotes(userDepartment));
				}
				out.println("<br><br>");

				if(searchRole.equals("facultystaff"))
				{
					String userOffice = user.getJobTitle();
					out.println("Office location: ");
					if(!userOffice.isEmpty())
					{
						out.println(trimQuotes(userOffice));
					}
					else
					{
						out.println("None listed");
					}
					out.println("<br><br>");
					String userPhone = user.getBusinessPhone1();
					out.println("Phone number: ");
					if(!userPhone.isEmpty())
					{
						out.println(trimQuotes(userPhone));
					}
					else
					{
						out.println("None listed");
					}

					if(APPOINTMENTS)
					{ %>
						<br><br>
						<form action="https://conevals.csr.oberlin.edu/view.php" method="post" id="appointment_form<%=userUserName%>">
							<input type="hidden" name="username" value="<%=currentUser.getUserName()%>">
							<input type="hidden" name="instructor" value="<%=userUserName%>">
							<input type="hidden" name="name" value="">
							<input type="hidden" name="email" value="">
							<input type="hidden" name="course_id" value="">
							<input type="hidden" name="course_cid" value="">
							<input type="hidden" name="course_name" value="">
							<a href="javascript:{}" onclick="document.getElementById('appointment_form<%=userUserName%>').submit();">Click here</a> to schedule an appointment with this instructor.
						</form>
					<% }
				}
				else if(searchRole.equals("student") && displayPrivilegedInformation)
				{
					String userDean = user.getStudentId();
					String userYear = "None listed";
					out.println("Class dean:");
					if(userDean.length() >= 3)
					{
						out.println(userDean.substring(3));
						switch(userDean.substring(0, 2))
						{
							case "FR":
								userYear = "Freshman";
								break;
							case "SO":
								userYear = "Sophomore";
								break;
							case "JR":
								userYear = "Junior";
								break;
							case "SR":
								userYear = "Senior";
								break;
							case "5Y":
								userYear = "Fifth year";
								break;
							default:
								userYear = userDean.substring(0, 2);
								break;
						}
					}
					else
					{
						out.println("None listed");
					}
					out.println("<br><br>Year: " + userYear);
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
							out.println(trimQuotes(userAdvisors.get(i)) + ", ");
						}
						out.println(trimQuotes(userAdvisors.get(userAdvisors.size() - 1)));
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
							out.println("<br>&emsp;&emsp;" + trimQuotes(courseName));
						}
					}
					else
					{
						out.println("None listed");
					}
				} %>
				</td>
			</tr></table>
		</bbUI:listElement>
	</bbUI:list>
<% } %>

<script language="JavaScript">
document.getElementById("searchusers").searchterm.focus();
</script>

</bbUI:docTemplate>
</bbData:context>
