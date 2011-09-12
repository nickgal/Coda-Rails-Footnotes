(* Nik's generic URI handling scriptlet

By Nik at http://nik.me

This script snippet has a script object that handles any URI/URL using the "open location" Applescript handler. This allows custom URI schemes to activate this script. It's a great way to fire off AppleScripts from web browsers that don't have script support or from shell scripts. If it can make a URL, it can run the applet.

This script takes a URL in the format of "theURI://theMethod?Arg1&Arg2&...ArgN". It handles the parsing of the individual URL arguments and the method, and generates an object containing the results as easy-to-access properties.

The "open location" handler is deliberately simplified to just generate the URL object -- nothing more. From there you can refer to the object to get specific properties, e.g. "get description of myURLObject's args" to get the "description" argument out of the original URL.

There is no built-in validation, so you'll have to manage that after parsing the initial URL.

For this script to work, you must save it as an Application Bundle, and edit the enclosed plist as follows (copied from Apple's website):

-----------

When you save the script as an application bundle, it will contain the standard Mac OS X bundle elements including an XML property list file defining important aspects of the script application.

To access the Info.plist property list, click on the script application with the Control key held down to access the Finder Contextual Menu. Choose Show Package Contents from this menu to open the script application bundle in a new window. Open the Contents folder within the new window to reveal the Info.plist file. Open this file in a text or property list editor and add the following XML keys and values to the property list.

To identify the Application, add the following lines to the property list, replacing the net.mysite.appname text shown here with a unique bundle identifier for your application:

<key>CFBundleIdentifier</key>
<string>net.mysite.appname</string>

To identify the URL handler that triggers the applet, add the following item to the property list, replacing the App Name and theURI text with title of your URL protocol and the URL scheme of your protocol:

<key>CFBundleURLTypes</key>
<array>
   <dict>
       <key>CFBundleURLName</key>
       <string>App Name</string>
       <key>CFBundleURLSchemes</key>
       <array>
           <string>theURI</string>
       </array>
   </dict>
</array>

-----------

You can find documentation on how this works on Apple's website:

http://www.apple.com/applescript/linktrigger/index.html

--------

This script is free to share with anybody you like for any purpose. I'd appreciate it if you'd attribute it back to me (Nik) if you can.

*)

-- Test it here
on run
	--open location "coda-uri://open?url=/Users/admin/Downloads/rdoc/index.html"
end run

on open location sURL
	set myURLObject to newURI(sURL)
	-- display alert "The following values were passed: " & return & "SCHEME: " & scheme of myURLObject & return & "LOCATION: " & location of myURLObject & return & "ARG1: " & URL of args of myURLObject
	--& return & "ARG2: " & arg2 of args of myURLObject
	
	if scheme of myURLObject = "coda-uri" and location of myURLObject = "open" then
		
		set h to "coda " & URL of args of myURLObject & " &> /dev/null &"
		--display alert h
		
		do shell script h
		
	end if
	
end open location




(* newURI(): URI Object Initialization Script

   This returns a URL script object, containing properties for the URL scheme, location, and arguments, as passed through an HTML-encoded URL. *)

on newURI(u)
	script uriObject
		
		property rawURL : missing value
		property scheme : missing value
		property location : missing value
		property args : {}
		
		(* initialize()        
       This handler initializes the URL object, breaking it out into its constituent parts, and assigns them to the various script object properties. It will also replace and overwrite any existing URL properties on the script object *)
		
		on initialize(aURL)
			try
				
				set u to aURL
				-- Break out the URL into its various components
				set theSplitURL to splitURL(aURL)
				log result
				--Get the URI-Scheme from the URI
				set scheme to item 1 of theSplitURL
				-- Get the location from the URI
				set location to (decode_text(item 2 of theSplitURL))
				
				-- parse arguments
				if item 2 of theSplitURL is not missing value then
					set args to argsToRecord(item 3 of theSplitURL)
				end if
				
				-- All went well, let's reset our text item delimiters and send back the arguments
				set AppleScript's text item delimiters to ""
				return {scheme:scheme, location:location, args:args}
				
			on error errMsg number errNum
				display alert errMsg & " (" & errNum & ")"
				error number -128
			end try
		end initialize
		
		
		
		(* Convert a URL into a record set *)
		on splitURL(theURL)
			
			set text item delimiters to ":"
			set theURI to text item 1 of theURL
			set text item delimiters to ""
			set grin to (count of characters of theURI) + 1 -- account for the ":"
			-- Get rid of the url protocol string
			
			set pN to offset of (theURI & "://") in theURL -- is it a mailto:// style?
			
			if pN > 0 then -- a URI:// url
				set theURL to text (grin + 3) through (count of characters of theURL) of theURL
			else -- or just a URI: url
				set theURL to text (grin + 1) through (count of characters of theURL) of theURL
			end if
			
			-- See if there's any arguments being passed, pass 'em back if there are
			set aN to offset of "?" in theURL
			if aN = 1 then -- no base url, just arguments
				return {missing value, (text (aN + 1) through (count of characters of theURL) of theURL)}
			else if aN > 1 then
				return {theURI, (text 1 through (aN - 1) of theURL), (text (aN + 1) through (count of characters of theURL) of theURL)}
			else
				return {theURI, theURL, theArgs}
			end if
			
		end splitURL
		
		(* Splits ?key=value&key2=value2 type arguments from the URI and turns them into a {key:value,key2:value2} record set *)
		on argsToRecord(argString)
			set rStringArray to {}
			set text item delimiters to "&"
			set splitArgs to text items of argString
			set text item delimiters to "="
			
			repeat with a in splitArgs
				set ax to text items of a
				set axKey to item 1 of ax
				set axValue to my decode_text(item 2 of ax)
				set rStringArray to rStringArray & {axKey & ":\"" & axValue & "\""}
			end repeat
			set text item delimiters to ","
			run script ("return {" & rStringArray as string) & "}"
			return result
		end argsToRecord
		
		(* Simple HTML decode routine *)
		on decode_text(encoded string)
			do shell script "echo " & quoted form of ¬
				encodedstring & " | /usr/bin/ruby -r cgi -e \"print CGI.unescape(STDIN.read).gsub('+',' ')\""
		end decode_text
	end script
	tell uriObject to initialize(u)
	return uriObject
end newURI