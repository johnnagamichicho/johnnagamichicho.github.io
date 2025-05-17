#!/bin/sh

#
# @(#)Vote.sh	1.5	7/19/95 19:58:39
# slightly modified 8/1/95 by Alec Proudfoot
# again 10/20/95 by John Cho
# yet again 10/30/95 by Screamin' Phil Erickson
#   (added multiple haiku votes, checking for max haiku votes)
# way too many new features 10/31/95  Screamin' Phil Erickson
#   (lots of error checking, no ballot-box stuffing, etc.)
# major bug fix 2/15/96  Screamin' Phil Erickson
#   (goof in the two "grep" lines; didn't allow for names with spaces)
#

#
# Use "postq" binary to pre-process input.
#
# This version uses "nawk" to set shell variables. The HTML generation
# can then use the contents of those variables to initiate various
# actions.
#
# John Little (gaijin@Japan.Sbi.COM).
#

#
# Configure the following two lines for your site.
#
ERRORS_TO="<A HREF="AlecPlan.html">alec@cougar.stanford.edu</A></A>";
BALLOT_BOX="/home/cougar/alec/httpd_1.3/htdocs/vote_spam-tally";
## Locate this somewhere SAFE.


BINARY=./postq;
ERR_IND="^POST_QUERY_ERROR";				## Error Flag.
DATE=`date`;
NAME=${0};
SHORT_NAME=`basename ${0}`;
MAX_HAIKU=10;						## Max of 5 haiku
HAIKU_COUNT=0;						## User's haiku count
VOTER_NAME="nobody";
VOTER_EMAIL="nobody";

#
# Save environmental variables.
#
REM_HOST_ID="${REMOTE_HOST:-unknown}";
REM_ADDR_ID="${REMOTE_ADDR:-unknown}";
REM_USER_ID="${REMOTE_USER:-unknown}";
REM_IDENT="${REMOTE_IDENT:-unknown}";

set -h;

#
# FUNCTION - Generate an error message for the user, including a mailing
# address for the server administrator. Generate a logfile error message.
#
Error(){
	
	cat <<- EO_ERROR
	Content-type: text/html

	<HTML>
	<HEAD>
	<TITLE>Query Error</TITLE>
	</HEAD>
	<BODY>
	<H2>*** ERROR ***</H2>
	An error has occured during the course of processing
	your query.
	<UL>
	<STRONG>${*}</STRONG>
	</UL>
	The query has <EM>not</EM> been completed.
	<P>
	You should contact the server administrator:-
	<UL>
	<STRONG>${ERRORS_TO}</STRONG>
	</UL>
	...and quote the highlighted message above to
	have the problem resolved.
	<HR>
	</BODY>
	</HTML>

	EO_ERROR

	#
	# Log message (STDERR).
	#
	echo "[${DATE}] ${SHORT_NAME}: ${*}"	>&2;

	exit 500;
}

#
# Check that the binary file for pre-processing client input is
# available.
#
if [ ! -x ${BINARY} ];	then

	Error "Unable To Execute: ${BINARY}";
fi

#
# Check that the target file is writeable.
#
if [ ! -f ${BALLOT_BOX} ];	then

	touch ${BALLOT_BOX} >/dev/null 2>&1;
	if [ ${?} -ne 0 ];	then

		Error "Unable to create ballot-box file: ${BALLOT_BOX}";
	fi

elif [ ! -w ${BALLOT_BOX} ];	then

	Error "Cannot write to ballot-box file: ${BALLOT_BOX}";
fi

eval `${BINARY} | nawk '
BEGIN {
	FS		= "="
	ERR_IND		= "'"${ERR_IND}"'";
	ERROR_FLAG	= "FALSE";

	EXP_TYPE	= "";
	NASTY		= "";
	HAIKU_LIST	= "";
	HAIKU_COUNT	= 0;
	VOTER_EMAIL	= "nobody";
	VOTER_NAME	= "nobody";
}

#
# Check the input for a pre-set error string from "postq".
#
$0 ~ ERR_IND {

	ERROR_FLAG = "TRUE";
	exit;
}

#
# Haiku information.
#
$1 ~ /^haiku/ {

	split($0, HAIKU_ARRAY, "=");
	if (length(HAIKU_LIST) == 0) {
  	  HAIKU_LIST=sprintf("%s",HAIKU_ARRAY[2]);
        }
        else {
  	  HAIKU_LIST=sprintf("%s,%s",HAIKU_LIST,HAIKU_ARRAY[2]);
        }
	HAIKU_COUNT=HAIKU_COUNT+1;
	printf("HAIKU=\"%s\";\n", HAIKU_LIST);
	printf("HAIKU_COUNT=%s;\n",HAIKU_COUNT);
	next;
}

$1 ~ /^Voter_Email/ {

	split($0, ADDR_ARRAY, "=");
	printf("VOTER_EMAIL=\"%s\";\n", ADDR_ARRAY[2]);
	next;
}

$1 ~ /^Voter_Name/ {

	split($0, NAME_ARRAY, "=");
	printf("VOTER_NAME=\"%s\";\n", NAME_ARRAY[2]);
	next;
}

END {
	printf("QUERY_ERROR=\"%s\";\n", ERROR_FLAG);
}'`

