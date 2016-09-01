<%@ page import="java.util.*,
                 java.net.URL,
                 java.net.CookieManager,
                 java.net.CookieHandler,
                 java.net.CookiePolicy,
                 java.text.SimpleDateFormat,
                 java.io.PrintWriter,
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
        session="true"
%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<bbData:context id="ctx">

<%!
// See all the easter eggs at once
static final String EASTER_EGG_PHRASE = "happy fun times";
// Where we get our easter eggs from
static final String EASTER_EGG_IMAGE_PAGE = "http://octet1.csr.oberlin.edu/octet/Bb/UserDirectory/hfti.php";
static final String EASTER_EGG_AUDIO_PAGE = "http://octet1.csr.oberlin.edu/octet/Bb/UserDirectory/hfta.php";
// Number of people per page
static final int PAGE_SIZE = 10;

// Should we show them potentially sensitive information?
static boolean displayPrivilegedInformation;
// Relevant portal roles
static PortalRole studentPortalRole;
static PortalRole facultyPortalRole;
static PortalRole staffPortalRole;
static PortalRole emeritiPortalRole;
static PortalRole alumniPortalRole;
static PortalRole nonObiePortalRole;
static PortalRole guestPortalRole;
%>

<%
try
{
    System.setProperty("jsse.enableSNIExtension", "false");
}
catch(Exception e)
{
    out.println("<!-- EXCEPTION ENCOUNTERED WHILE TRYING TO DISABLE SNI EXTENSION");
    e.printStackTrace(new PrintWriter(out));
    out.println(" -->");
}

displayPrivilegedInformation = false;

// What text did they ask to search for?
String searchTerm = request.getParameter("searchterm");
if(searchTerm == null) return;

// How do they want to search--first name, last name, or user name?
String searchCriteria = request.getParameter("searchcriteria");
if(searchCriteria == null) return;

// What kind of users are they searching for--student, faculty, and/or staff?
String[] searchRoleNames = request.getParameterValues("searchroles");
if(searchRoleNames == null) searchRoleNames = new String[0];

// Create a persistence manager - needed if we want to use loaders or persisters in blackboard.
BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
// Create a portal role loader, for locating and indentifying the portal roles of users.
PortalRoleDbLoader portalRoleLoader = (PortalRoleDbLoader)bbPm.getLoader(PortalRoleDbLoader.TYPE);

