/*****************************************************************************
;
;   (C) Unpublished Work of Senao Networks, Inc.  All Rights Reserved.
;
;       THIS WORK IS AN UNPUBLISHED WORK AND CONTAINS CONFIDENTIAL,
;       PROPRIETARY AND TRADESECRET INFORMATION OF SENAO INCORPORATED.
;       ACCESS TO THIS WORK IS RESTRICTED TO (I) SENAO EMPLOYEES WHO HAVE A
;       NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF THEIR ASSIGNMENTS
;       AND (II) ENTITIES OTHER THAN SENAO WHO HAVE ENTERED INTO APPROPRIATE
;       LICENSE AGREEMENTS.  NO PART OF THIS WORK MAY BE USED, PRACTICED,
;       PERFORMED, COPIED, DISTRIBUTED, REVISED, MODIFIED, TRANSLATED,
;       ABBRIDGED, CONDENSED, EXPANDED, COLLECTED, COMPILED, LINKED, RECAST,
;       TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN CONSENT OF SENAO.
;       ANY USE OR EXPLOITATION OF THIS WORK WITHOUT AUTHORIZATION COULD
;       SUBJECT THE PERPERTRATOR TO CRIMINAL AND CIVIL LIABILITY.
;
;------------------------------------------------------------------------------
;
;    Project : 
;    Creator : 
;    File    : md5sys.c
;    Abstract: generate MD5 and recovery file for firmware upgrade
;
;       Modification History:
;       By              Date     Ver.   Modification Description
;       --------------- -------- -----  --------------------------------------
;       cfho 2006-1002 This file calls the system comamnd "md5sum" to calcuate a md5sum value for a given file
;*****************************************************************************/

/*-------------------------------------------------------------------------*/
/*                        INCLUDE HEADER FILES                             */
/*-------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sap_ostypes.h>

/*-------------------------------------------------------------------------*/
/*                           DEFINITIONS                                   */
/*-------------------------------------------------------------------------*/

#define MD5RESULT_FILE "/tmp/md5sumresult"

#define HTOI(ch) ((tolower(ch)-'a'>=0)?(tolower(ch)-'a'+10):(tolower(ch)-'0'))

/*-------------------------------------------------------------------------*/
/*                           Parameter                                     */
/*-------------------------------------------------------------------------*/
static char gMd5sum[16];

/*****************************************************************
* NAME: usage
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
static T_BOOL hexStr2Struct(const T_CHAR *src, T_INT32 len, T_INT32 offset, T_CHAR *des )
{
	T_INT32 i;

    // protect
	if(src==0||des==0||len<=0||offset<0)
	{
		printf("Error: %s: offset %d len %d src 0x%x des 0x%x\n", __FUNCTION__,offset, len, (T_INT32)src, (T_INT32)des);
		return FALSE;
	}

	//printf("%s: src 0x%x len %d offset %d des 0x%x\n", __FUNCTION__, src, len, offset, des);

	for(i=0;i<(len-1-offset);i+=2)
	{
		//printf("[%c][%c] --> ",src[i+offset],src[i+offset+1]);
		des[(i+1)/2] = (HTOI(src[i+offset]))*16+(HTOI(src[i+offset+1]));
	   //printf("%d(%c)\t",des[(i/2)-1], (des[(i/2)-1]>32 && des[(i/2)-1] <126)?des[(i/2)-1]:' ');
	}

	return TRUE;
}
/*****************************************************************
* NAME: usage
* ---------------------------------------------------------------
* FUNCTION: This file calls the system comamnd "md5sum" to calcuate a md5sum value for a given file
* INPUT:    
* OUTPUT:   
* Author:   cfho 2006-1002
* Modify:   
****************************************************************/
unsigned char *hHash_file(const char *filename, int noused)
{
	FILE *fp;
	char buf[256];
	char md5sum[256];

    // protect
	if(!filename)
	{
		printf("Err: %s filename is NULL!\n", __FUNCTION__);
		return 0;
	}

	memset(gMd5sum, 0, sizeof(gMd5sum));

	sprintf(buf, "md5sum %s > %s ", filename, MD5RESULT_FILE );
	system(buf);

	fp = fopen(MD5RESULT_FILE, "r");

	if(fp == NULL)
	{
		printf("Err: %s File [%s] is NULL!\n", __FUNCTION__, MD5RESULT_FILE);
		return 0;
	}

	fscanf(fp, "%s %*s", md5sum);
	fclose(fp);

    // protect
	if(strlen(md5sum) != 32)
	{
		return 0;
	}

	printf("MD5 check OK!\n");
	hexStr2Struct(md5sum, 32, 0, gMd5sum);

#if 0 // For debug
	for(i=0;i<16;i++)
	{
		printf("%x ", gMd5sum[i]&0xff);
	}
#endif

	return (unsigned char *)&(gMd5sum[0]);
}