#
# Check the error flag.
#
if [ "${QUERY_ERROR}" = "TRUE" ];	then

	Error "Input Data Processing Failed";
fi

# calculate number of haiku over the max limit
eval "OVER_LIMIT=`expr ${HAIKU_COUNT} \> ${MAX_HAIKU}`";

# 
# Start error checking
#

#
# Check for no user or email
#
if [ "${VOTER_NAME}" = "nobody" ];	then

cat << EO_NO_NAME
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote Failed: No Name Given</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote Failed: No Name Given</H3>
<H4>WARNING!</H4>
<STRONG>
An error has occurred; you didn't give your name!<P>
(Required for the prize drawings ONLY; all votes are confidential.) <P>
Please resubmit your vote.  Sorry!
</STRONG>
<P>
<HR>

EO_NO_NAME

else

if [ "${VOTER_EMAIL}" = "nobody" ];	then

cat << EO_NO_EMAIL
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote Failed: No Email Address Given</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote Failed: No Email Address Given</H3>
<H4>WARNING!</H4>
<STRONG>
An error has occurred; you didn't give your Email address!<P>
(Required for the prize drawings ONLY; all votes are confidential.) <P>
Please resubmit your vote.  Sorry!
</STRONG>
<P>
<HR>

EO_NO_EMAIL

else

#
# Check for no haiku submitted at all
#
if [ ${HAIKU_COUNT} -eq 0 ];            then

cat << EO_NO_HAIKU
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote Failed: No Haiku Votes</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote Failed: No Haiku Votes</H3>
<H4>WARNING!</H4>
<STRONG>
An error has occurred; you didn't submit ANY haiku votes! <P>
Please resubmit your vote.  Sorry!
</STRONG>
<P>
<HR>

EO_NO_HAIKU

else

#
# Check for too many haiku submitted.
#
if [ ${OVER_LIMIT} -ne 0 ];		then

# more than ${MAX_HAIKU} haiku submitted

cat << EO_OVER_MAX_HAIKU
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote Failed: Too Many Haiku Votes</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote Failed: Too Many Haiku Votes</H3>
<H4>WARNING!</H4>
<STRONG>
An error has occurred; you can't vote for more than ${MAX_HAIKU} haiku! <P>
Please resubmit your vote.  Sorry!
</STRONG>
<P>
<HR>

EO_OVER_MAX_HAIKU

else

#
# Check that user hasn't already voted before (i.e. ballot-box stuffing)
#

grep -w "${VOTER_NAME}" ${BALLOT_BOX} > /dev/null;
NOTSEEN_THIS_NAME=${?};
grep -w "${VOTER_EMAIL}" ${BALLOT_BOX} > /dev/null;
NOTSEEN_THIS_EMAIL=${?};
eval "NAME_EMAIL_NEW=`expr ${NOTSEEN_THIS_NAME} + ${NOTSEEN_THIS_EMAIL}`"

if [ ${NAME_EMAIL_NEW} -eq 0 ]; then

cat << EO_BALLOT_STUFFING
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote Failed: You've Voted Before</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote Failed: You've Voted Before</H3>
<H4>WARNING!</H4>
<STRONG>
An error has occurred; you've ALREADY voted!  (Only one vote per customer.) <P>
Your vote has been rejected.  Sorry!
</STRONG>
<P>
<HR>

EO_BALLOT_STUFFING

else

#
# Vote OK: generate HTML output.
#
cat << EO_HTML
Content-type: text/html

<HTML>
<HEAD>
<TITLE>SPAM Haiku Vote</TITLE>
</HEAD>

<BODY>
<H3>SPAM Haiku Vote</H3>
Thank you, your vote has been accepted.
<P>
<HR>

EO_HTML

echo "Registering a vote for haiku number(s): 
<STRONG>${HAIKU}</STRONG><HR>";
echo "From: <STRONG>${VOTER_EMAIL} (${VOTER_NAME})</STRONG><HR>";

echo "${HAIKU}:${VOTER_NAME}:${VOTER_EMAIL}:${REM_HOST_ID}:${REM_ADDR_ID}:\
${REM_USER_ID}:${REM_IDENT}"			>> ${BALLOT_BOX};
if [ ${?} -ne 0 ];	then

	cat <<- EO_ERROR

	<P>
	<H4>WARNING!</H4>
	<STRONG>
	An error has occured while posting your vote. Please
	contact ${ERRORS_TO} and report this problem.
	</STRONG>
	<P>
	Your vote has probably
	<STRONG>
	not
	</STRONG>
	been included in the ballot-box. Sorry.
	<HR>
	EO_ERROR
fi

fi

fi

fi

fi

fi

#
# Write out footer section.
#
cat << EO_FOOTER

<EM>Processed: ${DATE}</EM><BR>
</BODY>
</HTML>

EO_FOOTER

exit 0;
