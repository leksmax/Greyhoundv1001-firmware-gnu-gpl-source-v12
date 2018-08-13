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
;
;*****************************************************************************/

#include <sap_ostypes.h>
/* Reference to sysHardwareIDInfo.h */
#define VENDOR_ID   0x0101
#define PRODUCT_ID  0x006D
/*****************************************************/
/*****************************************************/ 

#define CODE_TYPE   2
#define MAGIC_KEY   0x12345678
#define VERSION     "123"
#define HW_VERSION  1
#define SW_VERSION  1
#define MAX_LENGTH  0x600000 
#define MAX_DATA_LEN 128

typedef struct __IMAGE_HEADER
{   
    T_UINT32   start          __ATTRIBUTE_PACKED__;
    T_UINT32   vendor_id      __ATTRIBUTE_PACKED__;
    T_UINT32   product_id     __ATTRIBUTE_PACKED__;
    T_CHAR     version[16]    __ATTRIBUTE_PACKED__;  
    T_UINT32   type           __ATTRIBUTE_PACKED__;
    T_UINT32   comp_file_len  __ATTRIBUTE_PACKED__;
    T_UINT32   comp_file_sum  __ATTRIBUTE_PACKED__;
    T_CHAR     md5[16]        __ATTRIBUTE_PACKED__;
    T_CHAR     pad[32]        __ATTRIBUTE_PACKED__;
    T_UINT32   header_sum     __ATTRIBUTE_PACKED__;
    T_UINT32   magic_key      __ATTRIBUTE_PACKED__;
} __S_ATTRIBUTE_PACKED__ imageHeader_t;
