#ifndef __IMG_HEADER_H__
#define __IMG_HEADER_H__


#if __cplusplus
extern "C" {
#endif

#include <sap_ostypes.h>

#ifdef MAX_FW_SIZE
#define MAX_CODE_SIZE           MAX_FW_SIZE
#else
#define MAX_CODE_SIZE           0x1000000
#endif
#define DATA_BUFFER_SIZE        0x200

typedef struct __fwtype
{
    T_INT32 type;
    const T_CHAR* fwmethod;
} fwtype;


//cfho 2006-0922, don't change the numbers
#define BOOT_LOADER_TYPE      1
#define KERNEL_TYPE           2
#define KNLAPPS_TYPE          3
#define APPS_TYPE             4
#define APPS_LITTLE_TYPE      5
#define SOUNDS_TYPE           6
#define USER_CONFIG_TYPE      7
#define CONFIG_TYPE           8
#define FACTORY_TYPE          9
#define FACTORY_APP_DATA_TYPE 10
#define ODM_APP_TYPE          11
#define LANG_PACK_TYPE        12
#define CUST_LOGO_TYPE        13

enum VENDOR_ID_E
{
    GENETRIC=1
};

enum PRODUCT_ID_E
{
    VOIPGW = 1,
    VOOIPPROXY
};


/******************************
  Function declaration
 ******************************/

unsigned char *hHash_file(const char *filename, int noused);


#if __cplusplus
}
#endif


#endif

