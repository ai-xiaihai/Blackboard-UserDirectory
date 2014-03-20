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

//uid stores the search strong that tbe user specified
String uid = "";
if(request.getParameter("uid")!=null)
{
	uid = request.getParameter("uid"); //get the search string if one exists
} %>
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
String check = "1"; // stores the seatch  criteria (can be last name (1) or user name (2)
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
  Username</label><br>
  <em>Note: These searches are case-sensitive.</em></span>
</form>
<%
//process a search
String process = request.getParameter("process");
if((process!=null) && process.equals("1"))
{
	// create a persistence manager - needed if we want to use loaders or persistersi n blakcboard
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	
	//create a database loader for users
	UserDbLoader loader = (UserDbLoader) bbPm.getLoader( UserDbLoader.TYPE );
	//find what type the search is - can be usernameo r last name
	String searchtype = request.getParameter("searchcriteria");
	
	//create a new blackboard list to hold user objects
	blackboard.base.BbList userlist = new BbList(User.class);
	
	//create a database loader for portal role objects
	PortalRoleDbLoader roleloader = (PortalRoleDbLoader) bbPm.getLoader( PortalRoleDbLoader.TYPE );
	
	//user did not specify a search string, so load all students
	if(uid.equals(""))//load all students
	{
		//load all portal roles in Blackboard
		BbList rolelist = roleloader.loadAll();
		//create an iterator to step through the list of portal roles
		Iterator roleIter = rolelist.iterator();
			while(roleIter.hasNext())
			{	
				//get the next portal role
				PortalRole role = (PortalRole)roleIter.next();
				if(role.getRoleName().equals("Student"))//when we find trhe student role
				{
					// load all users who have that role in the system
					userlist.addAll( loader.loadByPrimaryPortalRoleId(role.getId()) );
				}
			}
	}
	else //the user has specified some search string
	{
		if(searchtype.equals("1")) //searching by last name
		{
			if(request.getParameter("uid").length()==1)
			{
				//if search string is only one letter, assume it's supposed to be capital
				String search = request.getParameter("uid").toUpperCase();
				
				//create a database loader for Person objects
				PersonLoader pL = (PersonLoader)bbPm.getLoader(PersonLoader.TYPE);
				
				// new person
				Person p = new Person();
				// search by family name
				p.setFamilyName("%"+search+"%");
				// loads everyone who has a last name like the one specified up top. % stands for a wildcard
				userlist = pL.load(p);
			}
			else
			{
			
				PersonLoader pL = (PersonLoader)bbPm.getLoader(PersonLoader.TYPE);
				Person p = new Person();
				//do not capitalize the search string if it's londer than one letter
				p.setFamilyName("%"+request.getParameter("uid")+"%");
				userlist = pL.load(p);
				
				//check if the search string is all lower case
				boolean isLC = true;
				String s = request.getParameter("uid");
				for(int i = 0; i < s.length() && isLC; i++)
				{
					isLC = Character.isLowerCase(s.charAt(i));
				}
				if(isLC) // if it's all lower case - append another result - with the first letter capitalized
				{
					String ss = s.toLowerCase();
					ss = (new Character(ss.charAt(0))).toString().toUpperCase() + ss.substring(1);
					p.setFamilyName("%"+ss+"%");
					userlist.addAll(pL.load(p));
				}
			}			
		}
		else if(searchtype.equals("2"))//search by user name
		{
			userlist = loader.searchByUserName(request.getParameter("uid"));
		}
		if(userlist.isEmpty() || userlist.size()==0) // if the rezults list is empty
		{
			String searchString = request.getParameter("uid").toLowerCase(); // try search with the search all lower case
			searchString = (new Character(searchString.charAt(0))).toString().toUpperCase() + searchString.substring(1);
			if(searchtype.equals("1"))
			{
				PersonLoader pL = (PersonLoader)bbPm.getLoader(PersonLoader.TYPE);
				Person p = new Person();
				p.setFamilyName("%"+searchString+"%");
				userlist = pL.load(p);
			}
			else if(searchtype.equals("2"))
			{
				userlist = loader.searchByUserName(searchString);
			}
		}
		
		// iterate through the results
		Iterator userIter = userlist.iterator();
		while(userIter.hasNext())
		{
			boolean isStudent = false;
			User thisUser = (User)userIter.next();
			String userRole = thisUser.getPortalRoleId().toExternalString();
			if(userRole.equals("_1_1")) //student role's exernal string id is "_1_1"
			{
					isStudent = true;
			}
			
			if(!isStudent) //if user is not a student
			{
				userIter.remove(); //remove the user from the list
			}
		}
	}
	// remove unavailable accounts from the list
	userlist = userlist.getFilteredSubList(new AvailabilityFilter(AvailabilityFilter.AVAILABLE_ONLY));
	// remove the default Mellon Accounts from the list
	userlist = userlist.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Faculty Member", GenericFieldFilter.Comparison.NOT_EQUALS));
	userlist = userlist.getFilteredSubList(new GenericFieldFilter("getGivenName", User.class, "Blackboard", GenericFieldFilter.Comparison.NOT_EQUALS));
	//remove users that have opted out
	userlist = userlist.getFilteredSubList(new GenericFieldFilter("getBusinessFax", User.class, "No", GenericFieldFilter.Comparison.NOT_EQUALS));
	
	// sort by last name, first name
	GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
    comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
    Collections.sort(userlist,comparator);
	
	 %>
	<span class="style7"><%=userlist.size()%>
	<% 
	 	out.print(" student(s) located.");
	 %><br>	
	</span>	<bbUI:list collection="<%=userlist%>" 
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