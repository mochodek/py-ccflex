@objecta.methoda().invocationa_returning_object().get()
@objectb.methodb().invocationb_returning_object().set()
@objectc.methodc().invocationcObject().x()
@objectd.methodd().invocationc().invocationa().invocationg().invocationz()

@objecte.methode().invocationk().invocationw().invocationl().invocationd().invocatione()

@objectf.methodf().invocationp().invocationqq().invocationaa().x

@pNppParams->writeHistory(_lrfl.at(i)._name.c_str());
@if (!lstrcmpi(_lrfl.at(i)._name.c_str(), fn))
@pNppParam->getFindDlgTabTitiles()._replace = nameW;
@pNppParam->getFindDlgTabTitiles()._findInFiles = nameW;
@pNppParam->getFindDlgTabTitiles()._mark = nameW;

@itemToAdd._id = _lrfl.back()._id;
@if (!lstrcmpi(_lrfl.at(i)._name.c_str(), fn))



#define __except(x)	catch(...)
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
// Convert a point size (1/72 of an inch) to raw pixels.
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
		if (encodings[i]._codePage == encoding)
		if (isInListA(encodingAlias, encodings[i]._aliasList))
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
// Copyright (C)2003 Don HO <don.h@free.fr>
// version 2 of the License, or (at your option) any later version.
		::RemoveMenu(_hMenu, _lrfl.at(i)._id, MF_BYCOMMAND);
		::InsertMenu(_hMenu, _posBase + 1, MF_BYPOSITION, IDM_FILE_RESTORELASTCLOSEDFILE, openRecentClosedFile.c_str());
		::InsertMenu(_hMenu, _posBase + 2, MF_BYPOSITION, IDM_OPEN_ALL_RECENT_FILE, openAllFiles.c_str());
		::InsertMenu(_hMenu, _posBase + 3, MF_BYPOSITION, IDM_CLEAN_RECENT_FILE_LIST, cleanFileList.c_str());
			::InsertMenu(_hParentMenu, _posBase + 0, MF_BYPOSITION | MF_POPUP, reinterpret_cast<UINT_PTR>(_hMenu), (LPCTSTR)recentFileList.c_str());
		::RemoveMenu(_hMenu, _lrfl.at(i)._id, MF_BYCOMMAND);
		generic_string strBuffer(BuildMenuFileName(pNppParam->getRecentFileCustomLength(), j, _lrfl.at(j)._name));
		::InsertMenu(_hMenu, _posBase + j, MF_BYPOSITION, _lrfl.at(j)._id, strBuffer.c_str());


/** @file AutoComplete.cxx
 ** Defines the auto completion list box.
 **/
// Copyright 1998-2003 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#include <string>
#include <vector>
#include <algorithm>

#include "Platform.h"

#include "Scintilla.h"
#include "CharacterSet.h"
#include "AutoComplete.h"

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

AutoComplete::AutoComplete() :
	active(false),
	separator(' '),
	typesep('?'),
	ignoreCase(false),
	chooseSingle(false),
	lb(0),
	posStart(0),
	startLen(0),
	cancelAtStartPos(true),
	autoHide(true),
	dropRestOfWord(false),
	ignoreCaseBehaviour(SC_CASEINSENSITIVEBEHAVIOUR_RESPECTCASE),
	widthLBDefault(100),
	heightLBDefault(100),
	autoSort(SC_ORDER_PRESORTED) {
	lb = ListBox::Allocate();
}

void AutoComplete::Start(Window &parent, int ctrlID,
	int position, Point location, int startLen_,
	int lineHeight, bool unicodeMode, int technology) {
	if (active) {
		Cancel();
	}
	lb->Create(parent, ctrlID, location, lineHeight, unicodeMode, technology);
	lb->Clear();
	active = true;
	startLen = startLen_;
	posStart = position;
}


