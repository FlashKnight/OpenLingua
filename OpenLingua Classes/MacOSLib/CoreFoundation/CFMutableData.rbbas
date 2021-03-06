#tag Class
Class CFMutableData
Inherits CFData
	#tag Method, Flags = &h0
		Sub Append(p as Ptr, length as Integer)
		  #if targetMacOS
		    soft declare sub CFDataAppendBytes lib CarbonLib (theData as Ptr, bytes as Ptr, length as Integer)
		    
		    if not me.IsNULL and p <> nil then
		      CFDataAppendBytes me.Reference, p, length
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Append(s as String)
		  #if targetMacOS
		    soft declare sub CFDataAppendBytes lib CarbonLib (theData as Ptr, bytes as CString, length as Integer)
		    
		    dim slen as Integer = LenB(s)
		    if not me.IsNULL and slen > 0 then
		      CFDataAppendBytes me.Reference, s, slen
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  #if targetMacOS
		    soft declare function CFDataCreateMutable lib CarbonLib (allocator as Ptr, capacity as Integer) as Ptr
		    
		    const capacity = 0 // can use all of available memory
		    super.Constructor CFDataCreateMutable(nil, capacity), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(data as CFData)
		  if data is nil then
		    me.Constructor
		    return
		  end if
		  
		  #if targetMacOS
		    soft declare function CFDataCreateMutableCopy lib CarbonLib (allocator as Ptr, capacity as Integer, theData as Ptr) as Ptr
		    
		    const capacity = 0 //can use all of available memory
		    super.Constructor CFDataCreateMutableCopy(nil, capacity, data.Reference), true
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(start as Integer, length as Integer)
		  #if targetMacOS
		    soft declare sub CFDataDeleteBytes lib CarbonLib (theData as Ptr, range as CFRange)
		    
		    if not me.IsNULL then
		      CFDataDeleteBytes me.Reference, CFRangeMake(start, length)
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Replace(start as Integer, length as Integer, newData as Ptr, newLength as Integer)
		  if not me.IsNULL then
		    if newData = nil then
		      me.Delete start, length
		    else
		      #if targetMacOS
		        soft declare sub CFDataReplaceBytes lib CarbonLib (theData as Ptr, range as CFRange, newBytes as Ptr, newLength as Integer)
		        
		        CFDataReplaceBytes me.Reference, CFRangeMake(start, length), newData, newLength
		      #endif
		    end if
		  end if
		End Sub
	#tag EndMethod


	#tag ViewBehavior
		#tag ViewProperty
			Name="Description"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="CFType"
		#tag EndViewProperty
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
End Class
#tag EndClass
