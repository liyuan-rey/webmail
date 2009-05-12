<link rel=stylesheet href="wm.css">
<script language="javascript" src="wm.js"></script>
<%
If NOT Application("WMAppIsInitialized") Then response.redirect ("diags.asp")
Response.CharSet=Session("Str")(0)
Response.Write "<Body BGColor=" & Application("PageBGColor") & " TOPMARGIN=3 LEFTMARGIN=3 MARGINWIDTH=3 MARGINHEIGHT=3>"
Session.Timeout=Application("SessionTimeout")
Server.ScriptTimeOut =Application("ScriptTimeout")
Set fso = Server.CreateObject("Scripting.FileSystemObject")

'GetLanguage Session("Language")

Const Delim1="@¶@" 'Separates items
Const Delim2="#¶#" 'Separates item name from value

'########################
SUB GetEmailList
'########################
	aTmp=Split(Session("POPAccountList"),VbCrLf)
	For i=0 to Ubound(aTmp)
		aTmp(i)=Trim(aTmp(i))
		If Instr(aTmp(i),",")>0 AND Instr(aTmp(i),";")<>1 Then
			a=Split(aTmp(i),",")
			a(0)=Trim(a(0))
			ReplyToList=ReplyToList & "<Option value='" & Replace(a(0),"'","") & "'>" & Replace(a(0),"'","") & "</option>"
			Session("ReplyToList")=ReplyToList
		End If
	Next
End SUB

'########################
SUB GetFolderNames
'########################
	Folders=Replace(Session("Str")(192),", ",",")
	If Session("CustomFolders")<>"" Then Folders=Folders & "," & Replace(Session("CustomFolders"),VbCrLf,",")
	Folders=Split(Folders,",") 'Comma delimited list of folders stored in an Array
	FolderNames=""
	Num=0
	For i = 0 To Ubound(Folders)
		If Trim(Folders(i))<>"" Then 
			Num=Num+1
			'FolderList=FolderList & "<Option value=" & i & ">" & Folders(i) & "</option>"
			FolderNames=FolderNames & Folders(i) & VbCrLf
		End If
	Next
	Session("FolderNames")=Split(FolderNames,VbCrLf)
	Session("NumFolders")=Num-1
End SUB

