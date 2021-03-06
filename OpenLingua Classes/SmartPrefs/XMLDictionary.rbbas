#tag Module
Protected Module XMLDictionary
	#tag Method, Flags = &h21
		Private Sub ClearStorage(storage As Variant)
		  Dim i, n As Integer
		  
		  If storage.Type = 9 Then
		    If storage.ObjectValue IsA Dictionary Then
		      Dictionary(storage).Clear
		    ElseIf storage.ObjectValue IsA Collection Then
		      n = Collection(storage.ObjectValue).Count
		      For i = n DownTo 1
		        Collection(storage.ObjectValue).Remove i
		      Next
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportXML(Extends xmldict As Dictionary, plist As Boolean = False) As XmlDocument
		  Dim xdoc As XmlDocument
		  Dim root, dict As XmlElement
		  
		  xdoc = New XmlDocument
		  If plist Then
		    // Plist-compatible output
		    root = XmlElement(xdoc.AppendChild(xdoc.CreateElement("plist")))
		    root.SetAttribute("version", PlistVersion)
		    dict = XmlElement(root.AppendChild(xdoc.CreateElement("dict")))
		    ParseStorage xmldict, dict, True
		    IndentNode root, 0, True
		    IndentNode dict, 0, True
		  Else
		    root = XmlElement(xdoc.AppendChild(xdoc.CreateElement("xmldict")))
		    root.SetAttribute("version", CurrentVersion)
		    ParseStorage xmldict, root, False
		    IndentNode root, 0, True
		  End If
		  xdoc.AppendChild(xdoc.CreateTextNode(EndOfLine))
		  
		  Return xdoc
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportXMLString(Extends xmldict As Dictionary, plist As Boolean = False) As String
		  // Since we can't add a DOCTYPE to the XmlDocument,
		  // lets hack this output to add it
		  
		  Dim s, DTD As String
		  Dim i As Integer
		  s = xmldict.ExportXML(plist).ToString
		  
		  // Let's add the DTD
		  i = s.InStr(EndOfLine)
		  
		  If plist Then
		    DTD = PlistDTD
		  Else
		    DTD = XMLDictDTD
		  End If
		  s = s.Mid(1, i + Len(EndOfLine) - 1) + DTD + EndOfLine + s.Mid(i + Len(EndOfLine))
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub IndentNode(node As XmlNode, level As Integer, indentCloseTag As Boolean = False)
		  Dim i As Integer
		  Dim s As String
		  s = EndOfLine
		  For i = 1 To level
		    s = s + Chr(9) // Tab
		  Next
		  node.Parent.Insert(node.OwnerDocument.CreateTextNode(s), node)
		  If indentCloseTag Then
		    node.AppendChild(node.OwnerDocument.CreateTextNode(s))
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LoadXML(Extends xmldict As Dictionary, XMLFile As FolderItem) As Boolean
		  Dim tos As TextInputStream
		  Dim s As String
		  
		  tos = XMLFile.OpenAsTextFile()
		  If tos <> nil Then
		    s = tos.ReadAll
		    tos.Close
		    Return xmldict.LoadXML(s)
		  Else
		    Return False
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LoadXML(Extends xmldict As Dictionary, XMLData As String) As Boolean
		  Dim xdoc As XmlDocument
		  
		  xdoc = New XmlDocument()
		  xdoc.PreserveWhitespace = True
		  xdoc.LoadXml(XMLData)
		  Return xmldict.LoadXML(xdoc)
		  
		Exception err As XmlException
		  // Ugh, invalid XML
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LoadXML(Extends xmldict As Dictionary, XMLDoc As XmlDocument) As Boolean
		  Dim node As XmlNode
		  
		  XMLDoc.PreserveWhitespace = True
		  
		  // Check to see if it's our xmldict or if it's a plist
		  If XMLDoc.DocumentElement.Name = "plist" Then
		    // Make sure it's a "dict" as the base type
		    node = XMLDoc.DocumentElement.FirstChild
		    While node.Type <> XmlNodeType.ELEMENT_NODE And node <> nil
		      node = node.NextSibling
		    Wend
		    If node = nil Or node.Name <> "dict" Then
		      // It's not valid
		      Return False
		    End If
		    // Now check the version
		    If Val(XMLDoc.DocumentElement.GetAttribute("version")) <= Val(PlistVersion) Then
		      ParseXML node, xmldict
		      Return True
		    Else
		      Return False
		    End If
		  Else
		    // First, make sure the version is at most what we expect
		    If Val(XMLDoc.DocumentElement.GetAttribute("version")) <= Val(CurrentVersion) Then
		      ParseXML XMLDoc.DocumentElement, xmldict
		      Return True
		    Else
		      // We can't reliably parse a higher version, so lets not parse it at all
		      Return False
		    End If
		  End If
		  
		Exception err As XmlException
		  // Ugh, invalid XML
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function NodeContents(parent As XmlNode) As String
		  // Concatenates all the node children values and returns the result
		  // It's designed for the children to be all text nodes, but for anything
		  // else it'll just use .ToString
		  
		  Dim i, n As Integer
		  Dim node As XmlNode
		  Dim s As String
		  n = parent.ChildCount - 1
		  For i = 0 To n
		    node = parent.Child(i)
		    If node.Type = 3 Then // Text node
		      s = s + node.Value
		    Else // Other node - shouldn't happen, but we gotta deal with it if it does
		      s = s + node.ToString
		    End If
		  Next
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseStorage(storage As Variant, parent As XmlNode, plist As Boolean = False)
		  Dim v(-1) As Variant
		  ParseStorage(storage, parent, v, 1, plist)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseStorage(storage As Variant, parent As XmlNode, alreadySeen() As Variant, indentLevel As Integer, plist As Boolean = False)
		  Dim i, n, x As Integer
		  Dim key, value As Variant
		  Dim node, tempNode As XmlNode
		  Dim xdoc As XmlDocument
		  Dim s, data(-1) As String
		  Dim multilineTag As Boolean
		  Dim mb As MemoryBlock
		  
		  // First, make sure we haven't already seen this dictionary
		  // This protects against circular dictionary references
		  n = UBound(alreadySeen)
		  For i = 0 To n
		    If alreadySeen(i) = storage Then
		      // Ack! We've seen this! Bail out
		      Return
		    End If
		  Next
		  // Ok, lets add out storage to the list
		  alreadySeen.Append storage
		  
		  xdoc = parent.OwnerDocument
		  n = StorageCount(storage) - 1
		  For i = 0 To n
		    // Key
		    key = StorageKey(storage, i)
		    If key <> nil Then // It's a keyed storage
		      node = parent.AppendChild(xdoc.CreateElement("key"))
		      node.AppendChild(xdoc.CreateTextNode(key.StringValue))
		      IndentNode node, indentLevel
		    End If
		    
		    // Value
		    multilineTag = False
		    value = StorageValue(storage, i)
		    Select Case value.Type
		    Case 0 // Null
		      // If it's a plist, we can't use null, so lets use false
		      If plist Then
		        node = xdoc.CreateElement("false")
		      Else
		        node = xdoc.CreateElement("null")
		      End If
		    Case 2 // Integer
		      node = xdoc.CreateElement("integer")
		      node.AppendChild(xdoc.CreateTextNode(Str(value.IntegerValue)))
		    Case 5 // Double/Single
		      node = xdoc.CreateElement("real")
		      node.AppendChild(xdoc.CreateTextNode(Format(value.DoubleValue, "-#.0##############")))
		    Case 7 // Date
		      node = xdoc.CreateElement("date")
		      dim s2 as String = value.DateValue.SQLDateTime
		      if plist then
		        s2 = s2.Replace(" ","T")+"Z"
		      end
		      node.AppendChild(xdoc.CreateTextNode(s2))
		    Case 8 // String
		      node = xdoc.CreateElement("string")
		      s = ConvertEncoding(value.StringValue, Encodings.UTF8) // Convert to UTF8
		      If s.Encoding = nil Then s = DefineEncoding(s, Encodings.UTF8) // If encoding was undefined, convert fails. Simply define instead
		      node.AppendChild(xdoc.CreateTextNode(s))
		    Case 9 // Object
		      // Is this a dictionary, memoryblock, collection, or folderitem?
		      If value.ObjectValue IsA Dictionary Then
		        // We can parse this dictionary
		        node = xdoc.CreateElement("dict")
		        ParseStorage Dictionary(value.ObjectValue), node, alreadySeen, indentLevel+1, plist
		        multilineTag = True
		      ElseIf value.ObjectValue IsA MemoryBlock Then
		        // We can parse this memoryblock
		        node = xdoc.CreateElement("data")
		        data = Split(EncodeBase64(MemoryBlock(value.ObjectValue), 45), ChrB(13)+ChrB(10)) // 45 is what plists use
		        For Each s In data
		          tempNode = node.AppendChild(xdoc.CreateTextNode(DefineEncoding(s, Encodings.ASCII)))
		          IndentNode tempNode, indentLevel
		        Next
		        multilineTag = True
		      ElseIf value.ObjectValue IsA Collection Then
		        // We can parse this collection
		        node = xdoc.CreateElement("array")
		        ParseStorage Collection(value.ObjectValue), node, alreadySeen, indentLevel+1, plist
		        multilineTag = True
		      ElseIf value.ObjectValue IsA FolderItem And Not plist Then // We can't output this if it's plist-compatible
		        // Do the same thing as a memoryblock, but with a different tag
		        node = xdoc.CreateElement("file")
		        data = Split(EncodeBase64(FolderItem(value.ObjectValue).GetSaveInfo(Nil), 45), ChrB(13)+ChrB(10))
		        For Each s In Data
		          tempNode = node.AppendChild(xdoc.CreateTextNode(s))
		          IndentNode tempNode, indentLevel
		        Next
		        multilineTag = True
		      Else
		        // Arbitrary object? We can't do this. Let's just add a null element
		        // If it's a plist, we can't use null, so lets use false
		        If plist Then
		          node = xdoc.CreateElement("false")
		        Else
		          node = xdoc.CreateElement("null")
		        End If
		      End If
		    Case 11 // Boolean
		      If value.BooleanValue = True Then
		        node = xdoc.CreateElement("true")
		      Else
		        node = xdoc.CreateElement("false")
		      End If
		    Case 16 // Color
		      If plist Then
		        // We can't output colors in plists
		        // Lets just add a False node
		        node = xdoc.CreateElement("false")
		      Else
		        node = xdoc.CreateElement("color")
		        node.AppendChild(xdoc.CreateTextNode("#" + Hex(value.IntegerValue)))
		      End If
		    Else
		      // Buh? We should never reach this point, but just in case, lets add a null value
		      // However, if it's plist-compatible mode, we have to add a false value, since it doesn't support null
		      if plist Then
		        node = xdoc.CreateElement("false")
		      Else
		        node = xdoc.CreateElement("null")
		      End If
		    End Select
		    parent.AppendChild node // workaround for AppendChild() as XmlNode bug
		    IndentNode node, indentLevel, multilineTag
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseXML(parent As XmlNode, storage As Variant)
		  Dim i As Integer
		  Dim node, tempNode As XmlNode
		  Dim key As Variant
		  Dim v As Variant
		  Dim d As Dictionary
		  Dim col As Collection
		  Dim mb As MemoryBlock
		  
		  //ClearStorage storage
		  
		  node = parent.FirstChild
		  While node <> nil
		    // We only want to deal with element nodes
		    // The only other type of node that *should* show up is
		    // a text node with only whitespace. However, even if
		    // other nodes show up, we should ignore them, since
		    // we're not a validator
		    If node.Type = XmlNodeType.ELEMENT_NODE Then // Element node
		      If key = nil And node.Name = "key" Then
		        key = NodeContents(node)
		      Else
		        Select Case node.Name
		        Case "null"
		          StoreValue key, nil, storage
		        Case "integer"
		          StoreValue key, Val(NodeContents(node)) \ 1, storage
		        Case "real"
		          StoreValue key, Val(NodeContents(node)), storage
		        Case "date"
		          v = NodeContents(node)
		          if Strcomp(v.Right(1), "Z", 0) = 0 then
		            // plist format
		            v = v.StringValue.Left(v.StringValue.Len-1).Replace("T", " ")
		          end
		          StoreValue key, v.DateValue, storage
		        Case "string"
		          StoreValue key, NodeContents(node), storage
		        Case "dict"
		          v = StorageByKey(storage, key)
		          If v.Type = 9 And v.ObjectValue IsA Dictionary Then
		            d = Dictionary(v.ObjectValue)
		          Else
		            d = New Dictionary
		          End If
		          ParseXML node, d
		          StoreValue key, d, storage
		        Case "array"
		          col = New Collection
		          ParseXML node, col
		          StoreValue key, col, storage
		        Case "data"
		          // Lets parse our Base64-encoded data
		          mb = DecodeBase64(NodeContents(node))
		          StoreValue key, mb, storage
		        Case "file"
		          // Lets parse our Base64-encoded alias data
		          StoreValue key, GetFolderItem(DecodeBase64(NodeContents(node))), storage
		        Case "true"
		          StoreValue key, True, storage
		        Case "false"
		          StoreValue key, False, storage
		        Case "color"
		          v = "&h" + NodeContents(node).Mid(1)
		          StoreValue key, v.ColorValue, storage
		        End Select
		        key = nil
		      End If
		    End If
		    node = node.NextSibling
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SaveXML(Extends xmldict As Dictionary, XMLFile As FolderItem, plist As Boolean = False) As Boolean
		  Dim bs As BinaryStream
		  
		  bs = XMLFile.CreateBinaryFile("")
		  If bs <> nil Then
		    bs.Write xmldict.ExportXMLString(plist)
		    bs.Close
		    XMLFile.MacType = ""
		    XMLFile.MacCreator = ""
		    Return True
		  Else
		    Return False
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StorageByKey(storage As Variant, key As Variant) As Variant
		  // This is only valid for dictionaries
		  // The only purpose is to make Jarvis Badgley's request work, i.e. preserve existing dictionaries
		  
		  If storage.Type = 9 Then
		    If storage.ObjectValue IsA Dictionary And Dictionary(storage.ObjectValue).HasKey(key) Then
		      Return Dictionary(storage.ObjectValue).Value(key)
		    End If
		  End If
		  
		  Return nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StorageCount(storage As Variant) As Integer
		  If storage.Type = 9 Then
		    If storage.ObjectValue IsA Dictionary Then
		      Return Dictionary(storage.ObjectValue).Count
		    ElseIf storage.ObjectValue IsA Collection Then
		      Return Collection(storage.ObjectValue).Count
		    End If
		  End If
		  Return 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StorageKey(storage As Variant, index As Integer) As Variant
		  If storage.Type = 9 And storage.ObjectValue IsA Dictionary Then
		    Return Dictionary(storage.ObjectValue).Key(index)
		  End If
		  Return nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StorageValue(storage As Variant, index As Integer) As Variant
		  If storage.Type = 9 Then
		    If storage.ObjectValue IsA Dictionary Then
		      Return Dictionary(storage.ObjectValue).Value(Dictionary(storage.ObjectValue).Key(index))
		    ElseIf storage.ObjectValue IsA Collection Then
		      Return Collection(storage.ObjectValue).Item(index+1)
		    End If
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StoreValue(key As Variant, value As Variant, storage As Variant)
		  If storage.Type = 9 Then
		    If storage.ObjectValue IsA Dictionary And key <> nil Then
		      Dictionary(storage.ObjectValue).Value(key) = value
		    ElseIf storage.ObjectValue IsA Collection Then
		      Collection(storage.ObjectValue).Add value
		    End If
		  End If
		End Sub
	#tag EndMethod


	#tag Note, Name = Version History
		Kevin Ballard
		kevin@sb.org
		http://www.tildesoft.com/
		
		v1.2.7:
		- (by Thomas Tempelmann, tempelmann@gmail.com): Fixed the Date format for plists
		
		v1.2.6:
		- Approximately tripled the speed of loading an XML file. Unfortunately, I can't do the same for saving because
		  the Dictionary class lacks an appropriate iterator-style access so my Ishmale the Painter's algorithm is required
		
		v1.2.5:
		- As per Jarvis Badgley's request, made it now respect existing dictionaries.
		  This means that if you create a set of nested dictionaries that corresponds to the plist structure,
		  when parsing the plist it will use the existing dictionaries rather than overwriting with its own. Of course,
		  this is not valid when parsing an array in the plist.
		  The main purpose of this is to set up default values before parsing the plist.
		  
		  Note: This means I no longer clear the dictionary when I parse the XML file. If you want to keep the old
		           behaviour, do a Dictionary.clear before parsing the XML file
		
		v1.2.4:
		- Made line endings use EndOfLine instead of linefeed
		- Removed some commented-out code left over from the 5.5.1fc1 hack
		
		v1.2.3:
		- Removed said hack, due to fix in 5.5.1fc4. If you're using 5.5.1fc1-fc3, upgrade
		
		v1.2.2:
		- Added a hack to work around the XmlDocument.AppendChild() As XmlNode bug present in 5.5.1fc1
		- If you pass a variant of an unknown type (something that should never happen), it now outputs "false"
		  instead of "null" in plist-compatible mode
		
		v1.2.1:
		- Fixed bug where plist-compatible mode wasn't preserved in nested dictionaries/collections
		- Fixed plist-compatible mode so that colors are now output as False instead (since plist doesn't support the color type)
		
		v1.2:
		- Fixed double output to use Format() instead of Str()
		- SaveXML now sets file type/creator to "" instead of using the text filetype
		- Can now parse plist files
		- Can now save as plist files with an option boolean to all the export/save methods
		
		v1.1:
		- Added support for Collections as a replacement for lack of array support
		     Note that keys in Collections are not preserved
		- Ugraded version attribute of resulting document to "1.1" - previous versions of XMLDictionary won't read new documents
		- When adding a string value to a document, it now converts it to UTF-8. If conversion failed (because no encoding was present originally),
		     it simply defines the encoding as UTF-8
		
		v1.0.1:
		- Added support for 5.5b6 changes
		
		v1.0:
		- Initial release
	#tag EndNote


	#tag Constant, Name = CurrentVersion, Type = String, Dynamic = False, Default = \"1.1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = PlistDTD, Type = String, Dynamic = False, Default = \"<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">", Scope = Private
	#tag EndConstant

	#tag Constant, Name = PlistVersion, Type = String, Dynamic = False, Default = \"1.0", Scope = Private
	#tag EndConstant

	#tag Constant, Name = XMLDictDTD, Type = String, Dynamic = False, Default = \"<!DOCTYPE xmldict PUBLIC \"-//Tildesoft//DTD XMLDICT 1.1//EN\" \"http://www.tildesoft.com/DTDs/XMLDictionary-1.1.dtd\">", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Module
#tag EndModule
