_editor_url = "editor/";

function addcategory(msg,action){
	var cat=prompt(msg,"");
	if (cat!=null)
	{
		document.myform.action=action + "&cat=" + escape(cat);
		document.myform.submit();
	}
}

function SelectAll(){
	obj=document.myform.email;
	for(i = 0; i < obj.options.length; i++){
		obj.options[i].selected=true
}}

function submitit(action){
for (var f, n=0, DL=document.myform, i=0; i<DL.elements.length; i++) {if ((DL.elements[i].name.indexOf('ID')> -1)) {if (DL.elements[i].checked){n=n+1; }}}
if (n>0) {
	document.myform.action=action;
	document.myform.submit();
	}
else {
	alert(NoItemsMsg)
}}

function submitform(action){
	document.myform.action=action;
	document.myform.submit();
}

function addTo() {
	obj=document.myform.email;
	for(i = 0; i < obj.options.length; i++){
		if(obj.options[i].selected){
			opener.myform.To.value=opener.myform.To.value + obj.options[i].value + "; ";
 		}
	}
}

function addCC() {
	obj=document.myform.email;
	for(i = 0; i < obj.options.length; i++){
		if(obj.options[i].selected){
			opener.myform.CC.value=opener.myform.CC.value + obj.options[i].value + "; ";
 		}
	}
}

function addBCC() {
	obj=document.myform.email;
	for(i = 0; i < obj.options.length; i++){
		if(obj.options[i].selected){
			opener.myform.BCC.value=opener.myform.BCC.value + obj.options[i].value + "; ";
 		}
	}
}

function openMainPopup(url) {
	myPopup = window.open(url,'Main','width=660,height=480,top=100,left=100,resizable=yes,scrollbars=yes,toolbars=no,statusbar=yes,titlebar=no');
	myPopup.focus();
}

function openMailPopup(url) {
	myPopup = window.open(url,Math.floor(Math.random() * 99999),'width=640,height=600,top=100,left=100,resizable=yes,scrollbars=yes,toolbars=no,statusbar=yes,titlebar=no');
	myPopup.focus();
}

function openSmallPopup(url) {
	myPopup = window.open(url,Math.floor(Math.random() * 99999),'width=400,height=280,top=100,left=600,resizable=yes,scrollbars=yes,toolbars=no,statusbar=yes,titlebar=no');
	myPopup.focus();
}

function closePopup() {
opener.focus();
 //opener.location.href = opener.location;
 self.close();
}


function find(Msg){
	var findstr=prompt(Msg,"");
	if (findstr!=null)
	{
		document.myform.action="readmail.asp?a=find&q="+escape(findstr);
		document.myform.submit();
	}
}

function moveitems(){
	myPopup = window.open('','MovePopup','width=200,height=210,top=100,left=600,resizable=yes,scrollbars=yes,toolbars=no,statusbar=yes,titlebar=no');
	document.myform.target='MovePopup';
	document.myform.action='readmail.asp?a=move';
	document.myform.submit();
	myPopup.focus();
}

function ConfirmAction(msg,action){
	if (confirm(msg)) {
	document.myform.action=action;
	document.myform.submit();}
}

function ButtonOver(item) {
	item.className = "Button_sel";
	if (item.alt !=null) {
		window.status=item.alt;
	}
}

function ButtonOff(item) {
	item.className = "Button_unsel";
	window.status='ASP WebMail - http://www.iisworks.com';
}


function CheckAll()
{for (var i=0;i<document.myform.elements.length;i++) { var e = document.myform.elements[i]; if (e.name != 'allbox') e.checked = document.myform.allbox.checked;}}


function Popup(ID) {
	myPopup=window.open("readmail.asp?a=show&ID=" + ID,ID, "height=660,width=700,location=no,menubar=no,resizable=yes,scrollbars=yes,status=no,toolbar=no");
	myPopup.focus();
}

function NewMail() {
	myPopup=window.open("sendmail.asp?a=reply&m=t",Math.floor(Math.random() * 99999), "height=660,width=700,location=no,menubar=no,resizable=yes,scrollbars=yes,status=no,toolbar=no");
	myPopup.focus();
}
