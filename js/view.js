var xmlhttp = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
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
function newSearch()
{
    if(validateSearch())
    {
        loadAJAX('search.jsp', searchUpdate, getSearchData());
        document.activeElement.blur();
    }
}
function validateSearch()
{
    var searchTerm = document.getElementById("searchterm").value;
    if(searchTerm.length <= 1)
        return confirm("The term you are searching is very short, which may return a large number (even thousands) of results and take a long time to load.\n\nAre you sure you want to search for '" + searchTerm + "'?");
    return true;
}
function loadAJAX(fileLocation, updateFunction, postData)
{
    xmlhttp.onreadystatechange = updateFunction;
    xmlhttp.open("POST", fileLocation, true);
    xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    xmlhttp.send(postData);
}
function globalKeyHandler(event)
{
    var code = event.keyCode || event.which;
    switch(code)
    {
        case 13:
            newSearch();
            break;
        case 37:
            prevPage();
            break;
        case 39:
            nextPage();
            break;
    }
}
function searchUpdate()
{
    if(xmlhttp.status == 404)
    {
        document.getElementById("loadingmessage").style.display = "none";
        alert("Something went wrong! We couldn't communicate with our server. Please let the OCTET office know if this was unexpected.");
    }
    else if(xmlhttp.readyState < 4)
    {
        document.getElementById("loadingmessage").style.display = "inline";
    }
    else
    {
        document.getElementById("loadingmessage").style.display = "none";
        document.getElementById("searchresults").innerHTML = xmlhttp.responseText;
        gotoPage(1);
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

    if(document.getElementById("studentrole").checked)
        result += "&searchroles=" + document.getElementById("studentrole").value;
    if(document.getElementById("facultyrole").checked)
        result += "&searchroles=" + document.getElementById("facultyrole").value;
    if(document.getElementById("staffrole").checked)
        result += "&searchroles=" + document.getElementById("staffrole").value;

    return result;
}
function gotoPage(newPageNumber)
{
    var currentPageElement = document.getElementById("currentpage");
    var currentPageNumber = currentPageElement.innerHTML;

    document.getElementById("buttonpage" + currentPageNumber).disabled = false;
    document.getElementById("buttonpage" + newPageNumber).disabled = true;

    document.getElementById("resultspage" + currentPageNumber).style.display = "none";
    document.getElementById("resultspage" + newPageNumber).style.display = "inline";

    currentPageElement.innerHTML = newPageNumber;
    checkPrevNextButtons();
}
function prevPage()
{
    var currentPageNumber = parseInt(document.getElementById("currentpage").innerHTML);
    var prevPageButton = document.getElementById("buttonpage" + (currentPageNumber - 1));
    if(prevPageButton != null)
        prevPageButton.click();
    checkPrevNextButtons();
}
function nextPage()
{
    var currentPageNumber = parseInt(document.getElementById("currentpage").innerHTML);
    var nextPageButton = document.getElementById("buttonpage" + (currentPageNumber + 1));
    if(nextPageButton != null)
        nextPageButton.click();
    checkPrevNextButtons();
}
function checkPrevNextButtons()
{
    var currentPageNumber = parseInt(document.getElementById("currentpage").innerHTML);
    var prevPageButton = document.getElementById("prevpagebutton");
    var nextPageButton = document.getElementById("nextpagebutton");
    if(document.getElementById("buttonpage" + (currentPageNumber - 1)) == null)
        prevPageButton.disabled = true;
    else
        prevPageButton.disabled = false;
    if(document.getElementById("buttonpage" + (currentPageNumber + 1)) == null)
        nextPageButton.disabled = true;
    else
        nextPageButton.disabled = false;
}
