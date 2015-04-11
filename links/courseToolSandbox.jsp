<%@ page import="java.net.URL,
                 java.util.*"
%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbUI" prefix="bbUI"%>

<%-- <bbData:context id="ctx">
<bbUI:docTemplate title="OCTET Sandbox"> --%>

<!--
	TEST DESCRIPTION:
        This test will aim to determine the feasibility of accessing an external
    php file from within a building block, and of constructing Easter eggs from
    its contents.
-->

<%!
public static String doubleQuote(String string) { return "\"" + string + "\""; }

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

    public String toString()
    {
        String result = "AudioEasterEgg: ";
        result += "username " + username;
        result += ", filename " + filename;
        return result;
    }
}

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
        return null;
    }
}

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
        return null;
    }
}
%>

<%
    out.println("<div>Audio Easter Eggs: " + getAudioEasterEggs() + "</div>");
    out.println("<div>Image Easter Eggs: " + getImageEasterEggs() + "</div>");
%>

<%-- </bbUI:docTemplate>
</bbData:context> --%>
