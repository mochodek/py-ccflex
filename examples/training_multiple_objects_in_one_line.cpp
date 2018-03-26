@object.method().invocation_returning_object().get()
@object.method().invocation_returning_object().set()
@object.method().invocationObject().x()
@object.method().invocation().invocation().invocation().invocation()

@object.method().invocation().invocation().invocation().invocation().invocation()

@object.method().invocation().invocation().invocation().x

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


