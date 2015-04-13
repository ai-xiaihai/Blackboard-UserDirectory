<%@ page import="java.util.*,
                 java.net.URL,
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

<%
// Debugging flag for simulating the view of faculty/staff
final boolean DEBUG = true;
// Appointment tool
final boolean APPOINTMENTS = false;
// See all the easter eggs at once
final String EASTER_EGG_PHRASE = "happy fun times";
// Number of people per page
final int PAGE_SIZE = 10;

// What text did they ask to search for?
String searchTerm = request.getParameter("searchterm");
if(searchTerm == null) return;

// How do they want to search--first name, last name, or user name?
String searchCriteria = request.getParameter("searchcriteria");
if(searchCriteria == null) return;

// What kind of user are they searching for--student, faculty, or staff?
String searchRole = request.getParameter("searchrole");
if(searchRole == null) return;

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
// Should we show them potentially sensitive information?
boolean displayPrivilegedInformation = DEBUG;
// Make sure they're logged in.
if(!ctx.getSession().isAuthenticated() ||
    currentUserPortalRoleId.equals(guestPortalRole.getId()))
{
    out.print("<div>You must be logged in to use this tool.</div>");
    return;
}
// If they are a member of faculty or staff, we show them more.
else if(currentUserPortalRoleId.equals(facultyPortalRole.getId()) ||
        currentUserPortalRoleId.equals(staffPortalRole.getId()))
{
    displayPrivilegedInformation = true;
}
// If they are not a student, alumnus, or faculty/emeriti, block access.
else if(!(currentUserPortalRoleId.equals(studentPortalRole.getId()) ||
          currentUserPortalRoleId.equals(emeritiPortalRole.getId()) ||
          currentUserPortalRoleId.equals(alumniPortalRole.getId())  ||
          currentUserPortalRoleId.equals(nonObiePortalRole.getId())))
{
    out.print("<div>In order to use this tool, you must be a student, alumnus, staff member, emeritus, or faculty member.</div>");
    return;
}
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

// Take in some string, and remove leading and trailing double-quote characters.
public static String trimQuotes(String string)
{
    int begin = 0;
    while(begin < string.length() && string.charAt(begin) == '"') begin++;
    string = string.substring(begin);
    int end = string.length() - 1;
    if(end >= 0 && string.charAt(end) == '"')
    {
        while(end >= 0 && string.charAt(end) == '"') end--;
        string = string.substring(0, end + 1);
    }
    return string;
}

// Take in some string, surround it with double quotes, and return it.
// Useful for improving readability with html attributes.
public static String doubleQuote(String string) { return "\"" + string + "\""; }

// Take in some string, surround it with single quotes, and return it.
// Useful for improving readability with JS code.
public static String singleQuote(String string) { return "'" + string + "'"; }

// Marginally better than hard-coding.
public static String getUserPicture(String userName)
{
    return "https://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/" + userName + "/profileImage";
}

// If the user has a preferred name, their first (given) name will be in the format
// "preferred (given)".
// Take in some first name, and if there is a preferred and given name in there,
// return only the preferred name. If there is not, return the name unchanged.
public static String getPreferredName(String firstName)
{
    int parenthesisIndex = firstName.indexOf('(');
    if(parenthesisIndex != -1) return firstName.substring(0, parenthesisIndex - 1);
    else return firstName;
}

/* For the lulz. */

// Mappings are username : image URL.
public static HashMap<String, String> getImageEasterEggs()
{
    try
    {
        HashMap<String, String> result = new HashMap<String, String>();
        URL fileURL = new URL("https://occs.cs.oberlin.edu/~cegerton/hfti.php");
        Scanner fileReader = new Scanner(fileURL.openStream());

        while(fileReader.hasNext())
            result.put(fileReader.next(), fileReader.next());

        fileReader.close();
        return result;
    }
    catch(Exception e)
    {
        return new HashMap<String, String>();
    }
}

