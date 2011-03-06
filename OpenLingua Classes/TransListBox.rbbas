#tag ClassProtected Class TransListBoxInherits PersistentListBox	#tag Event		Function CellTextPaint(g As Graphics, row As Integer, column As Integer, x as Integer, y as Integer) As Boolean		  dim dimmed as Boolean = me.CellTag(row, 0)		  if dimmed then		    g.ForeColor = &c808080		  end if		  return false		End Function	#tag EndEvent	#tag Event		Sub Change()		  if not mIgnoreChangeEvents then		    dim grp as LinguaRecordSet		    if me.ListIndex >= 0 and me.ListIndex < me.ListCount then		      grp = recordForRow(me.ListIndex)		    end if		    RaiseEvent SelectedRecord (grp)		  end if		End Sub	#tag EndEvent	#tag Event		Sub ExpandRow(row As Integer)		  dim grp as LinguaRecordSet = recordForRow(row)		  		  dim node as TransListBoxNode = mRootItemsDict.Value(grp.Identifier)		  for platform as Integer = 1 to MaxPlatform		    grp = node.ForPlatformCode (platform)		    addItem grp, true		  next		End Sub	#tag EndEvent	#tag Event		Function RowID(row as Integer) As Variant		  // Better to return a value that's not an object so that it can be recognized		  // later again (if we'd return the RowTag, it might get lost as some objects		  // get recreated so that RestoreState won't find them again)		  dim grp as LinguaRecordSet = recordForRow(row)		  return grp.Identifier + "_" + Str(grp.Platform)		End Function	#tag EndEvent	#tag Method, Flags = &h21		Private Sub addItem(grp as LinguaRecordSet, hierarchical as Boolean)		  // Add an item to the list		  		  dim choice as DisplayChoices		  if grp.Platform = 0 then		    choice = mDisplayChoice		  else		    choice = DisplayChoices.Translation		  end		  		  // Determine which text to show in this list row		  dim label as String		  dim dimmed as Boolean		  select case choice		  case DisplayChoices.Identifier		    label = grp.Identifier		  case DisplayChoices.Original		    label = grp.Original		  case DisplayChoices.Translation		    label = grp.Translation		  case DisplayChoices.TranslationOrOriginal		    label = grp.Translation		    if label = "" then		      label = grp.Original		      dimmed = true		    end if		  end select		  		  if grp.Platform <> 0 then		    // This is a platform specific item		    static shortPlatformLabel() as String = Array ("", "X", "W", "L")		    label = "(" + shortPlatformLabel(grp.Platform) + ") " + label		  end if		  		  if grp.Platform = 0 and hierarchical then		    me.AddFolder label		  else		    me.AddRow label		  end if		  		  if dimmed then		    me.CellTag(me.LastIndex, 0) = true		    me.CellItalic(me.LastIndex, 0) = true		  end		  		  me.RowTag (me.LastIndex) = grp		End Sub	#tag EndMethod	#tag Method, Flags = &h0		Sub Clear()		  mIgnoreChangeEvents = false		  mDisplayChoice = DisplayChoices.TranslationOrOriginal		  mFilter = ""		  mFileRef = nil		  mLTP = nil		  redim mRootItemsArray(-1)		  mRootItemsDict = new Dictionary		  me.DeleteAllRows()		End Sub	#tag EndMethod	#tag Method, Flags = &h21		Private Sub createDisplayNodes()		  // Creates a TransListBoxNode list from the LTP array,		  // with the default entries and their platform dependent values		  // collected in a single node each.		  		  for each rec as LinguaFileRecord in mLTP.RawRecords.AllItems		    if rec.Value.Type = Variant.TypeObject and rec.Value.ObjectValue isA LinguaRecordSet then		      dim grp as LinguaRecordSet = rec.Value		      dim key as String = grp.Identifier		      dim node as TransListBoxNode = mRootItemsDict.Lookup(key, nil)		      if node = nil then		        node = new TransListBoxNode		        mRootItemsArray.Append node		        mRootItemsDict.Value(key) = node		      end		      node.Assign grp		    end if		  next		End Sub	#tag EndMethod	#tag Method, Flags = &h0		Function FileRef() As FolderItem		  return mFileRef		End Function	#tag EndMethod	#tag Method, Flags = &h21		Private Sub rebuildList()		  mIgnoreChangeEvents = true		  me.SaveState (true)		  me.DeleteAllRows()		  		  if mFilter = "" then		    // hierarchical list		    for each node as TransListBoxNode in mRootItemsArray		      dim grp as LinguaRecordSet = node.Default		      addItem (grp, true)		    next		  else		    // we'll show a flat list when doing a search		    for each node as TransListBoxNode in mRootItemsArray		      for i as Integer = 0 to MaxPlatform		        dim grp as LinguaRecordSet = node.ForPlatformCode(i, true)		        if grp <> nil then		          if grp.Identifier.InStr(mFilter) > 0 or grp.Original.InStr(mFilter) > 0 or grp.Translation.InStr(mFilter) > 0 then		            addItem (grp, false)		          end if		        end if		      next		    next		    		  end if		  		  me.RestoreState()		  mIgnoreChangeEvents = false		End Sub	#tag EndMethod	#tag Method, Flags = &h21		Private Function recordForRow(row as Integer) As LinguaRecordSet		  dim grp as LinguaRecordSet = me.RowTag (row)		  return grp		End Function	#tag EndMethod	#tag Method, Flags = &h0		Sub SetTranslationGroup(ltp as LinguaTranslationPool, fileRef as FolderItem)		  Clear()		  mLTP = ltp		  mFileRef = fileRef		  createDisplayNodes()		  		  rebuildList()		End Sub	#tag EndMethod	#tag Method, Flags = &h0		Function TransPool() As LinguaTranslationPool		  return mLTP		End Function	#tag EndMethod	#tag Hook, Flags = &h0		Event SelectedRecord(grp as LinguaRecordSet)	#tag EndHook	#tag ComputedProperty, Flags = &h0		#tag Note			Applies only to root list items		#tag EndNote		#tag Getter			Get			  return mDisplayChoice			End Get		#tag EndGetter		#tag Setter			Set			  if mDisplayChoice <> value then			    mDisplayChoice = value			    rebuildList()			  end			End Set		#tag EndSetter		DisplayChoice As DisplayChoices	#tag EndComputedProperty	#tag ComputedProperty, Flags = &h0		#tag Getter			Get			  return mFilter			End Get		#tag EndGetter		#tag Setter			Set			  if mFilter <> value then			    mFilter = value			    rebuildList()			  end if			End Set		#tag EndSetter		Filter As String	#tag EndComputedProperty	#tag Property, Flags = &h21		Private mDisplayChoice As DisplayChoices	#tag EndProperty	#tag Property, Flags = &h21		Private mFileRef As FolderItem	#tag EndProperty	#tag Property, Flags = &h21		Private mFilter As String	#tag EndProperty	#tag Property, Flags = &h0		mIgnoreChangeEvents As Boolean	#tag EndProperty	#tag Property, Flags = &h21		Private mLTP As LinguaTranslationPool	#tag EndProperty	#tag Property, Flags = &h21		#tag Note			We're using this array to preserve the original order (which would be lost if we'd only use the Dictionary)		#tag EndNote		Private mRootItemsArray() As TransListBoxNode	#tag EndProperty	#tag Property, Flags = &h21		#tag Note			Key: Identifier			Value: TransListBoxNode		#tag EndNote		Private mRootItemsDict As Dictionary	#tag EndProperty	#tag Enum, Name = DisplayChoices, Type = Integer, Flags = &h0		Identifier		  Original		  Translation		TranslationOrOriginal	#tag EndEnum	#tag ViewBehavior		#tag ViewProperty			Name="AutoDeactivate"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="AutoHideScrollbars"			Visible=true			Group="Behavior"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Bold"			Visible=true			Group="Font"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Border"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="ColumnCount"			Visible=true			Group="Appearance"			InitialValue="1"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="ColumnsResizable"			Visible=true			Group="Behavior"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="ColumnWidths"			Visible=true			Group="Appearance"			Type="String"			EditorType="MultiLineEditor"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="DataField"			Visible=true			Group="Database Binding"			Type="String"			EditorType="DataField"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="DataSource"			Visible=true			Group="Database Binding"			Type="String"			EditorType="DataSource"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="DefaultRowHeight"			Visible=true			Group="Appearance"			InitialValue="-1"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Enabled"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="EnableDrag"			Visible=true			Group="Behavior"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="EnableDragReorder"			Visible=true			Group="Behavior"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Filter"			Group="Behavior"			Type="String"			EditorType="MultiLineEditor"		#tag EndViewProperty		#tag ViewProperty			Name="GridLinesHorizontal"			Visible=true			Group="Appearance"			InitialValue="0"			Type="Integer"			EditorType="Enum"			InheritedFrom="ListBox"			#tag EnumValues				"0 - Default"				"1 - None"				"2 - ThinDotted"				"3 - ThinSolid"				"4 - ThickSolid"				"5 - DoubleThinSolid"			#tag EndEnumValues		#tag EndViewProperty		#tag ViewProperty			Name="GridLinesVertical"			Visible=true			Group="Appearance"			InitialValue="0"			Type="Integer"			EditorType="Enum"			InheritedFrom="ListBox"			#tag EnumValues				"0 - Default"				"1 - None"				"2 - ThinDotted"				"3 - ThinSolid"				"4 - ThickSolid"				"5 - DoubleThinSolid"			#tag EndEnumValues		#tag EndViewProperty		#tag ViewProperty			Name="HasHeading"			Visible=true			Group="Appearance"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="HeadingIndex"			Visible=true			Group="Appearance"			InitialValue="-1"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Height"			Visible=true			Group="Position"			InitialValue="100"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="HelpTag"			Visible=true			Group="Appearance"			Type="String"			EditorType="MultiLineEditor"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Hierarchical"			Visible=true			Group="Behavior"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Index"			Visible=true			Group="ID"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="InitialParent"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="InitialValue"			Visible=true			Group="Appearance"			Type="String"			EditorType="MultiLineEditor"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Italic"			Visible=true			Group="Font"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Left"			Visible=true			Group="Position"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="LockBottom"			Visible=true			Group="Position"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="LockLeft"			Visible=true			Group="Position"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="LockRight"			Visible=true			Group="Position"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="LockTop"			Visible=true			Group="Position"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="mIgnoreChangeEvents"			Group="Behavior"			Type="Boolean"		#tag EndViewProperty		#tag ViewProperty			Name="Name"			Visible=true			Group="ID"			Type="String"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="RequiresSelection"			Visible=true			Group="Behavior"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="ScrollbarHorizontal"			Visible=true			Group="Appearance"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="ScrollBarVertical"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="SelectionType"			Visible=true			Group="Behavior"			InitialValue="0"			Type="Integer"			EditorType="Enum"			InheritedFrom="ListBox"			#tag EnumValues				"0 - Single"				"1 - Multiple"			#tag EndEnumValues		#tag EndViewProperty		#tag ViewProperty			Name="Super"			Visible=true			Group="ID"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TabIndex"			Visible=true			Group="Position"			InitialValue="0"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TabPanelIndex"			Group="Position"			InitialValue="0"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TabStop"			Visible=true			Group="Position"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TextFont"			Visible=true			Group="Font"			InitialValue="System"			Type="String"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TextSize"			Visible=true			Group="Font"			InitialValue="0"			Type="Single"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TextUnit"			Visible=true			Group="Font"			InitialValue="0"			Type="FontUnits"			EditorType="Enum"			InheritedFrom="ListBox"			#tag EnumValues				"0 - Default"				"1 - Pixel"				"2 - Point"				"3 - Inch"				"4 - Millimeter"			#tag EndEnumValues		#tag EndViewProperty		#tag ViewProperty			Name="Top"			Visible=true			Group="Position"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="TripleStateSorting"			Visible=true			Group="Behavior"			InitialValue="0"			Type="Boolean"			InheritedFrom="BetterListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Underline"			Visible=true			Group="Font"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="UseFocusRing"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Visible"			Visible=true			Group="Appearance"			InitialValue="True"			Type="Boolean"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="Width"			Visible=true			Group="Position"			InitialValue="100"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="_ScrollOffset"			Group="Appearance"			InitialValue="0"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty		#tag ViewProperty			Name="_ScrollWidth"			Group="Appearance"			InitialValue="-1"			Type="Integer"			InheritedFrom="ListBox"		#tag EndViewProperty	#tag EndViewBehaviorEnd Class#tag EndClass