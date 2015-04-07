var xmlhttp = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
window.onload = function()
                {
                    document.getElementById("searchterm").focus();
                    document.onkeypress = function() { searchOnEnter(event); };
                }
function imageError(image)
{
    image.src = "https://octet1.csr.oberlin.edu/octet/Bb/Faculty/img/noimage.jpg";
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
        document.getElementById("loadingsearch").innerHTML = "<br />";
        alert("Something went wrong! We couldn't communicate with our server. Please let the OCTET office know if this was unexpected.");
    }
    else if(xmlhttp.readyState < 4)
    {
        document.getElementById("loadingsearch").innerHTML = 'Loading...';
    }
    else
    {
        document.getElementById("loadingsearch").innerHTML = "<br />";
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
