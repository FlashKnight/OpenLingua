#tag BuildAutomation
			Begin BuildStepList Linux
				Begin BuildProjectStep Build
				End
			End
			Begin BuildStepList Mac OS X
				Begin BuildProjectStep Build
				End
				Begin IDEScriptBuildStep AddKeysToInfoPlist , AppliesTo = 2
					// Sadly, this only works when running on OSX. When building OpenLingua on Windows or Linux, the plist file must be edited by hand if you want to build the OSX version of the app.
					
					dim cmd, s as String
					
					cmd = "/usr/libexec/PlistBuddy -c ""Merge \""$PROJECT_PATH/Resources/Info-addon.plist\"""" "+CurrentBuildLocation+"/"""+CurrentBuildAppName+".app""/Contents/Info.plist"
					s = DoShellCommand (cmd)
					if s <> "" then
					print "Updating Info.plist failed: "+s
					end
					
				End
			End
			Begin BuildStepList Windows
				Begin BuildProjectStep Build
				End
			End
#tag EndBuildAutomation
