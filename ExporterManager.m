/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
  Redistribution and use in source and binary forms, with or without modification, are permitted 
  provided that the following conditions are met:
   - Redistributions of source code must retain the above copyright notice, this list of conditions 
     and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice, this list of 
	 conditions and the following disclaimer in the documentation and/or other materials provided with
     the distribution.
   - Neither the name of Notational Velocity nor the names of its contributors may be used to endorse 
     or promote products derived from this software without specific prior written permission. */


#import "ExporterManager.h"
#import "NoteObject.h"
#import "NotationPrefs.h"
#import "NSString_NV.h"
#import "GlobalPrefs.h"

@implementation ExporterManager

+ (ExporterManager *)sharedManager {
	static ExporterManager *man = nil;
	if (!man)
		man = [[ExporterManager alloc] init];
	return man;
}

- (void)awakeFromNib {
	
	NSInteger storageFormat = [[[GlobalPrefs defaultPrefs] notationPrefs] notesStorageFormat];
	[formatSelectorPopup selectItemWithTag:storageFormat];
}

- (IBAction)formatSelectorChanged:(id)sender {
}

void(^exportHandler)(NSInteger) =^(NSInteger returnCode) {
    NSLog(@"panel  handlin:%ld",returnCode);
//    NSArray *notes = (NSArray *)contextInfo;
//    NSLog(@"notes:%@",notes);
//    [notes release];
};



- (void)exportPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo {
	NSArray *notes = (NSArray *)contextInfo;
	if (returnCode == NSFileHandlingPanelOKButton && notes) {
		//write notes in chosen format
		NSInteger storageFormat = [[formatSelectorPopup selectedItem] tag];
		NSString *directory = nil, *filename = nil;
		__block BOOL overwriteNotes = NO;
		
		if ([sheet isKindOfClass:[NSOpenPanel class]]) {
            directory = [[sheet URL]path];
		} else {
            filename=[[sheet URL]path];            
            directory = [filename stringByDeletingLastPathComponent];
			filename = [filename lastPathComponent];
			NSAssert([notes count] == 1, @"We returned from a save panel with more than one note?!");
			
			//user wanted us to overwrite this one--otherwise dialog would have been cancelled
			if ([[NSFileManager defaultManager] fileExistsAtPath:[[sheet URL]path]]) overwriteNotes = YES;
			
			if ([filename compare:filenameOfNote([notes lastObject]) options:NSCaseInsensitiveSearch] != NSOrderedSame) {
				//undo any POSIX-safe crap NSSavePanel gave us--otherwise FSCreateFileUnicode will fail
				filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"/"];
			}
		}
		
		__block FSRef directoryRef;
		CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)directory, kCFURLPOSIXPathStyle, true);
		[(id)url autorelease];
		if (!url || !CFURLGetFSRef(url, &directoryRef)) {
			NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"The notes couldn't be exported because the directory quotemark%@quotemark couldn't be accessed.",nil),
				[directory stringByAbbreviatingWithTildeInPath]], @"", NSLocalizedString(@"OK",nil), nil, nil);
			return;
		}
		
		//re-uniqify file names here (if [notes count] > 1)?
		NSUInteger count = notes.count;
		[notes enumerateObjectsUsingBlock:^(NoteObject *note, NSUInteger i, BOOL *stop) {
			BOOL lastNote = i != count - 1;

			OSStatus err = [note exportToDirectoryRef:&directoryRef withFilename:filename usingFormat:storageFormat overwrite:overwriteNotes];

			if (err == dupFNErr) {
				//ask about overwriting
				NSString *existingName = filename ? filename : filenameOfNote(note);
				existingName = [[existingName stringByDeletingPathExtension] stringByAppendingPathExtension:[NotationPrefs pathExtensionForFormat:storageFormat]];
				NSInteger result = NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"A file named quotemark%@quotemark already exists.",nil), existingName],
										 NSLocalizedString(@"Replace its current contents with that of the note?", @"replace the file's contents?"),
										 NSLocalizedString(@"Replace",nil), NSLocalizedString(@"Don't Replace",nil), lastNote ? NSLocalizedString(@"Replace All",nil) : nil, nil);
				if (result == NSAlertDefaultReturn || result == NSAlertOtherReturn) {
					if (result == NSAlertOtherReturn) overwriteNotes = YES;
					err = [note exportToDirectoryRef:&directoryRef withFilename:filename usingFormat:storageFormat overwrite:YES];
				} else {
					return;
				}
			}

			if (err != noErr) {
				NSString *exportErrorTitleString = [NSString stringWithFormat:NSLocalizedString(@"The note quotemark%@quotemark couldn't be exported because %@.",nil),
													titleOfNote(note), [NSString reasonStringFromCarbonFSError:err]];
				if (!lastNote) {
					NSRunAlertPanel(exportErrorTitleString, nil, NSLocalizedString(@"OK",nil), nil, nil, nil);
				} else {
					NSInteger result = NSRunAlertPanel(exportErrorTitleString, NSLocalizedString(@"Continue exporting?", @"alert title for exporter interruption"),
											 NSLocalizedString(@"Continue", @"(exporting notes?)"), NSLocalizedString(@"Stop Exporting", @"(notes?)"), nil);
					if (result != NSAlertDefaultReturn) {
						*stop = YES;
						return;
					}
				}
			}
		}];
		
		FNNotify(&directoryRef, kFNDirectoryModifiedMessage, kFNNoImplicitAllSubscription);
		
		[notes release];
	}
}

- (void)exportNotes:(NSArray*)notes forWindow:(NSWindow*)window {
	
	if (!accessoryView) {
		if (![NSBundle loadNibNamed:@"ExporterManager" owner:self]) {
			NSLog(@"Failed to load ExporterManager.nib");
			NSBeep();
			return;
		}
	}
	
	if ([notes count] == 1) {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAccessoryView:accessoryView];
		[savePanel setCanCreateDirectories:YES];
		[savePanel setCanSelectHiddenExtension:YES];
		
		[self formatSelectorChanged:formatSelectorPopup];
		
		NSString *filename = filenameOfNote([notes lastObject]);
		filename = [filename stringByDeletingPathExtension];
		filename = [filename stringByAppendingPathExtension:[NotationPrefs pathExtensionForFormat:[[formatSelectorPopup selectedItem] tag]]];
		
        savePanel.nameFieldStringValue=filename;
        [savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
            [self exportPanelDidEnd:savePanel returnCode:result contextInfo:[notes retain]];
        }];
        
//		[savePanel beginSheetForDirectory:nil file:filename modalForWindow:window modalDelegate:self didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:[notes retain]];
		
	} else if ([notes count] > 1) {
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setAccessoryView:accessoryView];
		[openPanel setCanCreateDirectories:YES];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setPrompt:NSLocalizedString(@"Export",@"title of button to export notes from folder selection dialog")];
		[openPanel setTitle:NSLocalizedString(@"Export Notes", @"title of export notes dialog")];
		[openPanel setMessage:[NSString stringWithFormat:NSLocalizedString(@"Choose a folder into which %lu notes will be exported",nil), (unsigned long)[notes count]]];
        
//		[openPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:[notes retain]];
        [openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
            [self exportPanelDidEnd:openPanel returnCode:result contextInfo:[notes retain]];
        }];
        
	} else {
		NSRunAlertPanel(NSLocalizedString(@"No notes were selected for exporting.",nil), 
						NSLocalizedString(@"You must select at least one note to export.",nil), NSLocalizedString(@"OK",nil), NULL, NULL);
	}
}

@end