// Mappings are username : audio easter egg
public static HashMap<String, AudioEasterEgg> getAudioEasterEggs()
{
    try
    {
        HashMap<String, AudioEasterEgg> result = new HashMap<String, AudioEasterEgg>();
        URL fileURL = new URL("https://occs.cs.oberlin.edu/~cegerton/hfta.php");
        Scanner fileReader = new Scanner(fileURL.openStream());

        String userName;
        while(fileReader.hasNext())
        {
            userName = fileReader.next();
            result.put(userName, new AudioEasterEgg(userName, fileReader.next(), fileReader.nextBoolean(), fileReader.nextBoolean()));
        }

        fileReader.close();
        return result;
    }
    catch(Exception e)
    {
        return new HashMap<String, AudioEasterEgg>();
    }
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

    public boolean stopOnMouseExit() { return stopOnMouseExit; }
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
    public NameComparator(String term) { this.term = term.toLowerCase(); }

    public int compare(User userOne, User userTwo)
    {
        // Compare both names to see which (if either) more closely matches the
        // search term. If one is preferable, return it.
        int result = compare(extractComparisonName(userOne), extractComparisonName(userTwo));
        if(result != 0) return result;
        // Iterate over each of the tiebreaker names; if any is more preferable,
        // return it. If not, assume the users are identical (really should not happen).
        String[] tiebreakerNamesOne = extractTiebreakerNames(userOne);
        String[] tiebreakerNamesTwo = extractTiebreakerNames(userTwo);
        for(int i = 0; i < tiebreakerNamesOne.length && i < tiebreakerNamesTwo.length; i++)
            if((result = tiebreakerNamesOne[i].compareTo(tiebreakerNamesTwo[i])) != 0) return result;
        return 0;
    }

    private int compare(String nameOne, String nameTwo)
    {
        // If one of the names is identical to the search term but not the other,
        // give it priority. Reverse arguments (nameTwo first, nameOne second)
        // to fit with the Boolean class's compare() method.
        int result = Boolean.compare(nameTwo.equalsIgnoreCase(this.term), nameOne.equalsIgnoreCase(this.term));
        if(result != 0) return result;
        // If one of the names begins with the search term but not the other,
        // give it priority.
        result = Boolean.compare(nameTwo.toLowerCase().startsWith(this.term), nameOne.toLowerCase().startsWith(this.term));
        if(result != 0) return result;
        // Return a lexicographical comparison of the two names.
        return nameOne.compareTo(nameTwo);
    }
}

// Compare last names, break ties with first names and then user names.
private static class LastNameComparator extends NameComparator
{
    public LastNameComparator(String term) { super(term); }
    protected String extractComparisonName(User user) { return user.getFamilyName(); }
    protected String[] extractTiebreakerNames(User user) { return new String[] { user.getGivenName(), user.getUserName() }; }
}
// Compare first names, break ties with last names and then user names.
private static class FirstNameComparator extends NameComparator
{
    private boolean useBothNames;
    public FirstNameComparator(String term, boolean useBothNames) { super(term); this.useBothNames = useBothNames; }
    protected String extractComparisonName(User user)
    {
        if(useBothNames) return user.getGivenName();
        else return getPreferredName(user.getGivenName());
    }
    protected String[] extractTiebreakerNames(User user) { return new String[] { user.getFamilyName(), user.getUserName() }; }
}
// Compare user names, break ties with first names and then last names.
private static class UserNameComparator extends NameComparator
{
    public UserNameComparator(String term) { super(term); }
    protected String extractComparisonName(User user) { return user.getUserName(); }
    protected String[] extractTiebreakerNames(User user) { return new String[] { user.getGivenName(), user.getFamilyName() }; }
}

public static String imageEasterEggCode(String imageEasterEgg)
{
    String result = "<div class=" + doubleQuote("preload") + ">\n";
    result += "\t<img src=" + doubleQuote(imageEasterEgg) + " />\n";
    result += "</div>";
    return result;
}

// The body of the <bbUI:list> tag became rather messy. The next function(s) should help mitigate that.
public static String userImageCode(User user, HashMap<String, String> imageEasterEggs, HashMap<String, AudioEasterEgg> audioEasterEggs)
{
    String userName = user.getUserName();
    String userPicture = getUserPicture(userName);
    String result = "<td width=" + doubleQuote("110") + " valign=" + doubleQuote("middle") + ">\n";
    result += "\t<img src=" + doubleQuote(userPicture) + " width=" + doubleQuote("100") + " onerror=" + doubleQuote("imageError(this)");
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

<%
// Create a user loader, for loading users from the database.
UserDbLoader userLoader = (UserDbLoader)bbPm.getLoader(UserDbLoader.TYPE);
// Create a course loader, for loading all the courses a given user is enrolled in.
CourseDbLoader courseLoader = (CourseDbLoader)bbPm.getLoader(CourseDbLoader.TYPE);

// Guess what the current term is, and store its string representation.
// The format is <year> + ("09" if the term is fall, "02" if the term is spring).
Calendar calendar = Calendar.getInstance();
String year = Integer.toString(calendar.get(Calendar.YEAR));
String month = calendar.get(Calendar.MONTH) <= 6 ? "02" : "09";
String currentTermString = year + month;

// Which portal roles does the user want to see?
Id validPortalRoleId = null;
if(searchRole.equals("student"))
    validPortalRoleId = studentPortalRole.getId();
else if(searchRole.equals("faculty"))
    validPortalRoleId = facultyPortalRole.getId();
else if(searchRole.equals("staff"))
    validPortalRoleId = staffPortalRole.getId();

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
        userSet = new TreeSet(new UserNameComparator(searchTerm.substring(0, 8)));
    else
        userSet = new TreeSet(new UserNameComparator(searchTerm));
    userSearch.setNameParameter(UserSearch.SearchKey.UserName, SearchOperator.Contains, searchTerm);
    userSet.addAll(userLoader.loadByUserSearch(userSearch));
}

