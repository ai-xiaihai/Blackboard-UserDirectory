<%@page import="java.util.*,
				blackboard.admin.data.user.*,
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
<SCRIPT LANGUAGE="JavaScript">
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
 <bbUI:breadcrumb>Student Directory</bbUI:breadcrumb>
</bbUI:breadcrumbBar>
<%
/* This is the entry point for the student directory.
 * The student directory allows users in blackboard to seatch for students by username or last name.
 * It displays only name, email and a photo. The students have to opt in to have their photo displayed in the directory.
 */

String uid = request.getParameter("uid");
if(uid == null)
{
	uid = "";
}

%>
<bbUI:titleBar 	iconUrl="/images/ci/icons/user_u.gif">Student Directory</bbUI:titleBar>
<form action="userDir.jsp?mode=normal" method="post" name="searchusers" target="_self" id="searchusers">
<span class="style2">
<input name="uid" type="text" size="40" value="<%=uid%>">
<bbUI:button type="INLINE" name="search" alt="Search" action="SUBMIT_FORM"></bbUI:button>
<input name="process" type="hidden" id="process" value="1">
<br>
<span class="style1">Search by:
<label>
<%
String check = "1"; // stores the search  criteria (can be last name (1) or user name (2))
String roles = "3";
if(request.getParameter("searchcriteria")!=null)
{
	check = request.getParameter("searchcriteria");
}
if(request.getParameter("rolesearch")!=null)
{
	roles = request.getParameter("rolesearch");
}
 %>
  <input type="radio" name="searchcriteria" value="1" <% if(check.equals("1")){out.println("checked");}%>>
  Last Name</label>
  <label>
  <input type="radio" name="searchcriteria" value="2" <%if(check.equals("2")){out.println("checked");}%>>
  Username</label><br></span>