// Load all portal roles once to avoid redundancy with calls to getPortalRoleByName().
List<PortalRole> portalRoles = portalRoleLoader.loadAll();
// Find the student portal role.
studentPortalRole = getPortalRoleByName(portalRoles, "Student");
// Find the faculty portal role.
facultyPortalRole = getPortalRoleByName(portalRoles, "Faculty");
// Find the staff portal role.
staffPortalRole = getPortalRoleByName(portalRoles, "Staff");
// Find the emeriti portal role.
emeritiPortalRole = getPortalRoleByName(portalRoles, "Emeriti");
// Find the alumni portal role.
alumniPortalRole = getPortalRoleByName(portalRoles, "Alumni");
// Find the non-Obie portal role.
nonObiePortalRole = getPortalRoleByName(portalRoles, "Non Obie");
// Find the guest portal role.
guestPortalRole = getPortalRoleByName(portalRoles, "Guest");

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
// If they are a member of faculty, we show them more.
else if(currentUserPortalRoleId.equals(facultyPortalRole.getId()))
{
    displayPrivilegedInformation = true;
}
// If they are not a student, alumnus, or faculty/emeriti, block access.
else if(!(currentUserPortalRoleId.equals(staffPortalRole.getId())   ||
          currentUserPortalRoleId.equals(studentPortalRole.getId()) ||
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

// Take in some string, and remove leading and trailing single- and double-quote characters.
public static String trimQuotes(String string)
{
    int begin = 0;
    while(begin < string.length() && (string.charAt(begin) == '"' || string.charAt(begin) == '\'')) begin++;

    int end = string.length() - 1;
    if(end >= 0 && string.charAt(end) == '"')
    {
        while(end >= 0 && string.charAt(end) == '"') end--;
        return string.substring(begin, end + 1);
    }
    else
        return string.substring(begin);
}

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
public static HashMap<String, String> getImageEasterEggs() throws Exception
{
    HashMap<String, String> result = new HashMap<String, String>();
    URL fileURL = new URL(EASTER_EGG_IMAGE_PAGE);
    Scanner fileReader = new Scanner(fileURL.openStream());

    while(fileReader.hasNext())
        result.put(fileReader.next(), fileReader.next());

    fileReader.close();
    return result;
}

// Mappings are username : audio easter egg
public static HashMap<String, AudioEasterEgg> getAudioEasterEggs() throws Exception
{
    HashMap<String, AudioEasterEgg> result = new HashMap<String, AudioEasterEgg>();
    URL fileURL = new URL(EASTER_EGG_AUDIO_PAGE);
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
        String result = "<audio id=\"" + username + "_audio\" preload=\"auto\"";
        if(loop)
            result += " loop";
        result += " >";
        result += "<source src=\"" + filename + ".mp3\" type=\"audio/mpeg\" />";
        result += "<source src=\"" + filename + ".ogg\" type=\"audio/ogg\" />";
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
    StringBuilder result = new StringBuilder();
    result.append("<div class=\"preload\"><img src=\"");
    result.append(imageEasterEgg);
    result.append("\" /></div>");
    return result.toString();
}

// The body of the <bbUI:list> tag became rather messy. The next function(s) should help mitigate that.
public static String userImageCode(User user, HashMap<String, String> imageEasterEggs, HashMap<String, AudioEasterEgg> audioEasterEggs)
{
    StringBuilder result = new StringBuilder();

    String userName = user.getUserName();
    String userPicture = getUserPicture(userName);
    result.append("<img src=\"");
    result.append(userPicture);
    result.append("\" width=\"100\" onerror=\"imageError(this);\"");
    String imageEasterEgg = imageEasterEggs.get(userName);
    AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
    if(imageEasterEgg != null && audioEasterEgg != null)
    {
        result.append(" onMouseOver=\"mouseOverBoth(this, '");
        result.append(imageEasterEgg);
        result.append("', '");
        result.append(userName);
        result.append("');\"");
        if(audioEasterEgg.stopOnMouseExit())
        {
            result.append(" onMouseOut=\"mouseOutBoth(this, '");
            result.append(userPicture);
            result.append("', '");
            result.append(userName);
            result.append("');\"");
        }
        else
        {
            result.append(" onMouseOut=\"mouseOutImage(this, '");
            result.append(userPicture);
            result.append("');\"");
        }
    }
    else if(imageEasterEgg != null)
    {
        result.append(" onMouseOver=\"mouseOverImage(this, '");
        result.append(imageEasterEgg);
        result.append("');\"");
        result.append(" onMouseOut=\"mouseOutImage(this, '");
        result.append(userPicture);
        result.append("');\"");
    }
    else if(audioEasterEgg != null)
    {
        result.append(" onMouseOver=\"mouseOverAudio('");
        result.append(userName);
        result.append("');\"");
        if(audioEasterEgg.stopOnMouseExit())
        {
            result.append(" onMouseOut=\"mouseOutAudio('");
            result.append(userName);
            result.append("');\"");
        }
    }
    result.append(" />");
    return result.toString();
}

public static String userFirstColumnCode(User user, Id userPortalRoleId)
{
    StringBuilder result = new StringBuilder();

    result.append("<span class=\"userfullname\">");
    String userLastName = user.getFamilyName();
    String userFirstName = (displayPrivilegedInformation || !userPortalRoleId.equals(studentPortalRole.getId())) ? user.getGivenName() : getPreferredName(user.getGivenName());
    result.append(userLastName);
    result.append(", ");
    result.append(userFirstName);
    result.append("</span><br />");

    if(userPortalRoleId.equals(facultyPortalRole.getId()) || userPortalRoleId.equals(staffPortalRole.getId()))
    {
        String userTitle = trimQuotes(user.getCompany());
        if(!userTitle.isEmpty())
        {
            result.append("<span class=\"positiontitle\">");
            result.append(userTitle);
            result.append("</span><br />");
        }
    }

    result.append("<br /><span class=\"fieldtitle\">Email: </span>");
    result.append(user.getUserName());
    result.append("@oberlin.edu<br /><br />");

    if(userPortalRoleId.equals(studentPortalRole.getId()))
    {
        result.append("<span class=\"fieldtitle\">OCMR: </span>");
        String userMailbox = user.getJobTitle();
        if(userMailbox.startsWith("OCMR"))
            userMailbox = userMailbox.substring(4);
        if(userMailbox.startsWith("-"))
            userMailbox = userMailbox.substring(1);
        if(userMailbox.isEmpty())
            userMailbox = "None listed";
        result.append(userMailbox);
    }
    else if(userPortalRoleId.equals(facultyPortalRole.getId()) || userPortalRoleId.equals(staffPortalRole.getId()))
    {
        result.append("<span class=\"fieldtitle\">Website: </span>");
        String userWebPage = user.getWebPage();
        if(userWebPage.isEmpty())
            result.append("None listed");
        else
        {
            result.append("<a href=\"");
            result.append(userWebPage);
            result.append("\">");
            result.append(userWebPage);
            result.append("</a>");
        }
    }
	return result.toString();
}

public static String userSecondColumnCode(User user, Id userPortalRoleId, List<String> userAdvisors)
{
    StringBuilder result = new StringBuilder();
    if(displayPrivilegedInformation && userPortalRoleId.equals(studentPortalRole.getId()))
    {
        result.append("<span class=\"fieldtitle\">Major(s): </span>");
        String userMajor = trimQuotes(user.getDepartment());
        if(userMajor.startsWith("Major - "))
            userMajor = userMajor.substring(8);
        if(userMajor.isEmpty())
            userMajor = "None listed";
        result.append(userMajor);
        result.append("<br /><br />");

        result.append("<span class=\"fieldtitle\">Class dean: </span>");
        // Format should be something like "FR-Donaldson"
        String userDean = user.getOtherName();
        String userYear = "None listed";
        if(userDean.length() >= 3)
        {
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
            userDean = userDean.substring(3);
        }
        else
            userDean = "None listed";
        result.append(userDean);
        result.append("<br /><br /><span class=\"fieldtitle\">Year: </span>");
        result.append(userYear);
        result.append("<br /><br />");

        result.append("<span class=\"fieldtitle\">Advisor(s): </span>");
        if(userAdvisors != null && !userAdvisors.isEmpty())
        {
            for(int i = 0; i < userAdvisors.size() - 1; i++)
            {
                result.append(trimQuotes(userAdvisors.get(i)));
                result.append(", ");
            }
            result.append(trimQuotes(userAdvisors.get(userAdvisors.size() - 1)));
        }
        else
            result.append("None listed");
    }
    else if(userPortalRoleId.equals(facultyPortalRole.getId()) || userPortalRoleId.equals(staffPortalRole.getId()))
    {
        result.append("<span class=\"fieldtitle\">Department: </span>");
        String userDepartment = trimQuotes(user.getDepartment());
        if(userDepartment.startsWith("DEPT"))
            userDepartment = userDepartment.substring(4);
        if(userDepartment.startsWith("-"))
            userDepartment = userDepartment.substring(1);
        if(userDepartment.isEmpty())
            userDepartment = "None listed";
        result.append(userDepartment);
        result.append("<br /><br />");

        result.append("<span class=\"fieldtitle\">Office location: </span>");
        String userOffice = trimQuotes(user.getJobTitle());
        if(userOffice.isEmpty())
            userOffice = "None listed";
        result.append(userOffice);
        result.append("<br /><br />");

        result.append("<span class=\"fieldtitle\">Phone number: </span>");
        String userPhone = trimQuotes(user.getBusinessPhone1());
        if(userPhone.isEmpty())
            userPhone = "None listed";
        result.append(userPhone);
    }
    return result.toString();
}

String userThirdColumnCode(User user, Id userPortalRoleId, List<String> userCourses)
{
    StringBuilder result = new StringBuilder();
    if(displayPrivilegedInformation && userPortalRoleId.equals(studentPortalRole.getId()))
    {
        result.append("<br /><span class=\"fieldtitle\">Course(s): </span>");
        if(userCourses != null && !userCourses.isEmpty())
            for(String courseName : userCourses)
            {
                result.append("<br />&emsp;&emsp;");
                result.append(trimQuotes(courseName));
            }
        else
            result.append("None listed");
    }
    return result.toString();
}
%>

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
Set<Id> searchRoles = new HashSet<Id>();
for(String searchRoleName : searchRoleNames)
{
    PortalRole searchRole = getPortalRoleByName(portalRoles, searchRoleName);
    if(searchRole != null)
        searchRoles.add(searchRole.getId());
    else
        out.println("<div>Failed to load portal role for " + searchRoleName +
                    ". This is probably an error; please contact the OCTET" +
                    " office in King 125 with this information.</div>");
}

// We want a list of unique entries, sorted by how closely they resemble the search term.
TreeSet<User> userSet = null;

// Create a UserSearch object, for use with the UserDbLoader's loadByUserSearch() method.
UserSearch userSearch = new UserSearch();
// Don't show disabled users.
userSearch.setOnlyShowEnabled(true);

// Instantiate the set of users with the appropriate comparator and set up the
// parameters for the search
if(searchCriteria.equals("first"))
{
    userSet = new TreeSet(new FirstNameComparator(searchTerm, displayPrivilegedInformation));
    userSearch.setNameParameter(UserSearch.SearchKey.GivenName, SearchOperator.Contains, searchTerm);
}
else if(searchCriteria.equals("last"))
{
    userSet = new TreeSet(new LastNameComparator(searchTerm));
    userSearch.setNameParameter(UserSearch.SearchKey.FamilyName, SearchOperator.Contains, searchTerm);
}
else if(searchCriteria.equals("user"))
{
    if(searchTerm.length() > 8)
        userSet = new TreeSet(new UserNameComparator(searchTerm.substring(0, 8)));
    else
        userSet = new TreeSet(new UserNameComparator(searchTerm));
    userSearch.setNameParameter(UserSearch.SearchKey.UserName, SearchOperator.Contains, searchTerm);
}

// Teehee
try
{
    CookieManager cookieManager = new CookieManager();
    cookieManager.setCookiePolicy(CookiePolicy.ACCEPT_ALL);
    CookieHandler.setDefault(cookieManager);
}
catch(Exception e)
{
    out.println("<!-- EXCEPTION ENCOUNTERED WHILE SETTING COOKIE POLICY");
    e.printStackTrace(new PrintWriter(out));
    out.println(" -->");
}

HashMap<String, AudioEasterEgg> audioEasterEggs = null;
HashMap<String, String> imageEasterEggs = null;
try
{
    audioEasterEggs = getAudioEasterEggs();
}
catch(Exception e)
{
    out.println("<!-- EXCEPTION ENCOUNTERED WHILE ACQUIRING AUDIO EASTER EGGS");
    e.printStackTrace(new PrintWriter(out));
    out.println(" -->");
    audioEasterEggs = new HashMap<String, AudioEasterEgg>();
}
try
{
    imageEasterEggs = getImageEasterEggs();
}
catch(Exception e)
{
    out.println("<!-- EXCEPTION ENCOUNTERED WHILE ACQUIRING IMAGE EASTER EGGS");
    e.printStackTrace(new PrintWriter(out));
    out.println(" -->");
    imageEasterEggs = new HashMap<String, String>();
}

// Iterate over every user we've found.
for(User user : userLoader.loadByUserSearch(userSearch))
{
    String userName = user.getUserName();
    // Skip them if they're a preview user or unavailable.
    if(user.getIsAvailable() && !userName.contains("previewuser"))
    {
        // Find out what kind of user (student, faculty, administrator, etc.) they are.
        Id userPortalRoleId = portalRoleLoader.loadPrimaryRoleByUserId(user.getId()).getId();
        // Skip them if they aren't what the user has asked for.
        if(searchRoles.contains(userPortalRoleId))
        {
            // Unless a member of faculty/staff is performing the search, filter out
            // student name matches based on legal names instead of preferred names.
            if(!displayPrivilegedInformation &&
                searchCriteria.equals("first") &&
                userPortalRoleId.equals(studentPortalRole.getId()) &&
               !getPreferredName(user.getGivenName()).toLowerCase().contains(searchTerm.toLowerCase()))
            {
                continue;
            }
            // Add the user to our set. Complexity is neccessary, since some users
            // do not load fully otherwise and userSearch.setPublicInfoOnly(false)
            // doesn't work.
            userSet.add(userLoader.loadById(user.getId()));

            // Create the hidden audio elements for anyone who gets one.
            AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
            if(audioEasterEgg != null) out.print(audioEasterEgg.getAnchorCode());

            // Preload alternate images so there's no delay on the first mouseover.
            String imageEasterEgg = imageEasterEggs.get(userName);
            if(imageEasterEgg != null) out.print(imageEasterEggCode(imageEasterEgg));
        }
    }
}

if(userSet.isEmpty() && searchTerm.equalsIgnoreCase(EASTER_EGG_PHRASE))
{
    Set<String> easterEggNames = new HashSet<String>();
    easterEggNames.addAll(imageEasterEggs.keySet());
    easterEggNames.addAll(audioEasterEggs.keySet());
    for(String userName : easterEggNames)
    {
        try
        {
            userSet.add(userLoader.loadByUserName(userName));
            AudioEasterEgg audioEasterEgg = audioEasterEggs.get(userName);
            if(audioEasterEgg != null) out.print(audioEasterEgg.getAnchorCode());
            String imageEasterEgg = imageEasterEggs.get(userName);
            if(imageEasterEgg != null) out.print(imageEasterEggCode(imageEasterEgg));
        }
        catch(Exception e) {}
    }
}
%>

<span class="style7"><%=userSet.size()%> user(s) located.</span>
<span class="pagenumber">
    <button id="prevpagebutton" onclick="prevPage();" class="pagedirectionbutton" disabled>Prev</button>
    <span class="style7">Page <span id="currentpage">1</span> of <%=userSet.isEmpty() ? 1 : ((userSet.size() - 1) / PAGE_SIZE) + 1%></span>
    <button id="nextpagebutton" onclick="nextPage();" class="pagedirectionbutton">Next</button>
</span>
<br /><br />

<% if(userSet.isEmpty())
{ %>
    <div id="resultspage1" class="resultspage" hidden></div>
    <button id="buttonpage1" class="pagenumberbutton" hidden></button>
<% }

Iterator<User> userIterator = userSet.iterator();
for(int pageIndex = 0; userIterator.hasNext(); pageIndex++)
{ %>
    <div id="resultspage<%=pageIndex + 1%>" class="resultspage">
    <%  for(int i = 0; i < PAGE_SIZE; i++)
    {
        if(!userIterator.hasNext())
        { %>
            <table class="emptytable"><tr></tr></table>
        <% continue;
        }
        User user = userIterator.next();
        Id userPortalRoleId = portalRoleLoader.loadPrimaryRoleByUserId(user.getId()).getId();

        List<Course> userOrganizations = null;
        List<String> userCourses = null;
        List<String> userAdvisors = null;
        if(displayPrivilegedInformation && userPortalRoleId.equals(studentPortalRole.getId()))
        {
            userOrganizations = courseLoader.loadByUserId(user.getId());
            if(!userOrganizations.isEmpty())
            {
                userCourses = new ArrayList<String>();
                userAdvisors = new ArrayList<String>();
                for(Course organization : userOrganizations)
                {
                    String organizationTitle = organization.getTitle();
                    if(organizationTitle.startsWith(currentTermString + " "))
                        userCourses.add(organizationTitle.substring(7));
                    else if(organizationTitle.startsWith("Advising - "))
                        userAdvisors.add(organizationTitle.substring(11));
                }
            }
        }
        %>
        <table class="resultstable">
            <tr>
                <td width="30"></td>
                <td width="110" valign="middle"><%=userImageCode(user, imageEasterEggs, audioEasterEggs)%></td>
                <td width="250" valign="middle"><%=userFirstColumnCode(user, userPortalRoleId)%></td>
                <td width="250" valign="middle"><%=userSecondColumnCode(user, userPortalRoleId, userAdvisors)%></td>
                <td width="250" valign="top"><%=userThirdColumnCode(user, userPortalRoleId, userCourses)%></td>
                <td width="30"></td>
            </tr>
        </table>
    <% } %>
    </div>
<% } %>
<br />

<% for(int buttonIndex = 1; ((buttonIndex - 1) * PAGE_SIZE) + 1 <= userSet.size(); buttonIndex++)
{ %>
    <button id="buttonpage<%=buttonIndex%>" class="pagenumberbutton" onclick="gotoPage(<%=buttonIndex%>);"><%=buttonIndex%></button>
<% } %>

</bbData:context>