// Teehee
HashMap<String, AudioEasterEgg> audioEasterEggs = getAudioEasterEggs();
HashMap<String, String> imageEasterEggs = getImageEasterEggs();
boolean easterEggs = false;

if(userSet.isEmpty() && searchTerm.equalsIgnoreCase(EASTER_EGG_PHRASE))
{
    // This will find more than one kind of user; best to keep things simple and display the least information.
    searchRole = "student";
    displayPrivilegedInformation = false;
    easterEggs = true;
    Set<String> easterEggNames = new HashSet<String>();
    easterEggNames.addAll(imageEasterEggs.keySet());
    easterEggNames.addAll(audioEasterEggs.keySet());
    for(String name : easterEggNames)
        userSet.add(userLoader.loadByUserName(name));
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
        if(easterEggs || userPortalRoleId.equals(validPortalRoleId))
        {
            // Unless a member of faculty/staff is performing the search, filter out
            // name matches based on legal names instead of preferred names.
            if(!easterEggs &&
                searchCriteria.equals("first") &&
                !displayPrivilegedInformation &&
                !getPreferredName(user.getGivenName()).toLowerCase().contains(searchTerm.toLowerCase()))
            {
                continue;
            }
            // Add the user to our BbList.
            userList.add(userLoader.loadById(user.getId()));

            // Create the hidden audio elements for anyone who gets one.
            AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
            if(audioEasterEgg != null) out.print(audioEasterEgg.getAnchorCode());

            // Preload alternate images so there's no delay on the first mouseover.
            String imageEasterEgg = imageEasterEggs.get(userName);
            if(imageEasterEgg != null) out.print(imageEasterEggCode(imageEasterEgg));
        }
    }
} %>

<span class="style7">
<% out.print(userList.size());
if(easterEggs)
    out.print(" user(s)");
else if(searchRole.equals("student"))
    out.print(" student(s)");
else if(searchRole.equals("faculty"))
    out.print(" faculty");
else if(searchRole.equals("staff"))
    out.print(" staff");
%> located.
</span>
<span class="pagenumber">
    <button id="prevpagebutton" onclick="prevPage();" class="pagedirectionbutton" disabled>Prev</button>
    <span class="style7">Page <span id="currentpage">1</span> of <%=(userList.size() / PAGE_SIZE) + 1%></span>
    <button id="nextpagebutton" onclick="nextPage();" class="pagedirectionbutton">Next</button>
</span>
<br /><br />

<% if(userList.size() == 0)
{ %>
    <div id="resultspage1" class="resultspage" hidden></div>
    <button id="buttonpage1" class="pagenumberbutton" hidden></button>
<% }