</form>
<%
//process a search
String process = request.getParameter("process");
if((process!=null) && process.equals("1"))
{
	// create a persistence manager - needed if we want to use loaders or persisters in blakcboard
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();

	//find what type the search is - can be username or last name
	String searchtype = request.getParameter("searchcriteria");

	//create a new blackboard list to hold peron objects
	BbList<Person> personList = new BbList<Person>();

	//create a database loder for person objects
	PersonLoader personLoader = (PersonLoader)bbPm.getLoader(PersonLoader.TYPE);

	//create a database loader for portal role objects
	PortalRoleDbLoader roleLoader = (PortalRoleDbLoader)bbPm.getLoader(PortalRoleDbLoader.TYPE);

	// BRUTE FORCE METHOD FOR FINDING STUDENT PORTAL ROLE:
	PortalRole studentPortalRole = null;
	for(PortalRole portalRole : roleLoader.loadAll())
	{
		if(portalRole.getRoleName().equals("Student"))
		{
			studentPortalRole = portalRole;
			break;
		}
	}

	// // CODE THAT SHOULD WORK BUT DOES NOT (bug report has been submitted):
	// PortalRole studentPortalRole = roleLoader.loadByRoleName("Student");

	// CODE FOR TESTING ABOVE:
	%><%-- PortalRole studentPortalRole = null;

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

	// Create a new person to use as a template for searching with the PersonLoader's load() method
	Person searchTemplate = new Person();
	// We only want to load students.
	searchTemplate.setPortalRoleId(studentPortalRole.getId());

	//user did not specify a search string, so load all students
	if(uid.equals(""))//load all students
	{
		personList.addAll(personLoader.load(searchTemplate));
	}
	else //the user has specified some search string
	{
		if(searchtype.equals("1")) //searching by last name
		{
			// Search for last name with all lowercase
			searchTemplate.setFamilyName("%" + uid.toLowerCase() + "%");
			personList.addAll(personLoader.load(searchTemplate));
			// Search for last name with first character uppercase and the rest lowercase
			searchTemplate.setFamilyName("%" + uid.substring(0,1).toUpperCase() + uid.substring(1).toLowerCase() + "%");
			personList.addAll(personLoader.load(searchTemplate));
		}
		else if(searchtype.equals("2"))//search by user name; user names never have capital letters
		{
			searchTemplate.setUserName("%" + uid.toLowerCase() + "%");
			personList.addAll(personLoader.load(searchTemplate));
		}
	}
	// remove unavailable accounts from the list
	personList = personList.getFilteredSubList(new AvailabilityFilter(AvailabilityFilter.AVAILABLE_ONLY));
	// remove the default Mellon Accounts from the list
	personList = personList.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Faculty Member", GenericFieldFilter.Comparison.NOT_EQUALS));
	personList = personList.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Blackboard", GenericFieldFilter.Comparison.NOT_EQUALS));
	//remove users that have opted out
	personList = personList.getFilteredSubList(new GenericFieldFilter("getBusinessFax", User.class, "No", GenericFieldFilter.Comparison.NOT_EQUALS));

	// sort by last name, first name
	GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
    comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
    Collections.sort(personList,comparator);

	 %>
	<span class="style7"><%=personList.size()%>
	<%
	 	out.print(" student(s) located.");
	 %><br>
	</span>	<bbUI:list collection="<%=personList%>"
				collectionLabel="Students"
				objectId="student"
				className="User"
				sortUrl="">

		<bbUI:listElement
                width=""
                label="Student Information"
                href="">
					<table>
				 	 <tr><td width="70">

						<img src="http://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/<%=student.getUserName()%>/profileImage" name="facPhoto" width="70" onError="imageError(this)">
					</td>
					<td width="200"><span class="style3">
							<%=student.getFamilyName()%>, <%=student.getGivenName()%>
					<br></span>
					<% if(!student.getEmailAddress().equals(""))
					{
					 	out.print("<a href=\"mailto:" + student.getEmailAddress() + "\">" + student.getEmailAddress() + "</a>");
					}%><br>
					<% if(!student.getUserName().equals(""))
					{
						out.print(student.getUserName());
					} %><br>
					<% if(!student.getJobTitle().equals("")) //OCMR
					{
						out.print(student.getJobTitle());
					} %><br>
					<% if(!student.getDepartment().equals("")) //major
					{
						out.print(student.getDepartment());
					} %><br>
					<% if(!student.getStreet1().equals("")) //home address
					{
						out.print(student.getStreet1());
					} %><br>
					<% if(!student.getCity().equals(""))
					{
						out.print(student.getCity()+", ");
					} %>
					<% if(!student.getState().equals(""))
					{
						out.print(student.getState()+" ");
					} %>
					<% if(!student.getZipCode().equals(""))
					{
						out.print(student.getZipCode());
					} %>
					</td>
					<td width="200" valign="top">
					<% if(!student.getHomePhone1().equals(""))
					{
						out.print("Home: "+student.getHomePhone1());
					} %><br>
					<% if(!student.getMobilePhone().equals(""))
					{
						out.print("Mobile: "+student.getMobilePhone());
					} %><br>
					<% if(!student.getBusinessPhone1().equals(""))
					{
						out.print("Work: "+student.getBusinessPhone1());
					} %><br>

					</td>
					<td width="200" valign="top">
<%
	List<Course> courses = CourseDbLoader.Default.getInstance().loadByUserId(student.getId());

	for (Course currentCourse: courses) {
		Id id = currentCourse.getId();
		String courseID = currentCourse.getCourseId();

		String courseName = currentCourse.getTitle();

		String numbers = "0123456789";
		boolean isOrg = true;
		for(int i=0; i<10; i++){
			if (courseName.charAt(0)==numbers.charAt(i)){
				isOrg = false;
				break;
			}
		}
		if (isOrg){
		%>
		<div><%=courseName%></div>
	<%		}
		}%>


					</td></tr></table>
</bbUI:listElement></bbUI:list>
	<%
}
%>
<script language="JavaScript">
<!--

document.searchusers.uid.focus();
//-->
</script>
</bbUI:docTemplate>
</bbData:context>