'########################
SUB GetLanguage(languagefile)
'########################
If Application("Debugging")=False Then On Error resume next
ReDim aTmp(0)
f=Server.Mappath("lang/"& languagefile)
If fso.fileexists(f) Then
	Session("Language")=languagefile
	Set fr=fso.OpenTextFile(f,1,False)
	aLines=Split(fr.readall,VbCrLf)
	fr.close
	For n = 0 To UBound(aLines)
		s=Trim(aLines(n))
		Pos=Instr(s,"=")
		If s<>"" AND Pos>1 AND Pos<10 AND left(s,1)<>"'" AND left(s,1)<>";" Then 
			If Instr(s,";")>0 Then s=Left(s,Instr(pos,s,";",1)-1)
			If IsNumeric(Left(s,Pos-1)) Then
				i=Int(Left(s,Pos-1))
					If i>Hi Then
					Hi=i
					Redim Preserve aTmp(i)
				End If
				aTmp(i)=EscapeQuote(Trim(Mid(s,Pos+1)))
			End If
		End If
	Next
	If UBound(aTmp)>=Application("NumLangEntries") Then Session("Str")=aTmp Else ShowError("Invalid language file """ & languagefile & """: too few entries found (probably an old file)!")
End If
If Application("LogLevel")>1 Then WriteLogLine "Read language file: " & languagefile
On Error resume next
If IsNumeric(Session("Str")(1)) Then Session.LCID = Session("Str")(1)
Err.Clear
End SUB

'########################
Function ObjectExists(oClass)
'########################
	On Error Resume Next
	Set obj=Server.CreateObject(oClass)
	If Err Then ObjectExists=False Else ObjectExists=True
	Set Obj=Nothing
End Function

'########################
Function WriteToDB(Field, Value)
'########################
OpenConn Conn
SQL= "UPDATE Accounts SET [" & Field & "] = '" & FormatSQL(Value) & "' WHERE UserID =" & Session("UserID")
Conn.execute(SQL)
CloseConn Conn	
End Function

'########################
Function ReadFromDB(Field)
'########################
OpenRS Conn, RS
SQL= "Select [" & Field & "] FROM Accounts WHERE UserID=" & Session("UserID")
Set RS = Conn.Execute(SQL)
ReadFromDB=RS(Field) & ""
RS.Close
End Function

'########################
SUB DelItem(List, ItemNum)
'########################
aTmp=Split(List,Delim1)
List=""
For i=0 To Ubound(aTmp)
	If List="" Then t="" Else t=delim1
	If i<>ItemNum Then List=List & t & aTmp(i)
Next
End Sub

'########################
SUB SetItem(List, ItemNum, Value)
'########################
aTmp=Split(List,Delim1)
If ItemNum<=UBound(aTmp) Then
	s=aTmp(ItemNum)
	aTmp(ItemNum)=Left(s,Instr(s,Delim2)-1) & Delim2 & Left(Value,16384) 'Limit to 16kb per entry
	List=Join(aTmp,Delim1)
End If
End Sub

'########################
SUB AddNewItem(List, ItemName)
'########################
	List=List & Delim1 & Left(ItemName,50) & Delim2
	List=SortList(List,Delim1)
End SUB

'########################
SUB GetListValue(List, ItemNum, Value)
'########################
aTmp=Split(List,Delim1)
If ItemNum<=UBound(aTmp) Then
	s=aTmp(ItemNum)
	Value=Mid(s,Instr(s,Delim2)+Len(Delim2))
Else
	Value=""
End If
End SUB

'########################
Function GetItemList(List, SelectedItemNum)
'########################
If Instr(List,Delim2)>0 Then 
	aTmp=Split(List,Delim1)
	For i= 0 to UBound(aTmp)
		s=aTmp(i)
		If i=SelectedItemNum Then t="selected" Else t=""
		GetItemList=GetItemList & "<Option " & t & " value=" & i & ">" & Left(s,Instr(s,Delim2)-1) & "</option>"
	Next
End If
End Function

'########################
Function SortList(List,Delimiter)
'########################
Set RS=Server.CreateObject("ADODB.RecordSet")
RS.fields.append "Data",203,1 'Memo
RS.Open
a=Split(List,Delimiter)
For i = 0 To Ubound(a)
	RS.Addnew "Data",a(i)
Next
RS.Sort = "Data asc"
NumRecs=RS.Recordcount
For i = 1 To NumRecs 
	If i=NumRecs Then Delimiter=""
 	If RS(0)<>"" Then SortList = SortList & RS(0) & Delimiter
	RS.movenext
Next
Set RS=Nothing
End Function

'########################
Sub AddToAddressbook(list)
'########################
If list<>"" Then
	AddressBook=ReadFromDB("AddressBook")
	List= Replace(List, "'","")
	aTmp=Split(List,";")
	For i=0 To UBound(aTmp)
		aTmp(i)=Trim(aTmp(i))
		If Instr(1,AddressBook, aTmp(i) & VbCrLf,1)=0 Then AddressBook=AddressBook & aTmp(i) & VbCrLf
	Next
	WriteToDB "AddressBook", AddressBook
End If
End Sub

'########################
Function Drawbar(PercentageDone)
'########################
	PercentageDone=Round(PercentageDone)
	If PercentageDone<0 Then PercentageDone=0
	If PercentageDone>100 Then PercentageDone=100
	s=s & "<table align=absmiddle cellpadding=0 cellspacing=0 width='100%' bgcolor=00EE00 height=18><tr><td style='padding-left:0; padding-right:0;'>"
	If PercentageDone>5 Then t="<font size=1>" & PercentageDone & "%</font></td></tr>" Else t="&nbsp;"
	If PercentageDone>0 Then s=s & "<table width=" & PercentageDone & "% bgcolor=FF4444><tr><td align=center>" & t & "</td></tr></table>"
	s=s & "</td></tr></table>"
	Drawbar=s
End Function

'########################
Function ConvClientTime(TheDate)
'########################
	If TheDate<>"" Then ConvClientTime=DateAdd("n",Session("ClientTimeOffset"),TheDate)
End Function

'########################
Function ConvDate(TheDate)
'########################
	OldLCID=Session.LCID
	Session.LCID=Application("DefaultLCID") 'System default Date/time format
	ConvDate=FormatDateTime(TheDate,0)
	Session.LCID=OldLCID
End Function

'########################
Function DBDate(TheDate)
'########################
DBDate = Year(TheDate) & Left("00",2-len(Month(TheDate))) & Month(TheDate) & Left("00",2-len(day(TheDate))) & Day(TheDate) & " " & Formatdatetime(TheDate,4) 
End Function

'########################
Function CreateLinksFromText(str)
'########################
Set objRegExp = New Regexp
objRegExp.IgnoreCase = True
objRegExp.Global = True
'objRegExp.Pattern = "((www.)(|mailto\:|(news|(ht|f)tp(s?))\://){1}[\w\.\/\?&=@#$\+]+)"
Str=Replace(Str,"mailto:","")
objRegExp.Pattern = "(\w+(\.\w+)+@\w+(\.\w+)+)"
'objRegExp.Pattern = "(\w+@\w+(\.\w+)+)"
Str=objRegExp.Replace(str, "<a href='mailto:$1'>$1</a>")
Str=Replace(Str,"www.","http://www.",1,-1,1)
Str=Replace(Str,"http://http://","http://",1,-1,1)
Str=Replace(Str,"https://http://","https://",1,-1,1)
objRegExp.Pattern = "(((news|(ht|f)tp(s?))\://){1}[\w\.\/\?&=@#$\+-;%]+)"
Str=objRegExp.Replace(str, "<a href='$1'>$1</a>")
CreateLinksFromText=Str
End Function

'########################
Function Wrap(str,Length)
'########################
If Len(str)>length Then
	p1=Instr(Length,str," ")
	p2=Instr(Length,str,"/")
	If p2<p1 AND p2<>0 Then p=p2 Else p=p1
	While p>0
		If p>0 Then Str= Left(Str,p) & "<br>" & Mid(Str,p)
		p1=Instr(Length+p +4,str," ")
		p2=Instr(Length+p +4,str,"/")
		If p2<p1 AND p2<>0 Then p=p2 Else p=p1
	Wend	
End If
Wrap=Str
End Function

'########################
Sub StripExternalLinks(strHTML,strStripped, MatchFound)
'########################
strStripped=strHTML
If strHTML<>"" Then
	Set objRegExp = New Regexp
	objRegExp.IgnoreCase = True
	objRegExp.Global = True
	'### Remove links
	objRegExp.Pattern = "<[^>]*http:[^>]*>"
	If objRegExp.test(strHTML) Then
		MatchFound=True
		strStripped = objRegExp.Replace(strHTML, "")
	End If
	Set objRegExp = Nothing
	'### Remove script popups
	strStripped=Replace(strStripped,"window.open","window.focus")
End If
End Sub

'########################
Function stripHTML1(strHTML)
'########################
If strHTML<>"" Then
	strHTML=Replace(strHTML,"<br>",VbCrLf,1,-1,1)
	Set objRegExp = New Regexp
	objRegExp.IgnoreCase = True
	objRegExp.Global = True
	objRegExp.Pattern = "<(.|\n)+?>"
	strOutput = objRegExp.Replace(strHTML, "")
	strOutput = Replace(strOutput, "<", "&lt;")
	strOutput = Replace(strOutput, ">", "&gt;")
	stripHTML = strOutput
	Set objRegExp = Nothing
End If
End Function

'########################
Function stripHTML(strHTML)
'########################
If strHTML<>"" Then
	Set regEx = New RegExp  
	regEx.IgnoreCase = True 
	regEx.Global = True
	regEx.Pattern = " " 
	StrHTML = regEx.Replace(StrHTML, " #@!")
	
	'Add special character to certain tags to detect groups of html-elements
	regEx.Pattern = "(</pre[^<]*>|</script[^<]*>|</a[^<]*>)" 
	StrHTML = regEx.Replace(StrHTML, "$1" & " ")
	
	'Remove <head>, hyperlinks and script
	regEx.Pattern = "<head[\w\W]+</head>|<a href[^ ]*</a> |<script[^ ]*</script> "
	StrHTML = regEx.Replace(StrHTML, "")
	
	'Remove lf and cr (except between <pre>-tags)
	regEx.Pattern = "(<pre>[^ ]*</pre>) |[\r\n]" 
	StrHTML = regEx.Replace(StrHTML, "$1")
	
	'Add crlf at certain html-tags (only one lf at </pre></p>)
	regEx.Pattern = "(<p>|</p>|<pre>|</pre></p>|</pre>|<BR>)" 
	StrHTML = regEx.Replace(StrHTML, "$1"&vbcrlf)
	
	'Remove html-tags (don't remove numeric comparisation's using < >)
	regEx.Pattern = "(<\s*\d+[^<]*>)|<[^<]+>" 
	StrHTML = regEx.Replace(StrHTML, "$1")
	
	'Replace code by  
	regEx.Pattern = " #@!" 
	StrHTML = regEx.Replace(StrHTML, " ")
	
	'Remove multiple linefeeds
	regEx.Pattern = "[\n\r]{3,}" 
	regEx.IgnoreCase = True 
	regEx.Global = True
	StrHTML = regEx.Replace(StrHTML, vbcrlf & vbcrlf)
	
	'Remove leading and trailing cr's and lf's
	regEx.Pattern = "^[\r\n]*([^\r\n].*)" 
	StrHTML = regEx.Replace(StrHTML, "$1")
	regEx.Pattern = "(.*[^\r\n])[\r\n]*$" 
	StrHTML = regEx.Replace(StrHTML, "$1")

	'General tags
	regEx.Pattern = "<(.|\n)+?>"
	StrHTML = regEx.Replace(StrHTML, "")
	StrHTML = Replace(StrHTML, "&nbsp;", " ",1,-1,1)

	stripHTML=StrHTML
End If
End Function

'########################
Function AttachmentTypeOK(fn)
'########################
strFileType = fso.getExtensionName(fn)
AttachmentTypeOK=(Instr(1,"," & Session("BlockAttachmentTypes") & ",",strFileType,1)=0)
End Function

'########################
Function GetMaxFolderID
'########################
OpenRS Conn, RS
SQL = "SELECT MAX(FolderID) AS MaxFolderID FROM Messages WHERE UserID=" & Session("UserID")
Set RS = Conn.Execute(SQL)
If NOT ISNULL(RS("MaxFolderID")) Then GetMaxFolderID=RS("MaxFolderID") Else GetMaxFolderID=0
RS.Close
End Function

'########################
Function GetNumAccounts
'########################
OpenRS Conn, RS
SQL = "SELECT Count(UserID) AS NumAccounts FROM Accounts"
Set RS = Conn.Execute(SQL)
If NOT ISNULL(RS("NumAccounts")) Then GetNumAccounts=RS("NumAccounts") Else GetNumAccounts=0
CloseRS Conn, RS
End Function

'########################
Sub SetRead(ID,Status)
'########################
a=Split(ID, ", ")
For i= 0 to ubound(a)
	If trim(a(i))<>"" Then
		OpenRS Conn, RS
		SQL = "SELECT IsNew, ReadStatus From Messages WHERE MsgGUID='" & a(i) & "' AND UserID=" & Session("UserID")
		RS.Open SQL,Conn , 3,3
		If NOT ISNULL(RS("ReadStatus")) Then
			If Status=1 Then
				RS("IsNew")=1
				If RS("ReadStatus")<2 Then RS("ReadStatus")=0
			Else
				RS("IsNew")=0
				If RS("ReadStatus")<2 Then RS("ReadStatus")=1
			End If
			RS.Update
		End If
		CloseRS Conn, RS
	End If
Next
End Sub

'########################
Function SendEmail(oMsg)
'########################
On error resume next
Set oSMTP=Server.CreateObject("FathMAIL.SMTP")
If Application("UseSMTPAuthentication") Then
	oSMTP.LoginMethod =2
	oSMTP.Username=Application("SMTPAccount")
	oSMTP.Password=Application("SMTPPass")
End If
oSMTP.ServerAddr=Application("SMTPMailServer")
oSMTP.ServerPort=Application("SMTPPort")
oSMTP.Send oMsg
'LastResponse=oSMTP.LastCommandResponse
Set oSMTP=Nothing
SendEmail=(Err=0)
If NOT SendEmail Then 
	ShowError Session("Str")(105)
Else
	Session("Bandwidth")=Session("Bandwidth") + Round(oMsg.GetSize/1024)
End If
End Function

'########################
Function TimePassed(MyDate)
'########################
aTmp=Split(Session("Str")(196),",")
If Ubound(aTmp)<>5 Then aTmp=Array("Years","Months","Weeks","Days","Hours","Minutes")
M=DateDiff("n",MyDate,Now)
If M<0 Then M=0
If MyDate="" OR NOT IsDate(MyDate) Then
	TimePassed=""
ElseIf M>365*24*60 Then
	TimePassed=Round(M/365/24/60) & " " & aTmp(0)
ElseIf M>60*24*60 Then
	TimePassed=Round(M/30/24/60) & " " & aTmp(1)
ElseIf M>13*24*60 Then
	TimePassed=Round(M/7/24/60) & " " & aTmp(2)
ElseIf M>2*24*60 Then
	TimePassed=Round(M/24/60) & " " & aTmp(3)
ElseIf M>60 Then
	TimePassed=Round(M/60) & " " & aTmp(4)
Else
	TimePassed=M & " " & aTmp(5)
End If
End Function

'########################
Function MD5Digest(strText)
'########################
	Set oCrypt=Server.CreateObject("FathCrypt.CFathCrypt.1")
	MD5Digest=oCrypt.GetMD5Digest(strText)
	Set oCrypt=Nothing
End Function

'########################
Function EncryptText(strText)
'########################
On error resume next
EncryptText=strText
strKey=Application("EncryptionKey")
If strText<>"" AND strKey<>"" Then
	Set oCrypt=Server.CreateObject("FathCrypt.CFathCrypt.1")
	oCrypt.key = strKey
	EncryptText=oCrypt.EncryptString(strText)
	Set oCrypt=Nothing
End If
End Function

'########################
Function DecryptText(strText)
'########################
On error resume next
DecryptText=strText
strKey=Application("EncryptionKey")
If strText<>"" AND strKey<>"" Then
	Set oCrypt=Server.CreateObject("FathCrypt.CFathCrypt.1")
	oCrypt.key = strKey
	DecryptText=oCrypt.DecryptString(strText)
	Set oCrypt=Nothing
End If
End Function

'########################
Function HexEncode(Str)
'########################
For n = 1 to len(str)
	s = s & Right("0" & Hex(Asc(Mid(Str,n,1))),2)
Next
HexEncode = s
End Function

'########################
Function HexDecode(Str)
'########################
For n = 1 to Len(Str) Step 2
	s=s & Chr("&H" & Mid(Str,n,2))
Next
HexDecode = s
End Function

'########################
Function IsInDeletionHistory(ID)
'########################
IsInDeletionHistory=(Instr(1,", " & Session("DeletionHistory") & ", ",", " & ID & ", ",1)>0 )
End Function

'########################
SUB AddToDeletionHistory(ID)
'########################
dh=Session("DeletionHistory")
aTmp=Split(dh,", ")
If UBound(aTmp)<Application("MaxDeletionHistoryEntries") Then
	Session("DeletionHistory")=ID & ", " & dh
Else
	Redim preserve aTmp(Application("MaxDeletionHistoryEntries")-1)
	Session("DeletionHistory")=ID & ", " & Join(aTmp,", ") & ", "
End If
End SUB

'########################
SUB DelFromDeletionHistory(ID)
'########################
Session("DeletionHistory")=Replace(Session("DeletionHistory"), ID & ", ","")
End SUB

'########################
Sub DelMsg(ID, FullDelete)
'########################
OpenConn Conn
aTmp=Split(ID, ", ")
For i= 0 to ubound(aTmp)
	If Trim(aTmp(i))<>"" Then
		If FullDelete Then'### Remove from Deleted items: remove file + DB
			If Application("LogLevel")>1 Then WriteLogLine "Deleting message from WM: " & aTmp(i)
			fp=GetMailPath(aTmp(i))
			If fso.fileexists(fp) Then fso.deletefile fp,True
			SQL="DELETE FROM Messages WHERE MsgGUID='" & aTmp(i) & "' AND UserID=" & Session("UserID")
			Conn.execute(SQL)
			AddToDeletionHistory aTmp(i)
		Else '### Move message to "Deleted items"
			SQL= "UPDATE Messages SET FolderID=1, DateRetrieved='" & ConvDate(Now) & "' WHERE MsgGUID='" & aTmp(i) & "' AND UserID=" & Session("UserID")
			Conn.execute(SQL)
		End If
	End If
Next
Session("MailBoxSize")=GetMailboxSize
CloseConn Conn
End Sub

'########################
Sub SaveAttachments(oMsg,ID)
'########################
Separator = " | "
AttCnt=oMsg.GetAttachmentCount
For i = 0 To AttCnt-1
	fn=Trim(oMsg.GetAttachmentName(i))
	fn=RemoveIllegalChars(fn)
	If fn="" Then fn="Att" & i & ".dat"
	If fso.getExtensionName(fn)="" Then fn=fn & ".dat"
	If AttachmentTypeOK(fn) Then
		fs=oMsg.GetAttachmentSize(i)
		fp=GetFullTempPath(fn, ID)
		If fso.fileexists(fp) then fso.deletefile fp,True
		oMsg.SaveAttachment i, fp
		URL="readmail.asp?a=download&ID="& ID & "&f=" & Server.URLEncode(Replace(fn,"&","%26"))
		If Application("OpenAttachInPopup") Then 
			AttachmentLinks = AttachmentLinks & "<a href='javascript:openMainPopup(""" & URL & """);'><font size=1>" & Truncate(fn,20) & " (" & SizeString(fs) & ")" & "</font></a>&nbsp;&nbsp;"
		Else
			AttachmentLinks = AttachmentLinks & "<a href="& URL & "><font size=1>" & Truncate(fn,20) & " (" & SizeString(fs) & ")" & "</font></a>&nbsp;&nbsp;"
		End If
		Attachments=Attachments & fp & "|"
		TotalSize=TotalSize + fs
	Else
		AttachmentLinks = AttachmentLinks & "<font size=1>" & Truncate(fn,20) & " (Blocked)</font></a>&nbsp;&nbsp;"
	End If
Next
Session("AttSize_" & ID)=TotalSize
Session("AttLinks_" & ID)=AttachmentLinks
Session("AttList_" & ID)=Attachments
End Sub

'########################
Function RemoveIllegalChars(str)
'########################
	str=Replace(str,"/","_")
	str=Replace(str,"\","_")
	str=Replace(str,"?","_")
	str=Replace(str,"*","_")
	str=Replace(str,">","_")
	str=Replace(str,"<","_")
	str=Replace(str,"|","_")
	str=Replace(str,":","_")
	str=Replace(str,"'","_")
	str=Replace(str,"#","_")
	str=Replace(str,"+","_")
	'str=Replace(str,"!","_")
	'str=Replace(str,",","_")
	str=Replace(str,"""","_")
	RemoveIllegalChars=Str
End Function

'########################
Function OpenMessageFile(MsgGUID)
'########################
If Application("Debugging")=False Then On Error resume next
If MsgGUID<>"" Then 
	fp=GetMailPath(MsgGUID)
	If NOT fso.fileexists(fp) Then ShowError "This message was not found: " & MsgGUID
	Set oMsg=Server.CreateObject("FathMail.Message")
	If Session("EncryptMessages") Then
		Set oCrypt=Server.CreateObject("FathCrypt.CFathCrypt.1")
		oCrypt.key = Application("EncryptionKey")
		If oCrypt.IsCrypted(fp) Then
			RawMsg = oCrypt.DecryptFileToMemory(fp)
			oMsg.PutRaw RawMsg
		Else
			oMsg.LoadFromFile fp
		End If
		Set oCrypt=Nothing
	Else
		oMsg.LoadFromFile fp
	End If
	Set OpenMessageFile=oMsg
End If
End Function

'########################
Function SaveMessageFile(oMsg,MsgGUID)
'########################
If Application("Debugging")=False Then On Error resume next

If MsgGUID<>"" Then
	fp=GetMailPath(MsgGUID)
	If Session("EncryptMessages") Then
		Set oCrypt=Server.CreateObject("FathCrypt.CFathCrypt.1")
		oCrypt.key = Application("EncryptionKey")
		oCrypt.EncryptFileFromMemory oMsg.GetRaw, fp
		Set oCrypt=Nothing
	Else
		oMsg.SaveToFile fp
	End If
End If
SaveMessageFile=(Err=0)
End Function

'########################
Function GetMailboxSize
'########################
OpenRS Conn, RS
SQL = "SELECT SUM(MsgSize) AS TotalSize FROM Messages WHERE UserID=" & Session("UserID")
Set RS = Conn.Execute(SQL)
If NOT ISNULL(RS("TotalSize")) Then GetMailboxSize=RS("TotalSize") Else GetMailboxSize=0
RS.Close
End Function

'########################
Function FormatSQL(str)
'########################
FormatSQL=Replace(Str,"'","''")
End Function

'########################
Function GetFullTempPath(fn,ID)
'########################
If ID<>"" Then
	tp=Session("TempFolder") & ID & "\" 
	If NOT fso.folderexists(tp) Then fso.createfolder(tp)
	GetFullTempPath=tp & fn
Else
	GetFullTempPath=Session("TempFolder") & fn
End If
End Function

'########################
Function GetMailPath(MsgGUID)
'########################
GetMailPath=Session("MailFolder") & MsgGUID & ".EML"
End Function

'########################
SUB OpenConn(Conn)
'########################
Set Conn=Server.CreateObject("ADODB.Connection")
Conn.Mode = 3
Conn.ConnectionTimeout=20
Conn.Open Application("DBConnection")
End SUB

'########################
SUB CloseConn(Conn)
'########################
Conn.Close
Set Conn=Nothing
End SUB

'########################
SUB OpenRS(Conn,RS)
'########################
Set Conn=Server.CreateObject("ADODB.Connection")
Set RS=Server.CreateObject("ADODB.RecordSet")
Conn.Mode = 3
Conn.ConnectionTimeout=20
Conn.Open Application("DBConnection")
End SUB

'########################
SUB CloseRS(Conn,RS)
'########################
On error resume next
RS.Close
Set RS=Nothing
Conn.Close
Set Conn=Nothing
End SUB

'########################
Function MsgExistsInDB(MsgGUID)
'########################
OpenRS Conn, RS
SQL = "SELECT MsgGUID FROM Messages WHERE MsgGUID='" & MsgGUID & "' AND userID=" & Session("UserID")
Set RS = Conn.Execute(SQL)
MsgExistsInDB=NOT RS.EOF
CloseRS Conn, RS
End Function

'########################
Function MsgFileExists(MsgGUID)
'########################
fn=GetMailPath(MsgGUID)
MsgFileExists=fso.FileExists(fn) 
End Function

'########################
Function CreatePath(sPath)
'########################
If fso.folderexists(sPath) Then
	CreatePath=True
ElseIf Instr(sPath,"\")>0 Then
	pos=Instr(3,sPath,"\",1)
	aTmp=Split(Mid(sPath,pos+1),"\")
	sNewPath=Left(sPath,pos-1)
	For n = 0 to Ubound(aTmp)
		On Error resume next 'Ignore permission problems on higher levels
		sNewPath = sNewPath & "\" & aTmp(n)
		If aTmp(n)<>"" AND NOT fso.FolderExists(sNewPath) Then fso.CreateFolder sNewPath
	Next
	If fso.FolderExists(sPath) Then CreatePath=True Else CreatePath=False
End If
End Function

'########################
Function EncHTML(sHtml)
'########################
sHtml=Replace(sHtml,"<","&lt;")
sHtml=Replace(sHtml,">","&gt;")
sHtml=Replace(sHtml,VbCrLf,"<br>") 
EncHTML=sHtml
End Function

'########################
Function StartCapital(str)
'########################
	s=LCase(str)
	chLast=" "
	For Pos=1 To Len(s)
	 	ch=Mid(s,Pos,1)
	 	If Instr(" _\[(",chLast)>0 then t=t & Ucase(ch) Else t=t & ch
	 	chLast=ch
	Next
	StartCapital=Replace(t," of "," of ",1,-1,1)
	StartCapital=Replace(t," a "," a ",1,-1,1)
End Function

'########################
SUB ShowError(Info)
'########################
	If IsObject(Conn) Then Set Conn=Nothing
	If IsObject(RS) Then Set RS=Nothing
	If IsObject(fso) Then Set Fso=Nothing
	If IsObject(oMsg) Then Set oMsg=Nothing
	Response.Clear
	Response.Write "<style type='text/css'>body, td, pre { font-family: Tahoma, Arial, Helvetica; font-size: 10pt; color: #000000 }</style>"
	Response.Write "<br><table width=400 align=center border='1' cellpadding='6' cellspacing='0' bordercolor='#444444'>"
	Response.Write "<tr><td align='center' bgcolor=666688><font color=FFFFFF size=2>"
	Response.Write "<b>Sorry, an error occurred!</b></td></tr><tr><td bgcolor=EEEEEE>"
	Response.Write "<table>"
	Response.Write "<tr><td valign=top><img src=img/stop.gif border=0></td><td>" & Info & "</td></tr>"
	If err.description <>"" Then Response.Write "<tr><td></td><td><i>Description: " & err.description & "</i></td></tr>"
	Response.Write "</table>"
	Response.Write "<br><center><a href='javascript:history.go(-1);'>Back</a>"
	If Session("IsLoggedin") Then Response.Write " | <a href=readmail.asp>Inbox</a></center>"
	Response.end
End SUB

'########################
SUB WriteLogLine(msg)
'########################
	On Error resume next
	If err<>0 then sErr=VbTab & "Error: " & err.description Else sErr=""
	Set fw=fso.openTextFile(Application("LogFile"),8,true)
	fw.writeline Convdate(Now) & VbTab & Session("IP") & VbTab & Session("User") & VbTab & Msg & sErr
End SUB

'########################
Function SizeString(size)
'########################
If NOT Isnumeric(Size) OR Size="" Then Exit Function
Size=Clng(Size)
If Size=0 Then
	SizeString="0 B"
ElseIf Size>1024*1024*1024 Then
	SizeString=Round(Size/1024/1024/1024,1) & " GB"
ElseIf Size>10*1024*1024 Then
	SizeString=Round(Size/1024/1024) & " MB"
ElseIf Size>1024*1024 Then
	SizeString=Round(Size/1024/1024,1) & " MB"
ElseIf Size<1024 Then
	SizeString="1 kB"
ElseIf Size>500*1024 AND Size<=1024*1024 Then
	SizeString=Round(Size/1024/1024,1) & " MB"
Else
	SizeString=Round(Size/1024) & " kB"
End If
End Function

'########################
Function Truncate(str,length)
'########################
	If len(str)>length Then Truncate=Left(str ,length) & "..." Else Truncate=str
End Function

'##################
Function RandomString(length)
'##################
Randomize
For n= 1 to length
	s=s+ Chr(40 + rnd()*86)
Next
RandomString=s
End Function

'########################
SUB ShowInfo(Info)
'########################
	Response.Clear
	Response.Write "<style type='text/css'>body, td, pre { font-family: Tahoma, Arial, Helvetica; font-size: 10pt; color: #000000 }</style>"
	Response.Write "<br><table width=400 align=center border='1' cellpadding='6' cellspacing='0' bordercolor='#444444'>"
	Response.Write "<tr><td align='center' bgcolor=666688><font color=FFFFFF size=2>"
	Response.Write "<b>Information</b></td></tr><tr><td bgcolor=EEEEEE>"
	Response.Write "<table>"
	Response.Write "<tr><td valign=top><img src=img/info.gif border=0></td><td>" & Info & "</td></tr>"
	Response.Write "</table>"
	Response.Write "<center>"
	Response.Write "<a href='javascript:history.go(-1);'>Back</a>"
	If Session("IsLoggedin") Then Response.Write " | <a href=readmail.asp>Inbox</a>"
	Response.Write "</center>"
	Response.end
End SUB

'########################
SUB Download(f)
'########################
'On Error resume next
Server.ScriptTimeout=Application("LongScriptTimeout")
strFileType = LCase(fso.getExtensionName(f))
Select Case strFileType
	Case "htm", "html"
		ContentType = "text/html"
	Case "eml"
		ContentType = ""
	Case "xml"
		ContentType = "text/xml"
	Case "asp"
		ContentType = "text/asp"
	Case "txt"
		ContentType = "text/plain"
	Case "doc", "dot"
		ContentType = "application/msword"
	Case "xls", "xlt"
		ContentType = "application/vnd.ms-excel"
	Case "rtf"
		ContentType = "application/rtf"
	Case "ppt"
		ContentType = "application/x-mspowerpoint"
	Case "gif"
		ContentType = "image/gif"
	Case "bmp"
		ContentType = "image/bmp"
	Case "jpg", "jpeg"
		ContentType = "image/jpeg"
	Case "pdf"
		ContentType = "application/pdf"
	Case "zip"
		ContentType = "application/zip"
	Case "wav"
		ContentType = "audio/wav"
	Case "mid"
		ContentType = "audio/midi"
	Case "mp3"
		ContentType = "audio/mpeg"
	Case "asf"
		ContentType = "video/x-ms-asf"
	Case "avi"
		ContentType = "video/avi"
	Case "mpg", "mpeg"
		ContentType = "video/mpeg"
	Case Else
		ContentType = "application/octet-stream"
End Select

Response.Clear
Response.AddHeader "Content-disposition","inline; filename=" & fso.getfilename(f)
Response.ContentType = ContentType
Set ObjStream=Server.CreateObject("Adodb.stream")
ObjStream.Open
ObjStream.Type=1
ObjStream.LoadFromFile(f)
TotalSize=ObjStream.Size
Response.AddHeader "Content-Length", TotalSize
BlockSize=262144 
For lBlocks = 1 To TotalSize \ BlockSize
	If NOT Response.IsClientConnected Then Exit For
	Response.BinaryWrite objStream.Read(BlockSize)
	Response.Flush
Next
If TotalSize>0 Then Response.BinaryWrite objStream.Read(TotalSize Mod BlockSize)
ObjStream.Close
Set ObjStream=Nothing
Session("Bandwidth")=Session("Bandwidth") + Round(TotalSize/1024)
'Response.end
End SUB

'########################
Function EscapeQuote(str)
'########################
	If str<>"" Then 
		EscapeQuote=Replace(str,"'","&#39;")
	Else
		EscapeQuote=str
	End If
End Function

'########################
Function CheckEmail(Email)
'########################
If Email="" Then Exit Function
aEmail=Split(email,";")
For n=0 To Ubound(aEmail)
	aEmail(n)=Trim(aEmail(n))
	If aEmail(n)<>"" Then
		CheckEmail=False
		If Application("AllowedDomains")="" Then
			If Instr(aEmail(n),"@")>0 AND Instr(aEmail(n),".")>0 AND Len(aEmail(n))>5 AND NOT Isnumeric(mid(aEmail(n), instrrev(aEmail(n),".")+1)) Then CheckEmail=True '### Webmail does not check for email but for host name, no @ present!
		Else
			aTmp=Split(Trim(LCase(Application("AllowedDomains"))),",")
			For i=0 to Ubound(aTmp)
				s=Trim(aTmp(i))
				If InstrRev(aEmail(n),s,-1,1)=Len(aEmail(n))-Len(s)+1 Then
					CheckEmail=True
					Exit For
				End If
			Next
		End If
		If Application("DeniedDomains")<>"" Then
			aTmp=Split(Trim(LCase(Application("DeniedDomains"))),",")
			For i=0 to Ubound(aTmp)
				s=Trim(aTmp(i))
				If InstrRev(aEmail(n),s,-1,1)=Len(aEmail(n))-Len(s)+1 Then
					CheckEmail=False
					Exit For
				End If
			Next
		End If
		If CheckEmail=False Then Exit For
	End If
Next
End Function

'########################
Function CheckDomain(Domain)
'########################
If Domain="" Then Exit Function
aDomain=Split(Domain,";")
For n=0 To Ubound(aDomain)
	aDomain(n)=Trim(aDomain(n))
	If aDomain(n)<>"" Then
		CheckDomain=False
		If Application("AllowedDomains")="" Then
			CheckDomain=True
		Else
			aTmp=Split(LCase(Application("AllowedDomains")),",")
			For i=0 to Ubound(aTmp)
				s=Trim(aTmp(i))
				If InstrRev(aDomain(n),s,-1,1)=Len(aDomain(n))-Len(s)+1 Then 'Ends with...
					CheckDomain=True
					Exit For
				End If
			Next
		End If
		If Application("DeniedDomains")<>"" Then
			aTmp=Split(Trim(LCase(Application("DeniedDomains"))),",")
			For i=0 to Ubound(aTmp)
				s=Trim(aTmp(i))
				If InstrRev(aDomain(n),s,-1,1)=Len(aDomain(n))-Len(s)+1 Then
					CheckDomain=False
					Exit For
				End If
			Next
		End If
		If CheckDomain=False Then Exit For
	End If
Next
End Function
%>