for(int pageIndex = 0; pageIndex * PAGE_SIZE < userList.size(); pageIndex++)
{ %>
    <div id="resultspage<%=pageIndex + 1%>" class="resultspage">
    <% for(int userIndex = pageIndex * PAGE_SIZE; userIndex < (pageIndex + 1) * PAGE_SIZE && userIndex < userList.size(); userIndex++)
    {
        User user = userList.get(userIndex);
        %>
        <table class="resultstable"><tr>
            <%=userImageCode(user, imageEasterEggs, audioEasterEggs)%>
            <td width="200" valign="middle">
            <span class="userfullname">
            <%
                out.print(user.getFamilyName() + ", ");
                String userFirstName = user.getGivenName();
                if(!displayPrivilegedInformation && searchRole.equals("student"))
                    out.print(getPreferredName(userFirstName));
                else
                    out.print(userFirstName);
            %></span>
            <%	if(searchRole.equals("faculty") || searchRole.equals("staff"))
                {
                    String userTitle = user.getCompany();
                    if(!userTitle.isEmpty())
                    { %>
                        <br><span class="positiontitle"><%=trimQuotes(userTitle)%></span>
                    <% }
                }
                String userUserName = user.getUserName();
            %>
            <br><br>
            Email: <%=userUserName%>@oberlin.edu
            <%  if(searchRole.equals("student") && displayPrivilegedInformation)
                {
                    String userMailbox = user.getJobTitle();
                    if(userMailbox.startsWith("OCMR"))
                        userMailbox = userMailbox.substring(4);
                    if(userMailbox.startsWith("-"))
                        userMailbox = userMailbox.substring(1);
                    if(userMailbox.isEmpty())
                        userMailbox = "None listed";
                    out.print("<br><br>OCMR: " + userMailbox);
                }
            %>
            <br><br>
            <%
                String userWebPage = user.getWebPage();
                out.print("Website: ");
                if(userWebPage.isEmpty())
                    out.print("None listed");
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
                        userDepartment = userDepartment.substring(1);
                    if(userDepartment.length() > 8)
                        userDepartment = userDepartment.substring(8);
                }
                else
                    userDepartment = "None listed";
                out.print("Major(s): " + trimQuotes(userDepartment));
            }
            else if(searchRole.equals("faculty") || searchRole.equals("staff"))
            {
                if(userDepartment.length() > 5 && userDepartment.substring(0, 5).equals("DEPT-"))
                    userDepartment = userDepartment.substring(5);
                if(userDepartment.isEmpty())
                    userDepartment = "None listed";
                out.print("Department: " + trimQuotes(userDepartment));
            }
            out.print("<br><br>");
            if(searchRole.equals("faculty") || searchRole.equals("staff"))
            {
                String userOffice = user.getJobTitle();
                out.print("Office location: ");
                if(!userOffice.isEmpty())
                    out.print(trimQuotes(userOffice));
                else
                    out.print("None listed");
                out.print("<br><br>");
                String userPhone = user.getBusinessPhone1();
                out.print("Phone number: ");
                if(!userPhone.isEmpty())
                    out.print(trimQuotes(userPhone));
                else
                    out.print("None listed");

                if(APPOINTMENTS && searchRole.equals("faculty"))
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
                out.print("Class dean: ");
                if(userDean.length() >= 3)
                {
                    out.print(userDean.substring(3));
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
                    out.print("None listed");
                out.print("<br><br>Year: " + userYear);
                out.print("<br><br>");

                List<Course> userOrganizations = courseLoader.loadByUserId(user.getId());
                List<String> userCourses = new ArrayList<String>();
                List<String> userAdvisors = new ArrayList<String>();
                if(!userOrganizations.isEmpty())
                    for(Course organization : userOrganizations)
                    {
                        String organizationTitle = organization.getTitle();
                        if(organizationTitle.length() >= 7 && organizationTitle.substring(0, 7).equals(currentTermString + " "))
                            userCourses.add(organizationTitle.substring(7));
                        else if(organizationTitle.length() >= 11 && organizationTitle.substring(0, 11).equals("Advising - "))
                            userAdvisors.add(organizationTitle.substring(11));
                    }

                out.print("Advisor(s): ");
                if(!userAdvisors.isEmpty())
                {
                    for(int i = 0; i < userAdvisors.size() - 1; i++)
                        out.print(trimQuotes(userAdvisors.get(i)) + ", ");
                    out.print(trimQuotes(userAdvisors.get(userAdvisors.size() - 1)));
                }
                else
                    out.print("None listed");

                %> <td valign="top"> <%

                out.print("<br>Course(s): ");
                if(!userCourses.isEmpty())
                    for(String courseName : userCourses)
                        out.print("<br>&emsp;&emsp;" + trimQuotes(courseName));
                else
                    out.print("None listed");
            } %>
            </td>
        </tr></table>
    <% } %>
    </div>
<% } %>
<br />

<% for(int buttonIndex = 1; ((buttonIndex - 1) * PAGE_SIZE) + 1 <= userList.size(); buttonIndex++)
{ %>
    <button id="buttonpage<%=buttonIndex%>" class="pagenumberbutton" onclick="gotoPage(<%=buttonIndex%>);"><%=buttonIndex%></button>
<% } %>

</bbData:context>
