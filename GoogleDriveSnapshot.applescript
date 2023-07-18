use AppleScript version "2.4" -- Yosemite (10.10) or later
use script "RegexAndStuffLib" version "1.0.6"
use scripting additions

-- when calling on selection / single file
on run
	tell application id "DNtp"
		-- TODO make it also work from a "document window"
		snapshotGDocs((selection of think window 1) as list) of me
	end tell
end run

-- when called by smart rule
on performSmartRule(theRecords)
	snapshotGDocs(theRecords as list) of me
end performSmartRule

-- generic wrapper to handle multiple snapshots
on snapshotGDocs(theRecords)
	tell application id "DNtp"
		show progress indicator "Snapshotting Google Drive assets ..." steps (length of theRecords) + 1
		repeat with theRecord in theRecords
			step progress indicator (name of theRecord) as text
			snapshotGDoc(theRecord) of me
		end repeat
		hide progress indicator
	end tell
end snapshotGDocs

-- record snapshotting
on snapshotGDoc(theBookmark)
	tell application id "DNtp"
		-- prepare some vars
		set bookmarkURL to URL of theBookmark
		set gDocID to regex search once bookmarkURL search pattern "[^/]{32,52}"
		
		-- deal with the various types of docs
		if bookmarkURL contains "document" then
			set exportURL to "https://docs.google.com/document/u/0/export?format=pdf&id=" & gDocID
		end if
		if bookmarkURL contains "presentation" then
			set exportURL to "https://docs.google.com/presentation/d/" & gDocID & "/export/pdf?id=" & gDocID
		end if
		if bookmarkURL contains "spreadsheet" then
			set exportURL to "https://docs.google.com/spreadsheets/d/" & gDocID & "/export?format=pdf"
		end if
		
		
		set exportName to name of theBookmark & " (PDF Snapshot)"
		set exportGroup to first parent of theBookmark
		set referenceURL to get reference URL of theBookmark
		
		
		-- download new snapshot
		set exportData to download URL exportURL
		
		
		-- cleanup old snapshots
		set oldSnapshots to search "kind:pdf name:~snapshot url==" & referenceURL
		repeat with oldSnapshot in (oldSnapshots as list)
			move record oldSnapshot to trash group of current database
		end repeat
		
		
		-- save new snapshot
		set theExport to create record with {name:exportName, type:PDF document, MIME type:"application/PDF", URL:referenceURL} in exportGroup
		set data of theExport to exportData
		
		
		-- reproduce replicates and tags of bookmark
		repeat with parentGroup in parents of theBookmark
			if id of parentGroup = id of exportGroup then
				-- do not replicate to first parent
			else
				set theRep to replicate record theExport to parentGroup
			end if
		end repeat
	end tell
end snapshotGDoc
