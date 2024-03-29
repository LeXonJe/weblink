'    ________  ________  ___  ________  _______   ________ _________   
'   |\   __  \|\   ___ \|\  \|\   __  \|\  ___ \ |\   ____\\___   ___\ 
'   \ \  \|\  \ \  \_|\ \ \  \ \  \|\  \ \   __/|\ \  \___\|___ \  \_| 
'    \ \   ____\ \  \ \\ \ \  \ \   _  _\ \  \_|/_\ \  \       \ \  \  
'     \ \  \___|\ \  \_\\ \ \  \ \  \\  \\ \  \_|\ \ \  \____   \ \  \ 
'      \ \__\    \ \_______\ \__\ \__\\ _\\ \_______\ \_______\  \ \__\
'       \|__|     \|_______|\|__|\|__|\|__|\|_______|\|_______|   \|__|
'
'    A script to handle b-PAC Prints via Weblink.

''''''''''''''''''''''''''''''''''
'' UrlParser (https://github.com/dudleycodes/VBScript-UrlParser/blob/master/UrlParser.asp)
''      Simple class to parse a URL into its components.
''
'' [Notes]
''      • Creates absolute url from relative url; "dir1/dir2/../dir3" becomes "dir1/dir3"
''      • An expansion idea would be to build this into a UrlBuilder instead of just a parser. It is
''          for this reason the class is build with properties rather than functions.
''
'' [How To Use]
''      Dim Url: Set Url = New UrlParser
''      Url.path = "https://www.server.com/dir1/dir2/../dir3/file.html?i=3&t=5"
''      Response.Write(Url.filename)
''
'' [Exposed Properties (Read Only)]
''      .directories            (array) Returns an array of all directories in the url
''      .directoryCount         (integer) Returns number of directories
''      .directoryString        (string) String containing all directories separated by /
''      .file                   (sting) Filename if any
''      .filename               (string) Alias of .file
''      .fileExtension          (string) File extension (if any)
''      .fullPath               (string) Fully qualitifed url string
''      .host                   (string) Name of host (i.e. server name)
''      .hostname               (string) Alias of .host
''      .pathSeparator          (string) Path separator.  Usually "/"
''      .queries                (dictionary) Collection of url queries:  key => value
''      .queryCount             (integer) Number of query variables
''      .queryString            (string) Query string
''      .scheme                 (string) Scheme used (usually "http" or "https")
''
'' [Exposed Functions]
''      .directory(index)       (string) Returns specified directory name.  Index starts at zero.
''                                  example: In "dir1/dir2/dir3" .directory(1) yields "dir2"
''''''''''''''''''''''''''''''''''
Class UrlParser
    Private m_directoryArray
    Private m_file
    Private m_fileExtension
    Private m_folder
    Private m_host
    Private m_path
    Private m_pathSeparator
    Private m_scheme
    Private m_queryDictionary

    Public Property Get directories
        directories = array()
        If NOT IsNull(m_directoryArray) Then
            directories = m_directoryArray
        End If
    End Property

    Public Function directory(index)
        index = CInt(index)
        If index > UBound(m_directoryArray) OR index < LBound(m_directoryArray) Then
            directory = Null
        Else
            directory = CStr(m_directoryArray(index))
        End If
    End Function

    Public Property Get directoryCount
        directoryCount = 0
        If NOT IsNull(m_directoryArray) Then
            directoryCount = CInt(UBound(m_directoryArray) + 1 - LBound(m_directoryArray))
        End If
    End Property

    Public Property Get directoryString
        directoryString = ""
        If NOT IsNull(m_directoryArray) Then
            directoryString = Join(m_directoryArray, m_pathSeparator)
        End If
    End Property

    Public Property Get file
        file = Null
        If NOT IsEmpty(m_file) Then
            file = CStr(m_file)
        End If
    End Property

    Public Property Get filename
        filename = me.file
    End Property

    Public Property Get fileExtension
        Dim i: i = InStrRev(me.file, ".")
        fileExtension = Null
        If i > 0 Then
            fileExtension = Mid(me.file, i + 1)
        End If
    End Property

    Public Property Get fullPath
        fullPath = CStr(me.scheme & "://" & me.host)
        If LEN(me.directoryString) > 0 Then
            fullPath = fullPath & m_pathSeparator & me.directoryString
        End If
        If LEN(me.file) > 0 Then
            fullPath = fullPath & m_pathSeparator & me.file
        End If
        If LEN(me.queryString) > 0 Then
            fullPath = fullPath & me.queryString
        End If
    End Property

    Public Property Get host
        host = Null
        If NOT IsEmpty(m_host) Then
            host = CStr(m_host)
        End If
    End Property

    Public Property Get hostname
        hostname = me.host
    End Property

    Public Property Get path
        path = Null
        If NOT IsEmpty(m_path) Then
            path = m_path
        End If
    End Property

    Public Property Let path(value)
        Dim i: i = ""
        Dim temp: temp = ""
        Dim temp2: temp2 = ""
        Dim tempPath: tempPath = ""
        Dim regEx: Set regEx = New RegExp
        m_path = CStr(Trim(value))
        'Determine Path Separator
        If InStr(m_path, "/") Then
            m_pathSeparator = "/"
            m_path = Replace(m_path, "\", m_pathSeparator)
        Else
            m_pathSeparator = "\"
            m_path = Replace(m_path, "/", m_pathSeparator)
        End If
        tempPath = m_path
        
        'Determine scheme/host
        i = InStr(tempPath, "://")
        If i > 1 Then
            m_scheme = Left(tempPath, i - 1)
            tempPath = Replace(tempPath, m_scheme & "://", "")
            m_scheme = LCase(m_scheme)
            'Determine host
            m_host = Left(tempPath, InStr(tempPath, m_pathSeparator) - 1)
            tempPath = Replace(tempPath, m_host, "")
        Else
            'Derive scheme
            m_scheme = "http"
            If LCase(Request.ServerVariables("HTTPS")) = "on" Then
                m_scheme = "https"
            End If
            'Derive host
            m_host = Request.ServerVariables("SERVER_NAME")
        End If
        'Add current base path if necessary
        If InStr(tempPath, "../") = 1 Or InStr(tempPath, m_pathSeparator) > 1 Then
            temp = Request.ServerVariables("PATH_INFO")
            tempPath = MID(temp, 1, InStrRev(temp, m_pathSeparator))  & tempPath
        End If
        'Remove any leading path separator
        If InStr(tempPath, m_pathSeparator) = 1 Then
            tempPath = Right(tempPath, LEN(tempPath) - 1)
        End If
        'Resolve any ../ references
        Do
            i = InStr(tempPath, "../")
            If isNull(i) Then
                i = 0
            ElseIf i = 1 Then
                tempPath = MID(tempPath, 4)
            ElseIf i > 0 Then
                'Remove ../ and the preceding directory
                tempPath = Left(tempPath, InStrRev(tempPath, m_pathSeparator, i - 2)) & MID(tempPath, i + 3)
            End If
        Loop While i > 0
        'Process URL Queries
        m_queryDictionary = Null
        i = InStr(1, tempPath, "?")
        If i > 0 Then
            temp = MID(tempPath, i + 1)
            tempPath = Replace(tempPath, "?" & temp, "")
            temp = Split(temp, "&")
            If UBound(temp) <> -1 Then
                Set m_queryDictionary = CreateObject("Scripting.Dictionary")
                For i = LBound(temp) To UBound(temp)
                    temp2 = Split(temp(i), "=")
                    m_queryDictionary.item(temp2(0)) = temp2(1)
                Next
            End If
        End If
        'Process filename
        If InStr(tempPath, m_pathSeparator) Then
            i = InStr(InStrRev(tempPath, m_pathSeparator), tempPath, ".")
        Else
            i = InStr(tempPath, ".")
        End If
        If i Then
            temp = split(tempPath, m_pathSeparator)
            m_file = temp(ubound(temp)) 
            i = Null
            tempPath = Replace(tempPath, m_file, "")
            'Remove trailing path separator
            If Right(tempPath, 1) = m_pathSeparator Then
                tempPath = Left(tempPath, LEN(tempPath) - 1)
            End If
        End If
        
        'Directory Array
        m_directoryArray = Split(tempPath, m_pathSeparator)
        If UBound(m_directoryArray) = -1 Then
            m_directoryArray = Null
        End If
        
        tempPath = Null
    End Property

    Public Property Get pathSeparator
        pathSeparator = CStr(m_pathSeparator)
    End Property

    Public Property Get queries
        Dim temp: Set temp = CreateObject("Scripting.Dictionary")
        If IsNull(m_queryDictionary) Then
            Set queries = temp
        Else
            Set queries = m_queryDictionary ' https://stackoverflow.com/questions/140002/vbscript-how-to-utiliize-a-dictionary-object-returned-from-a-function
        End If
    End Property

    Public Property Get queryCount
        queryCount = 0
        If NOT IsNull(m_queryDictionary) Then
            queryCount = CInt(m_queryDictionary.Count)
        End If
    End Property

    Public Property Get queryString
        Dim element: element = ""
        queryString = ""
        If NOT IsNull(m_queryDictionary) Then
            For Each element in m_queryDictionary
                If queryString = "" Then
                    queryString = "?"
                Else
                    queryString = queryString & "&"
                End If
                queryString = queryString & element & "=" & m_queryDictionary(element)
            Next
        End If
    End Property

    Public Property Get scheme
        scheme = Null
        If NOT IsEmpty(m_scheme) Then
            scheme = CStr(m_scheme)
        End If
    End Property

End Class

' Hippity Hoppity This Code is now my property (https://stackoverflow.com/questions/17880395/decoding-url-encoded-utf-8-strings-in-vbscript)
Function decodeURL(str)
    set list = CreateObject("System.Collections.ArrayList")
    strLen = Len(str)
    for i = 1 to strLen
        sT = mid(str, i, 1)
        if sT = "%" then
            if i + 2 <= strLen then
                list.Add cbyte("&H" & mid(str, i + 1, 2))
                i = i + 2
            end if
        else
            list.Add asc(sT)
        end if
    next
    depth = 0
    for each by in list.ToArray()
        if by and &h80 then
            if (by and &h40) = 0 then
                if depth = 0 then Err.Raise 5
                val = val * 2 ^ 6 + (by and &h3f)
                depth = depth - 1
                if depth = 0 then
                    sR = sR & chrw(val)
                    val = 0
                end if
            elseif (by and &h20) = 0 then
                if depth > 0 then Err.Raise 5
                val = by and &h1f
                depth = 1
            elseif (by and &h10) = 0 then
                if depth > 0 then Err.Raise 5
                val = by and &h0f
                depth = 2
            else
                Err.Raise 5
            end if
        else
            if depth > 0 then Err.Raise 5
            sR = sR & chrw(by)
        end if
    next
    if depth > 0 then Err.Raise 5
    decodeURL = sR
End Function

Function getUrlArg
    Set args = Wscript.Arguments

    If args.Count > 0 Then
        getUrlArg = args(0)
    End If
End Function

Function getScriptFolder
    getScriptFolder = createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path 
End Function

Function changeExecutionFolder(path)
    Set objShell = CreateObject("Wscript.Shell")
    objShell.CurrentDirectory = path
End Function

' Entry Point
arg = getUrlArg()

'WScript.Echo(arg)

If arg <> false Then

    ' If something fails with the url parsing we'll handle it ourselves
    On Error Resume Next

    Dim Url: Set Url = New UrlParser
    Url.path = arg

    templateFile = Url.host
    quantity = Url.directory(0)

    Set queries = Url.queries

    If Not(Err.Number = 0) Then
        errorMessage = "Ein Fehler ist beim Verarbeiten der URL aufgetreten." + vbNewLine + "Die URL ist wohlmöglich ungültig." + vbNewLine + vbNewLine + "URL String: " + arg
        Msgbox errorMessage, 16, "pDirect"

        WScript.Quit()
    End If

    ' Resume normal error handling
    On Error Goto 0
    
    ' WScript.Echo(createobject("Scripting.FileSystemObject").GetFolder(".").Path)

    ' Change Execution Path
    folder = getScriptFolder()
    changeExecutionFolder(folder & "\templates\")
    
    'WScript.Echo(createobject("Scripting.FileSystemObject").GetFolder(".").Path)
                        
    'Create b-PAC object
    Set ObjDoc = CreateObject("bpac.Document")

    'Open template file created with P-touch Editor
    'Leave lbx file in the same folder as VBS file
    bRet = ObjDoc.Open(templateFile)

    If Not (bRet <> False) Then
        Msgbox "Konnte Templatedatei nicht öffnen.", 16, "pDirect"
        Wscript.Quit()
    End If

    For Each query in queries.Keys
        decodedItem = decodeURL(queries.Item(query))
        decodedKey = decodeURL(query)
    '    Msgbox "Key: " & decodedKey & " Value: " & decodedItem
        ObjDoc.GetObject(decodedKey).Text = decodedItem
    Next

    confirmMessage = "Wollen Sie den Druckauftrag ausführen?" + vbNewLine + vbNewLine + "Templatefile: " + templateFile + vbNewLine + "Anzahl: " + quantity

    confirmed = Msgbox(confirmMessage, 36, "pDirect")

    ' If Msgbox returned Yes
    If confirmed = 6 Then
        ObjDoc.StartPrint "pDirectPrintjob", bpoAutoCut
        ObjDoc.PrintOut quantity, bpoAutoCut
        ObjDoc.EndPrint
        ObjDoc.Close

        Msgbox "Druckauftrag wird ausgeführt!", 64, "pDirect"
    Else 
        Msgbox "Der Druckauftrag wurde abgebrochen.", 16, "pDirect"
        Wscript.Quit()
    End If
Else
    Msgbox "Dem Programm wurde keine URL angegeben.", 16, "pDirect"
End If